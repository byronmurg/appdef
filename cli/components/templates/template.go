/* Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
 */
package templates

import (
	"bytes"
	"github.com/Masterminds/sprig/v3"
	"io"
	"text/template"
)

type Template interface {
	Write(any, io.Writer) error
	Render(any) (string, error)
}

type goTemplate struct {
	goTmpl *template.Template
}

func (s goTemplate) Write(ctx any, fd io.Writer) error {
	return s.goTmpl.Execute(fd, ctx)
}

func (s goTemplate) Render(ctx any) (string, error) {
	var buf bytes.Buffer
	err := s.goTmpl.Execute(&buf, ctx)
	if err != nil {
		return "", err
	}
	return buf.String(), nil
}

func createTemplateFunctionMap() template.FuncMap {
	funcMap := sprig.TxtFuncMap()
	funcMap["toTf"] = toTf
	return funcMap
}

func build(name string, templateData string) Template {
	t := template.New(name)
	funcMap := createTemplateFunctionMap()

	// This implements a helm-style "include" function.
	// It has to be recreated each time as it references
	// the calling template.
	funcMap["include"] = func(name string, data interface{}) (string, error) {
		buf := bytes.NewBuffer(nil)
		if err := t.ExecuteTemplate(buf, name, data); err != nil {
			return "", err
		}
		return buf.String(), nil
	}

	goTmpl := template.Must(t.Funcs(funcMap).Parse(templateData))

	return goTemplate{goTmpl: goTmpl}
}
