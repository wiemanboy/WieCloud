package runner

import (
	"context"
	"fmt"
	"log"

	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
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

	runnerPod := pod(secret, "forgejo.wieman.cloud", runnerNamespace, runnerImage, dindImage)

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
  > /shared/uuid 2>&1
`, runnerName, secret)

	createRunnerCmd := fmt.Sprintf(`
UUID=$(cat /shared/uuid)
NAME=%s-${UUID}

echo "Creating ${NAME}"
kubectl create -f - <<EOF
%s
EOF
`, runnerName, podYaml)

	return &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			GenerateName: "register-runner-",
			Namespace:    forgejoNamespace,
			Labels:       map[string]string{runnerLabel: ""},
			Annotations:  map[string]string{"argocd.argoproj.io/tracking-id": "forgejo:apps/Deployment:forgejo/forgejo-runner-controller"},
		},
		Spec: batchv1.JobSpec{
			BackoffLimit: ptr.To(int32(0)),
			Template: corev1.PodTemplateSpec{
				Spec: corev1.PodSpec{
					RestartPolicy:      corev1.RestartPolicyNever,
					ServiceAccountName: "create-runner",
					SecurityContext: &corev1.PodSecurityContext{
						RunAsUser:  ptr.To(int64(1000)),
						RunAsGroup: ptr.To(int64(1000)),
						FSGroup:    ptr.To(int64(1000)),
					},
					InitContainers: []corev1.Container{{
						Name:  "register",
						Image: forgejoImage,
						Env: []corev1.EnvVar{{
							Name:  "GITEA_WORK_DIR",
							Value: "/data",
						}},
						Command: []string{
							"/bin/sh",
							"-ec",
							registerCmd,
						}, VolumeMounts: []corev1.VolumeMount{
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
					Containers: []corev1.Container{{
						Name:  "create-runner",
						Image: kubectlImage,
						Command: []string{
							"/bin/sh",
							"-ec",
							createRunnerCmd,
						},
						VolumeMounts: []corev1.VolumeMount{{
							Name:      "shared-data",
							MountPath: "/shared",
						}}},
					},
					Volumes: []corev1.Volume{
						{
							Name:         "shared-data",
							VolumeSource: corev1.VolumeSource{EmptyDir: &corev1.EmptyDirVolumeSource{}},
						},
						{
							Name:         "forgejo-data",
							VolumeSource: corev1.VolumeSource{PersistentVolumeClaim: &corev1.PersistentVolumeClaimVolumeSource{ClaimName: "gitea-shared-storage"}},
						},
					},
				},
			},
		},
	}
}

func pod(secret string, forgejoInstance string, namespace string, runnerImage string, dindImage string) *corev1.Pod {
	runnerCmd := fmt.Sprintf(`
cp /tmp/runner/config.yaml /etc/runner/config.yaml

awk -v name="%s" -v url="%s" -v uuid="\${RUNNER_UUID}" -v token="\${RUNNER_SECRET}" '
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

while ! nc -z 127.0.0.1 2375 </dev/null; do
  echo 'waiting for docker daemon...'
  sleep 5
done

/bin/forgejo-runner --config /etc/runner/config.yaml daemon
`, "wiecloud-runner", "forgejo.wieman.cloud")

	return &corev1.Pod{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "v1",
			Kind:       "Pod",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:        "${NAME}",
			Namespace:   namespace,
			Labels:      map[string]string{runnerLabel: ""},
			Annotations: map[string]string{"argocd.argoproj.io/tracking-id": "forgejo:apps/Deployment:forgejo/forgejo-runner-controller"},
		},
		Spec: corev1.PodSpec{
			InitContainers: []corev1.Container{{
				Name:          "dind",
				Image:         dindImage,
				RestartPolicy: ptr.To(corev1.ContainerRestartPolicyAlways),
				Command: []string{
					"dockerd",
					"-H",
					"tcp://0.0.0.0:2375",
					"--tls=false",
				},
				SecurityContext: &corev1.SecurityContext{
					Privileged: ptr.To(true),
				},
			}},

			Containers: []corev1.Container{{
				Name:  "forgejo-runner",
				Image: runnerImage,
				Env: []corev1.EnvVar{
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
				SecurityContext: &corev1.SecurityContext{
					Privileged: ptr.To(true),
				},
				VolumeMounts: []corev1.VolumeMount{
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

			Volumes: []corev1.Volume{
				{
					Name:         "runner",
					VolumeSource: corev1.VolumeSource{EmptyDir: &corev1.EmptyDirVolumeSource{}},
				},
				{
					Name:         "runner-data",
					VolumeSource: corev1.VolumeSource{EmptyDir: &corev1.EmptyDirVolumeSource{}},
				},
				{
					Name: "runner-config",
					VolumeSource: corev1.VolumeSource{
						ConfigMap: &corev1.ConfigMapVolumeSource{
							LocalObjectReference: corev1.LocalObjectReference{
								Name: "forgejo-runner-config",
							},
						},
					},
				},
			},
		},
	}
}
