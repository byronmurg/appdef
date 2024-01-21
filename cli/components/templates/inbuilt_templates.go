/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package templates

import (
	_ "embed"
)

//go:embed compose.yaml
var composeTemplate string
var Compose = build("compose", composeTemplate)

//go:embed nginx.conf
var nginxTemplate string
var Nginx = build("nginx", nginxTemplate)

//go:embed skeleton.yaml
var skeletonTemplate string
var Skeleton = build("skeleton", skeletonTemplate)
