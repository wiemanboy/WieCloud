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
)

var runnerName = "wiecloud-runner"
var runnerLabel = "wieman.cloud/forgejo-runner"

func Create(amount int, secret string, namespace string, client *kubernetes.Clientset) error {
	runnerCount, _ := count(namespace, client)
	log.Println("Counted", runnerCount, "runners")

	if runnerCount < amount {
		createJob(secret, namespace, client)
		Create(amount, secret, namespace, client)
	}

	log.Println("All runners created")
	return nil
}

func count(namespace string, client *kubernetes.Clientset) (int, error) {
	log.Println("Counting runners")
	pods, err := client.CoreV1().Pods(namespace).List(context.Background(), metav1.ListOptions{LabelSelector: runnerLabel})
	jobs, err := client.BatchV1().Jobs(namespace).List(context.Background(), metav1.ListOptions{LabelSelector: runnerLabel})

	if err != nil {
		log.Println("Failed to list jobs")
		return 0, err
	}

	return pods.Size() + jobs.Size(), nil
}

func createJob(secret string, namespace string, client *kubernetes.Clientset) {
	log.Println("Creating job")

	job := &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			GenerateName: "register-runner",
			Namespace:    namespace,
			Labels:       map[string]string{"wieman.cloud/forgejo-runner": ""},
		},
		Spec: batchv1.JobSpec{
			BackoffLimit: ptr.To(int32(0)),
			Template: v1.PodTemplateSpec{
				Spec: v1.PodSpec{
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
					InitContainers: []v1.Container{{
						Name:  "register",
						Image: "forgejo-image",
						Env: []v1.EnvVar{{
							Name:  "GITEA_WORK_DIR",
							Value: "/data",
						}},
						Command: []string{
							"/bin/sh",
							"-ec",
							fmt.Sprintf(`
              forgejo forgejo-cli actions register \
                --name "%s"\
                --secret "%s" \
								--ephemeral \
                > /shared/uuid 2>&1
							`, runnerName, secret),
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
						Image: "kubectl-image",
						Command: []string{
							"/bin/sh",
							"-ec",
						},
						VolumeMounts: []v1.VolumeMount{{
							Name:      "shared-data",
							MountPath: "/shared",
						}}},
					},
				},
			},
		},
	}
	client.BatchV1().Jobs(namespace).Create(context.Background(), job, metav1.CreateOptions{})
}
