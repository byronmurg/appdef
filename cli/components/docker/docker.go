/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package docker

import (
	"os"
	"os/exec"
	"os/signal"
	"syscall"
)

func createCommand(cmd string, args... string) *exec.Cmd {
	command := exec.Command(cmd, args...)

	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	command.Stdin = os.Stdin

	return command

}

func runForClient(cmd string, args... string) error {
	command := createCommand(cmd, args...)
	return command.Run()
}

func runForClientSafe(cmd string, args... string) error {
	command := createCommand(cmd, args...)
	command.Run()
	return nil
}

func Build(composePath string) error {
	return runForClient("docker-compose", "-f", composePath, "build", "--no-cache")
}

func Up(composePath string) error {
	// We ignore the signal as it is handled by docker-compose
	signal.Ignore(syscall.SIGINT)
	return runForClientSafe("docker-compose", "-f", composePath, "up", "--build")
}

func BuildImage(image string, build string) error {
	return runForClient("docker", "build", "-t", image, build)
}

func PushImage(image string) error {
	return runForClient("docker", "push", image)
}
