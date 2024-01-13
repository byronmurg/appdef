/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package spec

type SecretSpec struct {
	Description string `json:"description",yaml:"description"`
	Var         string `json:"var",yaml:"var"`
}

type SecretMap = []SecretSpec
