package check

import _ "embed"

//go:embed appdef.schema.json
var schema string

// just return the inbuilt spec
func LoadSchema() string {
	return schema
}
