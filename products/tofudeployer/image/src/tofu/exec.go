package tofu

import (
	"fmt"
	"os/exec"
)

func Init() ([]byte, error) {
	printHeader("Init")
	return run("tofu", "init")
}

func Plan() ([]byte, error) {
	printHeader("Plan")
	return run("tofu", "plan")
}

func Apply() ([]byte, error) {
	printHeader("Apply")
	return run("tofu", "apply", "-y")
}

func printHeader(header string) {
	fmt.Printf("\x1b[34m%s\x1b[0m\n", header)
	fmt.Printf("\x1b[34m%s\x1b[0m\n", "────────────────────────────────────────────────────────────────────────────")
}

func run(command string, args ...string) ([]byte, error) {
	cmd := exec.Command(command, args...)
	output, err := cmd.Output()
	fmt.Println(string(output))
	return output, err
}
