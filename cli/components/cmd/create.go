/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package cmd

import (
	"appdef/tool/components/templates"
	"github.com/spf13/cobra"
	"os"
	"fmt"
)

func init() {
	rootCmd.AddCommand(createCmd)
}

var createCmd = &cobra.Command{
	Use:   "create [name]",
	Short: "Write a skeleton appdef",
	Long: `
	Outputs a skeleton appdef.
  `,
	Run: func(cmd *cobra.Command, args []string) {

		if len(args) != 1 {
			fmt.Fprintln(os.Stderr, "create requires one argument")
			fmt.Fprintln(os.Stderr, cmd.UseLine())
			os.Exit(1)
		}

		createName := args[0]

		cfg := map[string]string{
			"name": createName,
		}

		if err := templates.Skeleton.Write(cfg, os.Stdout); err != nil {
			panic(err)
		}
	},
}
