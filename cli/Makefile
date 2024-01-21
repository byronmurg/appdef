PROGRAM=appdef
PREFIX=/usr/local/

VERSION=$(shell cat VERSION)

DEPS=main.go components/*/*.go components/templates/* components/check/appdef.schema.json components/version/VERSION

$(PROGRAM): $(DEPS)
	go build -o $@ $<

build/$(PROGRAM)-$(VERSION)-Linux-amd64: $(DEPS)
	GOOS=linux GOARCH=amd64 go build -o $@ $<

build/$(PROGRAM)-$(VERSION)-Darwin-arm64: $(DEPS)
	GOOS=darwin GOARCH=arm64 go build -o $@ $<

build/$(PROGRAM)-$(VERSION)-Darwin-amd64: $(DEPS)
	GOOS=darwin GOARCH=amd64 go build -o $@ $<

release/%.gz: build/%
	@mkdir -p release
	gzip $< -c > $@
	@chmod 644 $@

release: \
	release/$(PROGRAM)-$(VERSION)-Linux-amd64.gz \
	release/$(PROGRAM)-$(VERSION)-Darwin-arm64.gz \
	release/$(PROGRAM)-$(VERSION)-Darwin-amd64.gz

# These entries are becuase go:embed won't go up a directory to embed a file
components/check/appdef.schema.json: ../appdef.schema.json
	cp -u $< $@

components/version/VERSION: VERSION
	cp -u $< $@

install: $(PROGRAM)
	install -t $(PREFIX)/bin/ $(PROGRAM)

clean:
	@rm -f $(PROGRAM) $(PROGRAM).macos
	@rm -rf build/ release/

.PHONY: clean release install
