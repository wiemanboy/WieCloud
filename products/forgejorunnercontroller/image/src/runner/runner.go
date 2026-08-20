package runner

import (
	"context"
	"fmt"
	"log"

	batchv1 "k8s.io/api/batch/v1"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/utils/ptr"
	"sigs.k8s.io/yaml"
)

var runnerName = "wiecloud-runner"
var runnerLabel = "wieman.cloud/forgejo-runner"

func Create(amount int, secret string, forgejoNamespace string, runnerNamespace string, forgejoImage string, runnerImage string, dindImage string, kubectlImage string, client *kubernetes.Clientset) error {
	runnerCount, _ := count(forgejoNamespace, client)
	log.Println("Counted", runnerCount, "runners")

	if runnerCount < amount {
		createJob(secret, forgejoNamespace, runnerNamespace, forgejoImage, runnerImage, dindImage, kubectlImage, client)
		Create(amount, secret, forgejoNamespace, runnerNamespace, forgejoImage, runnerImage, dindImage, kubectlImage, client)
	}

	log.Println("All runners created")
	return nil
}

func count(forgejoNamespace string, client *kubernetes.Clientset) (int, error) {
	log.Println("Counting runners")

	pods, err := client.CoreV1().Pods(forgejoNamespace).List(context.Background(), metav1.ListOptions{LabelSelector: runnerLabel})
	jobs, err := client.BatchV1().Jobs(forgejoNamespace).List(context.Background(), metav1.ListOptions{LabelSelector: runnerLabel})

	if err != nil {
		log.Println("Failed to list jobs")
		log.Println(err)
		return 0, err
	}

	return len(pods.Items) + len(jobs.Items), nil
}

func createJob(secret string, forgejoNamespace string, runnerNamespace string, forgejoImage string, runnerImage string, dindImage string, kubectlImage string, client *kubernetes.Clientset) {
	log.Println("Creating job")

	runnerPod := pod(secret, "forgejo.wieman.cloud", forgejoNamespace, forgejoImage, dindImage)

	podBytes, _ := yaml.Marshal(runnerPod)
	podYaml := string(podBytes)

	_, err := client.BatchV1().Jobs(forgejoNamespace).Create(
		context.Background(),
		job(
			secret,
			forgejoNamespace,
			forgejoImage,
			kubectlImage,
			podYaml,
		),
		metav1.CreateOptions{})

	if err != nil {
		log.Println("Error creating job")
		log.Println(err)
	}
}

func job(secret string, forgejoNamespace string, forgejoImage string, kubectlImage string, podYaml string) *batchv1.Job {
	registerCmd := fmt.Sprintf(`
forgejo forgejo-cli actions register \
  --name "%s" \
  --secret "%s" \
  --ephemeral
`, runnerName, secret)
	//   > /shared/uuid

	createRunnerCmd := fmt.Sprintf(`
UUID=$(cat /shared/uuid)
NAME=%s-${UUID}

kubectl apply -f - <<EOF
%s
EOF
`, runnerName, podYaml)

	return &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			GenerateName: "register-runner-",
			Namespace:    forgejoNamespace,
			Labels:       map[string]string{runnerLabel: ""},
		},
		Spec: batchv1.JobSpec{
			BackoffLimit: ptr.To(int32(0)),
			Template: v1.PodTemplateSpec{
				Spec: v1.PodSpec{
					RestartPolicy:      v1.RestartPolicyNever,
					ServiceAccountName: "forgejo-runner-registration",
					SecurityContext: &v1.PodSecurityContext{
						RunAsUser:  ptr.To(int64(1000)),
						RunAsGroup: ptr.To(int64(1000)),
						FSGroup:    ptr.To(int64(1000)),
					},
					InitContainers: []v1.Container{{
						Name:  "register",
						Image: forgejoImage,
						Env: []v1.EnvVar{{
							Name:  "GITEA_WORK_DIR",
							Value: "/data",
						}},
						Command: []string{
							"/bin/sh",
							"-ec",
							registerCmd,
						}, VolumeMounts: []v1.VolumeMount{
							{
								Name:      "shared-data",
								MountPath: "/shared",
							},
							{
								Name:      "forgejo-data",
								MountPath: "/data",
							},
						},
					}},
					Containers: []v1.Container{{
						Name:  "create-runner",
						Image: kubectlImage,
						Command: []string{
							"/bin/sh",
							"-ec",
							createRunnerCmd,
						},
						VolumeMounts: []v1.VolumeMount{{
							Name:      "shared-data",
							MountPath: "/shared",
						}}},
					},
					Volumes: []v1.Volume{
						{
							Name:         "shared-data",
							VolumeSource: v1.VolumeSource{EmptyDir: &v1.EmptyDirVolumeSource{}},
						},
						{
							Name:         "forgejo-data",
							VolumeSource: v1.VolumeSource{PersistentVolumeClaim: &v1.PersistentVolumeClaimVolumeSource{ClaimName: "gitea-shared-storage"}},
						},
					},
				},
			},
		},
	}
}

