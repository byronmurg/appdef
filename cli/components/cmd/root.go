/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package cmd

import (
	"fmt"
	. "appdef/tool/components/config"
	"github.com/spf13/cobra"
	"os"
)

var rootCmd = &cobra.Command{
	Use:   "appdef-tool",
	Short: "A cli for interacting with appdef",
	Long:  "A cli for interacting with appdef", //@TODO More info
}

/*
 * This is the root config
 * defined here and consumed
 * by individual handlers.
 */
var config = &Config{
	SpecPath:  "appdef.yaml",
	WriteDir:  "/tmp/",
	LocalPort: 8080,

	TemplateVars: map[string]string{},
}

func init() {
	rootCmd.PersistentFlags().StringVarP(&config.SpecPath, "spec-path", "f", "appdef.yaml", "Location of the appdef")
	rootCmd.PersistentFlags().IntVarP(&config.LocalPort, "local-port", "p", 8080, "Local port to listen on.")
	rootCmd.PersistentFlags().StringArrayVarP(&config.Expose, "local-expose", "l", []string{}, "Local port to substitute for an app (e.g. ui:3000)")
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
