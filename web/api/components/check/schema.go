/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2020
 */
package check

import (
	_ "embed"
	"encoding/json"
	"log"
)

//go:embed appdef.schema.json
var schema string

func MustUnmarshal(input string) any {
	var v any
	err := json.Unmarshal([]byte(input), &v)
	if err != nil {
		log.Fatalln(err)
	}
	return v
}

var goSchema = MustUnmarshal(schema)

// just return the inbuilt spec
func LoadSchema() any {
	return goSchema
}
