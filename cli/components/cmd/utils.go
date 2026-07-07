package cmd

import (
	"fmt"
	"os"
)

func Die(v ...any) {
	fmt.Fprintln(os.Stderr, v...)
	os.Exit(1)
}
