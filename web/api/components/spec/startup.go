/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package spec

type StartupSpec struct {
	Image      string          `json:"image",yaml:"image"`
	User       int             `json:"user",yaml:"user"`
	ReadOnly   bool            `json:"read_only",yaml:"read_only"`
	Tag        string          `json:"tag",yaml:"tag"`
	Build      string          `json:"build",yaml:"build"`
	Secrets    SecretMap       `json:"secrets",yaml:"secrets"`
	Mongo      ContainerDbSpec `json:"mongo",yaml:"mongo"`
	Postgresql ContainerDbSpec `json:"postgresql",yaml:"postgresql"`
	S3         ContainerDbSpec `json:"s3",yaml:"s3"`

	External []ContainerExternalSpec `yaml:"external"`
}

type StartupContainer struct {
	spec StartupSpec
}

func (s StartupContainer) Image() string {
	return s.spec.Image
}

func (s StartupContainer) Mongo() ContainerDbSpec {
	return s.spec.Mongo
}

func (s StartupContainer) Postgresql() ContainerDbSpec {
	return s.spec.Postgresql
}

func (s StartupContainer) S3() ContainerDbSpec {
	return s.spec.S3
}

func (s StartupContainer) Secrets() SecretMap {
	return s.spec.Secrets
}

func (s StartupContainer) External() []ContainerExternalSpec {
	return s.spec.External
}

func (s StartupContainer) Build() string {
	return s.spec.Build
}
