package k8s

import appsv1 "k8s.io/api/apps/v1"

type DeploymentBuilder interface {
	Build() *appsv1.Deployment
}

type RunnerDeploymentBuilder struct {
	name           string
	instance       string
	label          string
	namespace      string
	image          string
	dindImage      string
	configChecksum string
}

func (rdb *RunnerDeploymentBuilder) Build() *appsv1.Deployment {
	return &appsv1.Deployment{}
}
