/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package config

type Config struct {
	SpecPath     string
	WriteDir     string
	LocalPort    int
	Expose       []string
	SecretSource string
	TemplateVars map[string]string
}
