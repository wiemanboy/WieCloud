package k8s

import (
	"fmt"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/utils/ptr"
)

type DeploymentBuilder interface {
	Build() *appsv1.Deployment
}

type RunnerDeploymentBuilder struct {
	instance       string
	label          string
	namespace      string
	runnerName     string
	runnerImage    string
	dindImage      string
	configChecksum string
}

func (rdb *RunnerDeploymentBuilder) Build() *appsv1.Deployment {
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
					TopologySpreadConstraints: []corev1.TopologySpreadConstraint{
						{
							MaxSkew:           1,
							TopologyKey:       "topology.kubernetes.io/zone",
							WhenUnsatisfiable: corev1.ScheduleAnyway,
							LabelSelector:     &metav1.LabelSelector{MatchLabels: map[string]string{"app": runner.Name}},
						},
						{
							MaxSkew:           1,
							TopologyKey:       "kubernetes.io/hostname",
							WhenUnsatisfiable: corev1.ScheduleAnyway,
							LabelSelector:     &metav1.LabelSelector{MatchLabels: map[string]string{"app": runner.Name}},
						},
					},
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

func (rdb *RunnerDeploymentBuilder) SetInstance(instance string) *RunnerDeploymentBuilder {
	rdb.instance = instance
	return rdb
}

func (rdb *RunnerDeploymentBuilder) SetNamespace(namespace string) *RunnerDeploymentBuilder {
	rdb.namespace = namespace
	return rdb
}

// set label
func (rdb *RunnerDeploymentBuilder) SetLabel(label string) *RunnerDeploymentBuilder {
	rdb.label = label
	return rdb
}

func (rdb *RunnerDeploymentBuilder) SetRunnerName(name string) *RunnerDeploymentBuilder {
	rdb.runnerName = name
	return rdb
}

func (rdb *RunnerDeploymentBuilder) SetRunnerImage(image string) *RunnerDeploymentBuilder {
	rdb.runnerImage = image
	return rdb
}

func (rdb *RunnerDeploymentBuilder) SetDindImage(image string) *RunnerDeploymentBuilder {
	rdb.dindImage = image
	return rdb
}

func (rdb *RunnerDeploymentBuilder) SetConfigChecksum(checksum string) *RunnerDeploymentBuilder {
	rdb.configChecksum = checksum
	return rdb
}
