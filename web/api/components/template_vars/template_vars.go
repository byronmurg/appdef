package template_vars

type TemplateVars struct {
	SecretPrefix string `json:"SecretPrefix", form:"SecretPrefix"`
	BucketName string `json:"BucketName", form:"BucketName"`
}
