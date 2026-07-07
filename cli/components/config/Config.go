package config

type Config struct {
	SpecPath     string
	WriteDir     string
	LocalPort    int
	Expose       []string
	SecretSource string
	TemplateVars map[string]string
}
