package tofu

import (
	"fmt"
	"os/exec"
)

func Init() ([]byte, error) {
	fmt.Println("init")
	return run("tofu", "init")
}

func Plan() ([]byte, error) {
	fmt.Println("plan")
	return run("tofu", "plan")
}

func Apply() ([]byte, error) {
	fmt.Println("apply")
	return run("tofu", "apply")
}

func run(command string, args ...string) ([]byte, error) {
	cmd := exec.Command(command, args...)
	return cmd.Output()
}
