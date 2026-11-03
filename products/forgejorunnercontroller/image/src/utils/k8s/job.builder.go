package k8s

import "k8s.io/client-go/kubernetes"

type JobBuilder interface {
	Build()
}

type RunnerJobBuilder struct {
}

func NewRunnerJobBuilder(k8s *kubernetes.Clientset) *RunnerJobBuilder {
	return &RunnerJobBuilder{}
}

func (rjb *RunnerJobBuilder) Build() {}
