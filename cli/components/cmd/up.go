/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package cmd

import (
	"appdef/tool/components/templates"
	"appdef/tool/components/context"
	"appdef/tool/components/dev_hints"
	"appdef/tool/components/docker"
	"github.com/spf13/cobra"
	"os"
)

func init() {
	rootCmd.AddCommand(upCmd)
	upCmd.Flags().StringVarP(&config.WriteDir, "output-dir", "o", "/tmp/", "Directory to output working files")
}

var upCmd = &cobra.Command{
	Use:   "up",
	Short: "Start up compose to run your appdef",
	Long:  `@TODO Byron write something here`,
	Run: func(cmd *cobra.Command, args []string) {

		ctx, err := context.BuildFromConfig(config)
		if err != nil {
			Die(err)
		}

		nginxData, err := templates.Nginx.Render(ctx)
		if err != nil {
			panic(err)
		}
		os.WriteFile(ctx.NginxConfig, []byte(nginxData), 0600)

		composeData, err := templates.Compose.Render(ctx)
		if err != nil {
			panic(err)
		}
		os.WriteFile(ctx.ComposeConfig, []byte(composeData), 0600)

		dev_hints.PrintDevHints(ctx)

		if err := docker.Build(ctx.ComposeConfig); err != nil {
			panic(err)
		}

		if err := docker.Up(ctx.ComposeConfig); err != nil {
			panic(err)
		}

	},
}
