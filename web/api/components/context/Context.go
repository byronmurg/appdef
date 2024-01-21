/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package context

import (
	. "appdef/api/components/spec"
	"appdef/api/components/template_vars"
	"appdef/api/components/render_query"
)

type Context struct {
	Spec *Spec

	Subdomains   []string
	SecretSource string
	SecretList   []string
	TemplateVars template_vars.TemplateVars

	ContainerMap  map[string]Container
	ContainerList []ContainerEntry
}

func BuildFromRenderQuery(req *render_query.RenderQuery) (*Context, error) {

	checkErr := req.Spec.Check()

	if checkErr != nil {
		return nil, checkErr
	}

	ctx := Context{
		Spec:          &req.Spec,
		SecretList:    req.Spec.BuildSecretList(),
		TemplateVars:  req.TemplateVars,
		Subdomains:    req.Spec.BuildSubdomainList(),
		ContainerMap:  req.Spec.BuildContainerMap(),
		ContainerList: req.Spec.BuildContainerList(),
	}

	return &ctx, nil
}
