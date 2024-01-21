package spec

import (
	"errors"
)

func (s Spec) Check() error {
	subdomains := s.BuildSubdomainList()

	// Check that no path/subdomain pairs match
	for _, subdomain := range(subdomains) {
		pathMap := map[string]string{}

		for appName, app := range(s.Apps) {
			if app.Subdomain == subdomain && app.Path != "" {
				k, exists := pathMap[app.Path]

				if exists {
					return errors.New("app "+ appName +" and "+ k +" have mathing path/subdomain")
				} else {
					pathMap[app.Path] = appName
				}
			}
		}
	}

	return nil
}
