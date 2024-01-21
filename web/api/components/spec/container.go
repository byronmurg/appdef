/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package spec

type ContainerEntry struct {
	Type      string
	Name      string
	Fullname  string
	Container Container
}

type Container interface {
	Image() string
	Build() string
	Mongo() ContainerDbSpec
	S3() ContainerDbSpec
	Postgresql() ContainerDbSpec
	Secrets() SecretMap
	External() []ContainerExternalSpec
}
