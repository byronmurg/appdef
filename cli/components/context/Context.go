/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package context

import (
	"encoding/json"
	"errors"
	. "appdef/tool/components/config"
	"appdef/tool/components/routing_logic"
	"appdef/tool/components/check"
	. "appdef/tool/components/spec"
	"gopkg.in/yaml.v2"
	"io/ioutil"
	"os"
	"path/filepath"
	s "strings"
)

type Context struct {
	Spec          *Spec
	GoSpec        any
	NginxConfig   string
	ComposeConfig string

	Cwd     string
	AppRoot string

	Config *Config

	UrlMapJson string
	UrlMap     map[string]string
	Subdomains []string

	Expose map[string]string

	ContainerMap  map[string]Container
	ContainerList []ContainerEntry
}

func BuildFromConfig(config *Config) (*Context, error) {
	raw, err := ioutil.ReadFile(config.SpecPath)
	if err != nil {
		return nil, err
	}

	var goSpec interface{}
	if err := yaml.Unmarshal(raw, &goSpec); err != nil {
		return nil, err
	}

	if err := check.CheckSpec(goSpec); err != nil {
		return nil, err
	}

	spec := Spec{}
	if err := yaml.Unmarshal(raw, &spec); err != nil {
		return nil, err
	}

	/*
     * build the container structures
	 */
	containerMap := spec.BuildContainerMap()
	containerList := spec.BuildContainerList()

	/*
	 * build the url map
	 */

	urlMap := routing_logic.BuildUrlMap(&spec, config)
	urlMapJSON, jsErr := json.Marshal(urlMap)
	if jsErr != nil {
		return nil, jsErr
	}

	cwd, err := os.Getwd()
	if err != nil {
		return nil, err
	}

	/*
	 * build the config structure
	 */
	ctx := Context{
		Spec:          &spec,
		GoSpec:        goSpec,
		UrlMap:        urlMap,
		UrlMapJson:    string(urlMapJSON),
		Subdomains:    routing_logic.BuildSubdomainList(&spec),
		Config:        config,
		NginxConfig:   config.WriteDir + "/nginx.conf",
		ComposeConfig: config.WriteDir + "/compose.yaml",
		Cwd:           cwd,
		AppRoot:       filepath.Dir(config.SpecPath),
		Expose:        map[string]string{},
		ContainerMap:  containerMap,
		ContainerList: containerList,
	}

	for _, expose := range config.Expose {
		parts := s.Split(expose, ":")
		if len(parts) != 2 {
			return nil, errors.New("invalid expose flag: " + expose)
		}

		ctx.Expose[parts[0]] = parts[1]
	}

	return &ctx, nil
}
