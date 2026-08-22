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
	"wieman.cloud/forgejorunnercontroller/runner/secret"
)

type Register struct {
	Namespace    string
	ForgejoImage string
	KubectlImage string
}

type Runner struct {
	Name      string
	Instance  string
	Label     string
	Namespace string
	Image     string
	DindImage string
}

func Create(amount int, secretName string, register Register, runner Runner, client *kubernetes.Clientset) error {
	runnerCount, _ := count(register.Namespace, runner.Label, client)
	log.Println("Counted", runnerCount, "runners")

	if runnerCount < amount {
		secretRefs, _ := secret.Create(
			secret.Secret{
				Name:              secretName,
				Label:             runner.Label,
				RegisterNamespace: register.Namespace,
				RunnerNamespace:   runner.Namespace,
			},
			client,
		)
		createJob(secretRefs, register, runner, client)
		Create(amount, secretName, register, runner, client)
	}

	log.Println("All runners created")
	return nil
}

func count(namespace string, label string, client *kubernetes.Clientset) (int, error) {
	log.Println("Counting runners with label " + label + " in namespace " + namespace)

	pods, err := client.CoreV1().Pods(namespace).List(context.Background(), metav1.ListOptions{LabelSelector: label})
	jobs, err := client.BatchV1().Jobs(namespace).List(context.Background(), metav1.ListOptions{LabelSelector: label})

	if err != nil {
		log.Println("Failed to list runners")
		log.Println(err)
		return 0, err
	}

	return len(pods.Items) + len(jobs.Items), nil
}

func createJob(secretRefs secret.SecretsRefs, register Register, runner Runner, client *kubernetes.Clientset) {
	log.Println("Creating job")

	runnerPod := pod(secretRefs, runner)

	podBytes, _ := yaml.Marshal(runnerPod)
	podYaml := string(podBytes)

	_, err := client.BatchV1().Jobs(register.Namespace).Create(
		context.Background(),
		job(
			secretRefs,
			register,
			runner,
			podYaml,
		),
		metav1.CreateOptions{})

	if err != nil {
		log.Println("Error creating job")
		log.Println(err)
	}
}

func job(secretRefs secret.SecretsRefs, register Register, runner Runner, podYaml string) *batchv1.Job {
	registerCmd := fmt.Sprintf(`
forgejo forgejo-cli actions register \
  --name "%s" \
  --secret "${SECRET}" \
  > /shared/uuid 2>&1
`, runner.Name)

	createRunnerCmd := fmt.Sprintf(`
UUID=$(cat /shared/uuid)
NAME=%s-${UUID}

echo "Creating ${NAME}"
kubectl create -f - <<EOF
%s
EOF
`, runner.Name, podYaml)

	return &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			GenerateName: "register-runner-",
			Namespace:    register.Namespace,
			Labels:       map[string]string{runner.Label: ""},
			Annotations:  map[string]string{"argocd.argoproj.io/tracking-id": "forgejo:apps/Deployment:forgejo/forgejo-runner-controller"},
			OwnerReferences: []metav1.OwnerReference{{
				Name:               secretRefs.RegisterSecret.Name,
				UID:                secretRefs.RegisterSecret.UID,
				Controller:         ptr.To(true),
				BlockOwnerDeletion: ptr.To(true),
			}},
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
						Image: register.ForgejoImage,
						Env: []corev1.EnvVar{
							{
								Name:  "GITEA_WORK_DIR",
								Value: "/data",
							},
							{
								Name: "SECRET",
								ValueFrom: &corev1.EnvVarSource{
									SecretKeyRef: &corev1.SecretKeySelector{
										LocalObjectReference: corev1.LocalObjectReference{Name: secretRefs.RegisterSecret.Name},
										Key:                  "secret",
									},
								},
							},
						},
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
						Image: register.KubectlImage,
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

func pod(secretRefs secret.SecretsRefs, runner Runner) *corev1.Pod {
	// Below command needs to be bash escaped
	runnerCmd := fmt.Sprintf(`
cp /tmp/runner/config.yaml /etc/runner/config.yaml

awk -v name="%s" -v url="%s" -v uuid="\${RUNNER_UUID}" -v token="\${RUNNER_SECRET}" '
/^  connections:/ && !done {
  print \$0
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

cat /etc/runner/config.yaml

while ! nc -z 127.0.0.1 2375 </dev/null; do
  echo 'waiting for docker daemon...'
  sleep 5
done

/bin/forgejo-runner --config /etc/runner/config.yaml daemon
`, runner.Name, runner.Instance)

	return &corev1.Pod{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "v1",
			Kind:       "Pod",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:        "${NAME}",
			Namespace:   runner.Namespace,
			Labels:      map[string]string{runner.Label: ""},
			Annotations: map[string]string{"argocd.argoproj.io/tracking-id": "forgejo:apps/Deployment:forgejo/forgejo-runner-controller"},
			OwnerReferences: []metav1.OwnerReference{{
				Name:               secretRefs.RunnerSecret.Name,
				UID:                secretRefs.RunnerSecret.UID,
				Controller:         ptr.To(true),
				BlockOwnerDeletion: ptr.To(true),
			}},
		},
		Spec: corev1.PodSpec{
			InitContainers: []corev1.Container{{
				Name:          "dind",
				Image:         runner.DindImage,
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
				Image: runner.Image,
				Env: []corev1.EnvVar{
					{
						Name: "RUNNER_SECRET",
						ValueFrom: &corev1.EnvVarSource{
							SecretKeyRef: &corev1.SecretKeySelector{
								LocalObjectReference: corev1.LocalObjectReference{Name: secretRefs.RunnerSecret.Name},
								Key:                  "secret",
							},
						},
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
