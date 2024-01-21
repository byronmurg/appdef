package main

import (
	"github.com/gin-contrib/gzip"
	"github.com/gin-gonic/gin"
	"appdef/api/components/check"
	"appdef/api/components/context"
	"appdef/api/components/templates"
	"appdef/api/components/render_query"
	"io/ioutil"
	"net/http"
)

func main() {
	router := gin.Default()

	router.Use(gzip.Gzip(gzip.DefaultCompression))

	router.GET("/api/appdef-schema.json", getJsonSchema)
	router.POST("/api/render/k8s", generateTemplateHandler(templates.Kubernetes))
	router.POST("/api/render/gcp-cloud-run", generateTemplateHandler(templates.GcpCloudRun))
	router.POST("/api/render/github-gke", generateTemplateHandler(templates.GithubGKE))
	router.POST("/api/render/github-gcp-cloud-run", generateTemplateHandler(templates.GithubGcpCloudRun))

	router.StaticFile("/asset-manifest.json", "./ui/build/asset-manifest.json")
	router.StaticFile("/favicon.ico", "./ui/build/favicon.ico")
	router.StaticFile("/logo192.png", "./ui/build/logo192.png")
	router.StaticFile("/logo512.png", "./ui/build/logo512.png")
	router.StaticFile("/manifest.json", "./ui/build/manifest.json")
	router.StaticFile("/robots.txt", "./ui/build/robots.txt")

	router.Static("/static", "./ui/build/static")

	// Just return the index when no file is found
	router.NoRoute(func(c *gin.Context) {
		c.File("./ui/build/index.html")
	})

	router.Run("0.0.0.0:5000")
}

func generateTemplateHandler(tmpl templates.Template) func(*gin.Context) {
	return func(c *gin.Context) {

		// Read the json body from the request
		jsonData, readErr := ioutil.ReadAll(c.Request.Body)
		if readErr != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": readErr,
			})
			return
		}

		// Validate the json input
		result, err := render_query.Validate(jsonData)

		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": readErr,
			})
			return
		}

		// Send any validation errors as a json array
		if !result.Valid() {
			schemaErrors := []string{}
			for _, res := range result.Errors() {
				desc := res.Field() + ": " + res.Description()
				schemaErrors = append(schemaErrors, desc)
			}

			c.JSON(http.StatusBadRequest, gin.H{
				"format_errors": schemaErrors,
			})
			return
		}

		// Build the template context
		ctx, ctxErr := BuildContextFromBody(jsonData)

		if ctxErr != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": ctxErr.Error(),
			})
			return
		}

		// Render the template
		tf, templateErr := tmpl.Render(ctx)
		if templateErr != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": templateErr.Error(),
			})
			return
		}

		// Send the template output in a json block
		c.IndentedJSON(http.StatusOK, gin.H{
			"output": tf,
		})
	}
}

func getJsonSchema(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, check.LoadSchema())
}

func BuildContextFromBody(raw []byte) (*context.Context, error) {
	req, err := render_query.UnmarshalJson(raw)
	if err != nil {
		return nil, err
	}

	return context.BuildFromRenderQuery(req)
}
