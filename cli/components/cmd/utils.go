/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package cmd

import (
	"fmt"
	"os"
)

func Die(v ...any) {
	fmt.Fprintln(os.Stderr, v...)
	os.Exit(1)
}
