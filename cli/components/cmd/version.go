package cmd

import (
	"fmt"
	"appdef/tool/components/version"
	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(versionCmd)
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Output the version",
	Long:  `Just outputs the version string.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Print(version.GetVersion())
	},
}
