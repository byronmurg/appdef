/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package check

import (
	"errors"
	"fmt"
	"appdef/tool/components/utils"
	"github.com/xeipuuv/gojsonschema"
)

func CheckSpec(spec any) error {
	strKeyRawSpec, strKErr := utils.ToStringKeys(spec)
	if strKErr != nil {
		return strKErr
	}

	schemaLoader := gojsonschema.NewStringLoader(LoadSchema())
	specLoader := gojsonschema.NewGoLoader(strKeyRawSpec)

	result, err := gojsonschema.Validate(schemaLoader, specLoader)
	if err != nil {
		panic(err.Error())
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
