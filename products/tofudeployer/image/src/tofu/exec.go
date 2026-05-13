package tofu

import (
	"fmt"
	"os/exec"
)

func Init() {
	fmt.Println("init")
	// run("tofu", "init")
}

func Plan() {
	fmt.Println("plan")
	// run("tofu", "plan")
}

func Apply() {
	fmt.Println("apply")
	// run("tofu", "apply")
}

func run(command string, args ...string) {
	cmd := exec.Command(command, args...)
	output, err := cmd.Output()
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	fmt.Println(string(output))
}
