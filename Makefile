DFX  ?= dfx
PORT ?= 8123

EXT_NAME 		   ?= ping
EXT_NAME_INSTALLED ?= $(EXT_NAME)-ext
EXT_VERSION		   ?= $(shell cargo metadata --format-version=1 | jq -r '.packages[] | select(.name == "$(EXT_NAME)") | .version')

DOWNLOAD_URL_TEMPLATE_LOCAL  = http://localhost:$(PORT)/$(EXT_NAME).tar.gz
DOWNLOAD_URL_TEMPLATE_GITHUB = https://github.com/rikonor/dfx-extension-$(EXT_NAME)/releases/download/{{tag}}/{{basename}}.{{archive-format}}

CARGO_TARGET   ?=
CARGO_RELEASE  ?=

CARGO_TARGET_DIR   ?= target$(if $(CARGO_TARGET),/$(CARGO_TARGET))
CARGO_ARTIFACT_DIR ?= $(CARGO_TARGET_DIR)/$(if $(CARGO_RELEASE),release,debug)

EXT_MANIFEST_LOCAL  = dfx/extension.local.json
EXT_MANIFEST_GITHUB = dfx/extension.gh.json

EXT_RELEASE  ?=
EXT_MANIFEST ?= $(if $(EXT_RELEASE),$(EXT_MANIFEST_GITHUB),$(EXT_MANIFEST_LOCAL))

all: install

clean:
	@rm -rf \
		out www \
		*.tar.gz

build:
	cargo build \
		$(if $(CARGO_TARGET),--target $(CARGO_TARGET)) \
		$(if $(CARGO_RELEASE),--release)

manifest:
	@sed \
		-e "s|{{NAME}}|$(EXT_NAME)|g" \
		-e "s|{{VERSION}}|$(EXT_VERSION)|g" \
		-e "s|{{HOMEPAGE}}||g" \
		-e "s|{{DOWNLOAD_URL_TEMPLATE}}|$(DOWNLOAD_URL_TEMPLATE_LOCAL)|g" \
			dfx/extension.json.tmpl > $(EXT_MANIFEST_LOCAL)

	@sed \
		-e "s|{{NAME}}|$(EXT_NAME)|g" \
		-e "s|{{VERSION}}|$(EXT_VERSION)|g" \
		-e "s|{{HOMEPAGE}}|https://github.com/rikonor/dfx-extension-$(EXT_NAME)|g" \
		-e "s|{{DOWNLOAD_URL_TEMPLATE}}|$(DOWNLOAD_URL_TEMPLATE_GITHUB)|g" \
			dfx/extension.json.tmpl > $(EXT_MANIFEST_GITHUB)

bundle: build manifest
	@mkdir -p out
	@cp $(CARGO_ARTIFACT_DIR)/$(EXT_NAME) out/
	@cp $(EXT_MANIFEST) out/extension.json
	@tar -czf $(EXT_NAME).tar.gz out
	@rm -r out

	@rm -rf www && mkdir -p www
	@cp $(EXT_NAME).tar.gz dfx/dependencies.json www/
	@cp $(EXT_MANIFEST) www/extension.json

serve: bundle
	@miniserve www \
		-p $(PORT)

check-serve:
	@curl -s --head --fail http://localhost:$(PORT) >/dev/null && echo "Server is up!" || { \
		echo 'Please run "make serve" first' >&2; exit 1; \
	}

install: bundle check-serve
	@$(DFX) extension uninstall $(EXT_NAME_INSTALLED) || :
	@echo "Installing extension as $(EXT_NAME_INSTALLED)"
	@$(DFX) extension install \
		--install-as $(EXT_NAME_INSTALLED) \
			http://localhost:$(PORT)/extension.json

run:
	@$(DFX) $(EXT_NAME_INSTALLED)

help:
	@$(DFX) $(EXT_NAME_INSTALLED) --help
