/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package spec

type AppSpec struct {
	Path        string          `json:"path",yaml:"path"`
	Subdomain   string          `json:"subdomain",yaml:"subdomain"`
	User        int             `json:"user",yaml:"user"`
	ReadOnly    bool            `json:"read_only",yaml:"read_only"`
	Image       string          `json:"image",yaml:"image"`
	Tag         string          `json:"tag",yaml:"tag"`
	Build       string          `json:"build",yaml:"build"`
	Port        int             `json:"port",yaml:"port"`
	Secrets     SecretMap       `json:"secrets",yaml:"secrets"`
	HealthCheck string          `json:"health_check",yaml:"health_check"`
	Mongo       ContainerDbSpec `json:"mongo",yaml:"mongo"`
	Postgresql  ContainerDbSpec `json:"postgresql",yaml:"postgresql"`
	S3          ContainerDbSpec `json:"s3",yaml:"s3"`

	External []ContainerExternalSpec `json:"external",yaml:"external"`
}

type AppContainer struct {
	spec AppSpec
}

func (s AppContainer) Image() string {
	return s.spec.Image
}

func (s AppContainer) Mongo() ContainerDbSpec {
	return s.spec.Mongo
}

func (s AppContainer) Postgresql() ContainerDbSpec {
	return s.spec.Postgresql
}

func (s AppContainer) S3() ContainerDbSpec {
	return s.spec.S3
}

func (s AppContainer) Secrets() SecretMap {
	return s.spec.Secrets
}

func (s AppContainer) External() []ContainerExternalSpec {
	return s.spec.External
}

func (s AppContainer) Build() string {
	return s.spec.Build
}
