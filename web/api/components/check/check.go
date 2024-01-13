/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package check

import (
	"errors"
	"fmt"
	"github.com/xeipuuv/gojsonschema"
)

var SchemaLoader = gojsonschema.NewGoLoader(LoadSchema())

func checkSpec(specLoader gojsonschema.JSONLoader) error {

	result, err := gojsonschema.Validate(SchemaLoader, specLoader)
	if err != nil {
		return err
	}

	if result.Valid() {
		return nil
	} else {
		var errStr string
		errStr += fmt.Sprintf("The document is not valid. see errors :\n")
		for _, desc := range result.Errors() {
			errStr += fmt.Sprintf("- %s\n", desc)
		}
		return errors.New(errStr)
	}
}

func CheckStringSpec(spec string) error {
	specLoader := gojsonschema.NewStringLoader(spec)
	return checkSpec(specLoader)
}

func CheckGoSpec(spec any) error {
	specLoader := gojsonschema.NewGoLoader(spec)
	return checkSpec(specLoader)
}
