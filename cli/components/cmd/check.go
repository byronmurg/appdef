/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package cmd

import (
	"fmt"
	"appdef/tool/components/context"
	"github.com/spf13/cobra"
)

var checkCmdSilentFlag bool

func init() {
	rootCmd.AddCommand(checkCmd)
	checkCmd.Flags().BoolVarP(&checkCmdSilentFlag, "silent", "s", false, "Don't output anything when spec is valid")
}

var checkCmd = &cobra.Command{
	Use:   "check",
	Short: "Check the appdef file for errors",
	Long: `
  This command simply performs the go and jsonschema validation
  then exits with a zero status on success or non-zero on
  failure.`,
	Run: func(cmd *cobra.Command, args []string) {

		_, err := context.BuildFromConfig(config)
		if err != nil {
			Die(err)
		}

		if !checkCmdSilentFlag {
			fmt.Println(config.SpecPath, "passed validation 👍")
		}
	},
}
