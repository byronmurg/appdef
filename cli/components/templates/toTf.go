/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package templates

import (
	"errors"
	"reflect"
	"strconv"
	"strings"
)

/*
 * escape a string for terraform
 */

func quoteTf(str string) string {
	var escapedStr = str
	escapedStr = strings.Replace(escapedStr, `\`, `\\`, -1)
	escapedStr = strings.Replace(escapedStr, `"`, `\"`, -1)
	return `"` + escapedStr + `"`
}

/*
 * Convert
 */

func toTf(v any) (string, error) {
	if v == nil {
		return "null", nil
	}

	t := reflect.TypeOf(v)

	switch t.Kind() {
	case reflect.String:
		return quoteTf(v.(string)), nil
	case reflect.Int:
		return strconv.Itoa(v.(int)), nil
	case reflect.Map:
		s := reflect.ValueOf(v)
		var ret []string

		for _, key := range s.MapKeys() {
			keyStr, keyErr := toTf(key.Interface())
			if keyErr != nil {
				return "", keyErr
			}

			valStr, valErr := toTf(s.MapIndex(key).Interface())
			if keyErr != nil {
				return "", valErr
			}

			ret = append(ret, keyStr+" = "+valStr)
		}

		return "{" + strings.Join(ret, ", ") + "}", nil
	case reflect.Slice:
		s := reflect.ValueOf(v)
		var ret []string

		for i := 0; i < s.Len(); i++ {
			elem, err := toTf(s.Index(i).Interface())
			if err != nil {
				return "", err
			}
			ret = append(ret, elem)
		}

		return "[" + strings.Join(ret, ", ") + "]", nil
	default:
		return "", errors.New("unknown value type passed to toTf: " + t.Name())
	}
}
