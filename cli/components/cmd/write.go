/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package cmd

import (
	"fmt"
	"appdef/tool/components/templates"
	"appdef/tool/components/context"
	"appdef/tool/components/dev_hints"
	"github.com/spf13/cobra"
	"os"
)

func init() {
	rootCmd.AddCommand(writeCmd)
	writeCmd.Flags().StringVarP(&config.WriteDir, "output-dir", "o", "/tmp/", "Directory to output working files")
}

var writeCmd = &cobra.Command{
	Use:   "write",
	Short: "Write out the compose and additional files",
	Long: `
  Write the compose and nginx file to a specified directory.
  After running this command you can use:
    docker-compose -f <COMPOSE_FILE> up
  to start the local development environment`,
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

		fmt.Println("writen compose file to", ctx.ComposeConfig)
	},
}
