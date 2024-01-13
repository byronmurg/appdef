/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2020
 */
package check

import _ "embed"

//go:embed appdef.schema.json
var schema string

// just return the inbuilt spec
func LoadSchema() string {
	return schema
}
