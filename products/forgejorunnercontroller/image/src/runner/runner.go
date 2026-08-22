package runner

import (
	"context"
	"fmt"
	"log"

	appsv1 "k8s.io/api/apps/v1"
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
	Name           string
	Instance       string
	Label          string
	Namespace      string
	Image          string
	DindImage      string
	ConfigChecksum string
}

func Create(amount int, secretName string, register Register, runner Runner, client *kubernetes.Clientset) error {
	runnerCount, _ := secret.Count(runner.Namespace, runner.Label, client)
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

func UpdateChecksums(runner Runner, client *kubernetes.Clientset) error {
	deployments, err := client.AppsV1().Deployments(runner.Namespace).List(context.Background(), metav1.ListOptions{LabelSelector: runner.Label})

	if err != nil {
		log.Println("Failed to list deployments")
		log.Println(err)
		return err
	}

	for _, deployment := range deployments.Items {
		deployment.Spec.Template.Annotations["wieman.cloud/runner-config-checksum"] = runner.ConfigChecksum
		_, err := client.AppsV1().Deployments(runner.Namespace).Update(context.Background(), &deployment, metav1.UpdateOptions{})

		if err != nil {
			log.Println("Failed to update deployment")
			log.Println(err)
			return err
		}
	}

	return nil
}

func createJob(secretRefs secret.SecretsRefs, register Register, runner Runner, client *kubernetes.Clientset) {
	log.Println("Creating job")

	runnerDeployment := deployment(secretRefs, runner)

	deploymentBytes, _ := yaml.Marshal(runnerDeployment)
	deploymentYaml := string(deploymentBytes)

	_, err := client.BatchV1().Jobs(register.Namespace).Create(
		context.Background(),
		job(
			secretRefs,
			register,
			runner,
			deploymentYaml,
		),
		metav1.CreateOptions{})

	if err != nil {
		log.Println("Error creating job")
		log.Println(err)
	}
}

func job(secretRefs secret.SecretsRefs, register Register, runner Runner, deploymentYaml string) *batchv1.Job {
	registerCmd := fmt.Sprintf(`
NAME=%s

echo "Registering ${NAME}"

forgejo forgejo-cli actions register \
  --name "${NAME}" \
  --secret "${SECRET}" \
  > /shared/uuid 2>&1

UUID=$(cat /shared/uuid)

echo "Successfully registered ${NAME} with uuid ${UUID}"
`, runner.Name)

	createRunnerCmd := fmt.Sprintf(`
UUID=$(cat /shared/uuid)
NAME=%s-${UUID}

echo "Creating ${NAME}"
kubectl create --validate=false -f - <<EOF
%s
EOF

kubectl delete secret %s -n %s
`, runner.Name, deploymentYaml, secretRefs.RegisterSecret.Name, secretRefs.RegisterSecret.Namespace)

	return &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			GenerateName: "register-runner-",
			Namespace:    register.Namespace,
			Labels:       map[string]string{runner.Label: ""},
			OwnerReferences: []metav1.OwnerReference{{
				Name:               secretRefs.RegisterSecret.Name,
				UID:                secretRefs.RegisterSecret.UID,
				Controller:         ptr.To(true),
				BlockOwnerDeletion: ptr.To(true),
				APIVersion:         secretRefs.RegisterSecret.ApiVersion,
				Kind:               secretRefs.RegisterSecret.Kind,
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

func deployment(secretRefs secret.SecretsRefs, runner Runner) *appsv1.Deployment {
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

	return &appsv1.Deployment{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "apps/v1",
			Kind:       "Deployment",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      "${NAME}",
			Namespace: runner.Namespace,
			Labels: map[string]string{
				runner.Label: "",
				"app":        runner.Name,
			},
			OwnerReferences: []metav1.OwnerReference{{
				Name:               secretRefs.RunnerSecret.Name,
				UID:                secretRefs.RunnerSecret.UID,
				Controller:         ptr.To(true),
				BlockOwnerDeletion: ptr.To(true),
				APIVersion:         secretRefs.RunnerSecret.ApiVersion,
				Kind:               secretRefs.RunnerSecret.Kind,
			}},
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: ptr.To(int32(1)),
			Selector: &metav1.LabelSelector{
				MatchLabels: map[string]string{
					"app": runner.Name,
				},
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{
						runner.Label: "",
						"app":        runner.Name,
					},
					Annotations: map[string]string{
						"wieman.cloud/runner-config-checksum": runner.ConfigChecksum,
					},
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
			},
		},
	}
}
