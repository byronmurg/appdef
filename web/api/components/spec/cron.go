/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package spec

type CronSpec struct {
	Schedule   string          `json:"schedule",yaml:"schedule"`
	User       int             `json:"user",yaml:"user"`
	ReadOnly   bool            `json:"read_only",yaml:"read_only"`
	Image      string          `json:"image",yaml:"image"`
	Tag        string          `json:"tag",yaml:"tag"`
	Build      string          `json:"build",yaml:"build"`
	Secrets    SecretMap       `json:"secrets",yaml:"secrets"`
	Mongo      ContainerDbSpec `json:"mongo",yaml:"mongo"`
	Postgresql ContainerDbSpec `json:"postgresql",yaml:"postgresql"`
	S3         ContainerDbSpec `json:"s3",yaml:"s3"`

	External []ContainerExternalSpec `json:"external",yaml:"external"`
}

type CronContainer struct {
	spec CronSpec
}

func (s CronContainer) Image() string {
	return s.spec.Image
}

func (s CronContainer) Mongo() ContainerDbSpec {
	return s.spec.Mongo
}

func (s CronContainer) Postgresql() ContainerDbSpec {
	return s.spec.Postgresql
}

func (s CronContainer) S3() ContainerDbSpec {
	return s.spec.S3
}

func (s CronContainer) Secrets() SecretMap {
	return s.spec.Secrets
}

func (s CronContainer) External() []ContainerExternalSpec {
	return s.spec.External
}

func (s CronContainer) Build() string {
	return s.spec.Build
}
