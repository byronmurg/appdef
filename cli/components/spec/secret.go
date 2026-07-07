package spec

type SecretSpec struct {
	Description string `json:"description",yaml:"description"`
	Var         string `json:"var",yaml:"var"`
}

type SecretMap = []SecretSpec
