/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package cmd

import (
	"appdef/tool/components/context"
	"appdef/tool/components/docker"
	"github.com/spf13/cobra"
)

var buildCmdTag string
var buildCmdRemote string
var buildCmdPush bool

func init() {
	rootCmd.AddCommand(buildCmd)
	buildCmd.Flags().StringVarP(&buildCmdTag, "tag", "t", "latest", "tag to use for built images")
	buildCmd.Flags().StringVarP(&buildCmdRemote, "remote", "r", "", "remote to push tag to")
	buildCmd.Flags().BoolVar(&buildCmdPush, "push", false, "push the images after build")
}

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "Build all docker images",
	Long: `Build and push the docker images using the commmit as a reference`,
	Run: func(cmd *cobra.Command, args []string) {

		ctx, err := context.BuildFromConfig(config)
		if err != nil {
			panic(err)
		}

		var remotePrefix = ""
		if buildCmdRemote != "" {
			remotePrefix = buildCmdRemote +"/"
		}

		if err := docker.BuildCtx(ctx, remotePrefix, buildCmdTag, buildCmdPush); err != nil {
			panic(err)
		}

	},
}
