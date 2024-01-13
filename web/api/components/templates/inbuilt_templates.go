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

//go:embed gcp-cloud-run.tf
var gcpCloudRunTemplate string
var GcpCloudRun = build("gcp-cloud-run", gcpCloudRunTemplate)

//go:embed github-gke.yml
var githubGKETemplate string
var GithubGKE = build("github-gke", githubGKETemplate)

//go:embed github-gcp-cloud-run.yml
var githubGcpCloudRunTemplate string
var GithubGcpCloudRun = build("github-gcp-cloud-run", githubGcpCloudRunTemplate)

//go:embed kubernetes.tf
var kubernetesTemplate string
var Kubernetes = build("kubernetes", kubernetesTemplate)

//go:embed nginx.conf
var nginxTemplate string
var Nginx = build("nginx", nginxTemplate)

//go:embed skeleton.yaml
var skeletonTemplate string
var Skeleton = build("skeleton", skeletonTemplate)
