/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package dev_hints

import (
	"fmt"
	. "appdef/tool/components/context"
	s "strings"
	"os"
)

var rc = "\x1b[91m"
var yc = "\x1b[93m"
var cc = "\x1b[0m"

var _coolHeader = `
                       _       __ 
  __ _ _ __  _ __   __| | ___ / _|
 / _  | '_ \| '_ \ / _  |/ _ \ |_ 
| (_| | |_) | |_) | (_| |  __/  _|
 \__,_| .__/| .__/ \__,_|\___|_|  
      |_|   |_|                   

`

func isTTY(output *os.File) bool {
    fileInfo, _ := output.Stat()
	return (fileInfo.Mode() & os.ModeCharDevice) != 0
}

var stdOutisTTY = isTTY(os.Stdout)

func printCoolHeader() {
	fmt.Println(_coolHeader)
}

func printUrlMappings(ctx *Context) {
	fmt.Println("url mappings:")
	for app, route := range ctx.UrlMap {
		paddedName := padString(app)
		fmt.Println(colourGreen(paddedName) + " => " + route)
	}
}

func printAppStructure(ctx *Context) {
	fmt.Println("app structure:")
	for _, sub := range ctx.Subdomains {

		var nice_sub = sub
		if sub == "" {
			nice_sub = "(root)"
		}

		fmt.Println("\t", nice_sub)
		for key, app := range ctx.Spec.Apps {
			if app.Subdomain != sub {
				continue
			}
			fmt.Println("\t\t", app.Path, "=>", key)
		}
	}
}

func PrintDevHints(ctx *Context) {
	printCoolHeader()
	printUrlMappings(ctx)
	printAppStructure(ctx)
}

func padString(str string) string {
	return s.Repeat(" ", 16-len(str)) + str
}

func coloutString(str string, colour string) string {
	if stdOutisTTY {
		return "\x1b["+colour+"m" + str + "\x1b[0m"
	} else {
		return str
	}
}

func colourGreen(str string) string {
	return coloutString(str, "92")
}
