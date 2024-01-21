/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package spec

import (
	"appdef/api/components/utils"
)

type Spec struct {
	Name         string                  `json:"name",yaml:"name"`
	Apps         map[string]AppSpec      `json:"apps",yaml:"apps"`
	Cron         map[string]CronSpec     `json:"cron",yaml:"cron"`
	Startup      map[string]StartupSpec  `json:"startup",yaml:"startup"`
	External     map[string]ExternalSpec `json:"external",yaml:"external"`
	Mongo        DbSpec                  `json:"mongo",yaml:"mongo"`
	Postgresql   DbSpec                  `json:"postgresql",yaml:"postgresql"`
	S3           DbSpec                  `json:"s3",yaml:"s3"`
	SecretSource string                  `json:"secret_source",yaml:"secret_source"`
}

func (s *Spec) ExposedApps() map[string]AppSpec {
	ret := map[string]AppSpec{}

	for appName, app := range(s.Apps) {
		if app.Path != "" {
			ret[appName] = app
		}
	}

	return ret
}

func (s *Spec) BuildSecretList() []string {
	var ret []string

	containerList := s.BuildContainerList()

	for _, entry := range containerList {
		secretMap := entry.Container.Secrets()

		for _, secret := range secretMap {
			if !utils.ArrayContains(ret, secret.Var) {
				ret = append(ret, secret.Var)
			}
		}
	}

	return ret
}

func (s *Spec) BuildSubdomainList() []string {
	ret := []string{""}

	for _, app := range s.Apps {
		if utils.ArrayContains(ret, app.Subdomain) {
			continue
		} else {
			ret = append(ret, app.Subdomain)
		}
	}

	return ret
}

func (s *Spec) BuildContainerMap() map[string]Container {
	ret := map[string]Container{}

	for name, app := range s.Apps {
		ret["app-"+name] = AppContainer{spec: app}
	}

	for name, cron := range s.Cron {
		ret["cron-"+name] = CronContainer{spec: cron}
	}

	for name, startup := range s.Startup {
		ret["startup-"+name] = StartupContainer{spec: startup}
	}

	return ret
}

func (s *Spec) BuildContainerList() []ContainerEntry {
	ret := []ContainerEntry{}

	for name, app := range s.Apps {
		entry := ContainerEntry{
			Type:      "app",
			Name:      name,
			Fullname:  "app-" + name,
			Container: AppContainer{spec: app},
		}
		ret = append(ret, entry)
	}

	for name, cron := range s.Cron {
		entry := ContainerEntry{
			Type:      "cron",
			Name:      name,
			Fullname:  "cron-" + name,
			Container: CronContainer{spec: cron},
		}
		ret = append(ret, entry)
	}

	for name, startup := range s.Startup {
		entry := ContainerEntry{
			Type:      "startup",
			Name:      name,
			Fullname:  "startup-" + name,
			Container: StartupContainer{spec: startup},
		}
		ret = append(ret, entry)
	}

	return ret
}

type ExternalSpec struct {
	Hostname string `json:"hostname",yaml:"hostname"`
	Ports    []int  `json:"ports",yaml:"ports"`
}

type ContainerExternalSpec struct {
	Name string `json:"name",yaml:"name"`
}

type ContainerDbSpec struct {
	Use bool   `json:"use",yaml:"use"`
	Db  string `json:"db",yaml:"db"`
	Priviledged bool `json:"priviledged",yaml:"priviledged"`
}

type DbInstanceSpec struct {
	Name string `json:"name",yaml:"name"`
}

type DbSpec struct {
	Enabled bool             `json:"enabled",yaml:"enabled"`
	Dbs     []DbInstanceSpec `json:"dbs",yaml:"dbs"`
}

// This is a helper function as this is really hard to do in go templates
func (s DbSpec) DbNames() []string {
	var ret []string

	for _, db := range s.Dbs {
		ret = append(ret, db.Name)
	}

	return ret
}