func pod(secret string, forgejoInstance string, namespace string, forgejoImage string, dindImage string) *v1.Pod {
	runnerCmd := `
cp /tmp/runner/config.yaml /etc/runner/config.yaml

awk -v name="%s" -v url="%s" -v uuid="$RUNNER_UUID" -v token="$RUNNER_SECRET" '
/^  connections:/ && !done {
	print $0
	print "    " name ":"
	print "      url: " url
	print "      uuid: " uuid
	print "      token: " token
	done=1
	next
}
done && /^  [^ ]/ {
	done=0
}
done {
	next
}
1' /etc/runner/config.yaml > /etc/runner/config.yaml.tmp && mv /etc/runner/config.yaml.tmp /etc/runner/config.yaml

/bin/forgejo-runner --config /etc/runner/config.yaml daemon
`

	return &v1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "${NAME}",
			Namespace: namespace,
			Labels:    map[string]string{runnerLabel: ""},
		},
		Spec: v1.PodSpec{
			InitContainers: []v1.Container{{
				Name:  "dind",
				Image: dindImage,
				Command: []string{
					"dockerd",
					"-H",
					"tcp://0.0.0.0:2375",
					"--tls=false",
				},
				SecurityContext: &v1.SecurityContext{
					Privileged: ptr.To(true),
				},
			}},

			Containers: []v1.Container{{
				Name:  "forgejo-runner",
				Image: forgejoImage,
				Env: []v1.EnvVar{
					{
						Name:  "RUNNER_SECRET",
						Value: secret,
					},
					{
						Name:  "RUNNER_UUID",
						Value: "${UUID}",
					},
				},
				Command: []string{
					"sh",
					"-c",
					runnerCmd,
				},
				SecurityContext: &v1.SecurityContext{
					Privileged: ptr.To(true),
				},
				VolumeMounts: []v1.VolumeMount{
					{
						Name:      "runner",
						MountPath: "/etc/runner",
					},
					{
						Name:      "runner-data",
						MountPath: "/data",
					},
					{
						Name:      "runner-config",
						MountPath: "/tmp/runner",
					},
				},
			}},

			Volumes: []v1.Volume{
				{
					Name:         "runner",
					VolumeSource: v1.VolumeSource{EmptyDir: &v1.EmptyDirVolumeSource{}},
				},
				{
					Name:         "runner-data",
					VolumeSource: v1.VolumeSource{EmptyDir: &v1.EmptyDirVolumeSource{}},
				},
				{
					Name: "runner-config",
					VolumeSource: v1.VolumeSource{
						ConfigMap: &v1.ConfigMapVolumeSource{
							LocalObjectReference: v1.LocalObjectReference{
								Name: "forgejo-runner-config",
							},
						},
					},
				},
			},
		},
	}
}
