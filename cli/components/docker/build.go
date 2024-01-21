/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package docker

import (
	. "appdef/tool/components/context"
)

func BuildCtx(ctx *Context, remotePrefix string, buildCmdTag string, push bool) error {

	for _, app := range(ctx.Spec.Apps) {
		if app.Tag != "" { continue }
		image := remotePrefix + app.Image +":"+ buildCmdTag
		if err := BuildImage(image, ctx.AppRoot+"/"+app.Build); err != nil {
			return err
		}

		if push {
			if err := PushImage(image); err != nil {
				return err
			}
		}
	}

	for _, start := range(ctx.Spec.Startup) {
		if start.Tag != "" { continue }
		image := remotePrefix + start.Image +":"+ buildCmdTag
		if err := BuildImage(image, ctx.AppRoot+"/"+start.Build); err != nil {
			return err
		}

		if push {
			if err := PushImage(image); err != nil {
				return err
			}
		}
	}

	for _, cron := range(ctx.Spec.Cron) {
		if cron.Tag != "" { continue }
		image := remotePrefix + cron.Image +":"+ buildCmdTag
		if err := BuildImage(image, ctx.AppRoot+"/"+cron.Build); err != nil {
			return err
		}

		if push {
			if err := PushImage(image); err != nil {
				return err
			}
		}
	}

	return nil
}
