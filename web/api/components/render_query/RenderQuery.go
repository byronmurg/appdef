package render_query

import (
	"encoding/json"

	"appdef/api/components/check"
	"appdef/api/components/template_vars"
	. "appdef/api/components/spec"
	"github.com/xeipuuv/gojsonschema"
)

type RenderQuery struct {
	Spec         Spec         `form:"spec",json:"spec"`
	TemplateVars template_vars.TemplateVars `form:"templateVars",json:"templateVars"`
}

var requestJsonSchema = `
{
	"type": "object",
	"additionalProperties": false,
	"required": ["spec"],
	"properties": {
		"spec": { "$ref":"https://appdef.io/appdef.schema.json" },
		"secretSource": {
			"type": "string",
			"enum": ["none", "doppler", "gcp", "aws"]
		},
		"templateVars": {
			"type": "object",
			"maxItems": 16,
			"additionalProperties": { "type":"string", "maxLength":32 },
			"propertyNames": { "maxLength": 32 }
		}
	}
}
`

func loadReqSchema() *gojsonschema.Schema {
	schemaLoader := gojsonschema.NewSchemaLoader()
	schemaLoader.AddSchema("https://appdef.io/appdef.schema.json", check.SchemaLoader)

	schema, err := schemaLoader.Compile(gojsonschema.NewStringLoader(requestJsonSchema))

	if err != nil {
		panic(err)
	}

	return schema
}

var reqSchema = loadReqSchema()

func Validate(jsonData []byte) (*gojsonschema.Result, error) {
	return reqSchema.Validate(gojsonschema.NewStringLoader(string(jsonData)))
}

func UnmarshalJson(raw []byte) (*RenderQuery, error) {
	req := RenderQuery{}
	err := json.Unmarshal(raw, &req)
	return &req, err
}

