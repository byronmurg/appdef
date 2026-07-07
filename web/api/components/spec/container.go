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
