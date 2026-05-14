package main

import (
	"os"
	"strconv"

	"github.com/go-git/go-git/v6"
	"github.com/go-git/go-git/v6/plumbing"
	"wieman.cloud/tofudeployer/tofu"
)

func main() {

	dryRunStr := os.Getenv("DRY_RUN")
	dryRun := true

	if dryRunStr != "" {
		parsed, err := strconv.ParseBool(dryRunStr)
		if err == nil {
			dryRun = parsed
		}
	}

	repo := os.Getenv("REPOSITORY_URL")
	if repo == "" {
		panic("ERROR: repository url is required")
	}

	branch := os.Getenv("REPOSITORY_BRANCH")
	if branch == "" {
		panic("ERROR: repository branch is required")
	}

	path := os.Getenv("TOFU_PATH")
	if path == "" {
		panic("ERROR: tofu path is required")
	}

	cloneTarget := "output"

	// stage files
	_, err := git.PlainClone(cloneTarget, &git.CloneOptions{
		URL:           repo,
		ReferenceName: plumbing.NewBranchReferenceName(branch),
		Depth:         1,
		SingleBranch:  true,
	})

	if err != nil {
		panic(err)
	}

	err = os.Chdir(cloneTarget + "/" + path)

	if err != nil {
		panic(err)
	}

	// tofu init
	_, err = tofu.Init()

	if err != nil {
		panic(err)
	}

	// tofu plan -> exit on fail or dry run
	_, err = tofu.Plan()

	if err != nil {
		panic(err)
	}

	if dryRun {
		return
	}

	// tofu apply
	_, err = tofu.Apply()

	if err != nil {
		panic(err)
	}
}
