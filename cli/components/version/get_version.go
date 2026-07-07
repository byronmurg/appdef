package version

import _ "embed"

//go:embed VERSION
var versionString string

func GetVersion() string {
	return versionString
}
