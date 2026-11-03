package k8s

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type SecretBuilder interface {
	Build()
}

type RunnerSecretBuilder struct {
	name      string
	postfix   string
	namespace string
	label     string
	value     string
}

func NewRunnerSecretBuilder() *RunnerSecretBuilder {
	return &RunnerSecretBuilder{}
}

func (rsb *RunnerSecretBuilder) Build() *corev1.Secret {
	return &corev1.Secret{
		Type: corev1.SecretTypeOpaque,
		ObjectMeta: metav1.ObjectMeta{
			Name:        rsb.name + "-" + rsb.postfix,
			Namespace:   rsb.namespace,
			Labels:      map[string]string{rsb.label: ""},
			Annotations: map[string]string{"argocd.argoproj.io/tracking-id": "forgejo:apps/Secret:forgejo/forgejo-runner"},
		},
		StringData: map[string]string{
			"secret": rsb.value,
		},
	}

}

func (rsb *RunnerSecretBuilder) SetName(name string) *RunnerSecretBuilder {
	rsb.name = name
	return rsb
}

func (rsb *RunnerSecretBuilder) SetPostfix(postfix string) *RunnerSecretBuilder {
	rsb.postfix = postfix
	return rsb
}

func (rsb *RunnerSecretBuilder) SetNamespace(namespace string) *RunnerSecretBuilder {
	rsb.namespace = namespace
	return rsb
}

func (rsb *RunnerSecretBuilder) SetLabel(label string) *RunnerSecretBuilder {
	rsb.label = label
	return rsb
}

func (rsb *RunnerSecretBuilder) SetValue(value string) *RunnerSecretBuilder {
	rsb.value = value
	return rsb
}
