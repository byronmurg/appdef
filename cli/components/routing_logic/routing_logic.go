/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package routing_logic

import (
	. "appdef/tool/components/config"
	. "appdef/tool/components/spec"
	"strconv"
)

func BuildUrlMap(spec *Spec, config *Config) map[string]string {
	ret := map[string]string{}
	portStr := strconv.Itoa(config.LocalPort)

	for key, app := range spec.Apps {
		var hostname = spec.Name + ".localhost:" + portStr + app.Path

		if app.Subdomain != "" {
			hostname = app.Subdomain + "." + hostname
		}

		ret[key] = "http://" + hostname
	}

	return ret
}

func array_contains[T comparable](container []T, value T) bool {
	for _, v := range container {
		if v == value {
			return true
		}
	}
	return false
}

func BuildSubdomainList(spec *Spec) []string {
	ret := []string{""}

	for _, app := range spec.Apps {
		if array_contains(ret, app.Subdomain) {
			continue
		} else {
			ret = append(ret, app.Subdomain)
		}
	}

	return ret
}
