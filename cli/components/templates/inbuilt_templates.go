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
