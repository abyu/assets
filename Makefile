ifndef MAKE_DEBUG
.SILENT: ;					# no need for `\@`
endif
.EXPORT_ALL_VARIABLES: ;	# send all vars to shell

SHELL 		:=$(shell which zsh)
.SHELLFLAGS :=-c
WORKDIR 	:=$(shell pwd)
GO_VERSION := 1.16
BIN_DIR := $(GOPATH)/bin

OPEN_API_FILES  := $(wildcard api/*.yaml)
$(info $$OPEN_API_FILES is [${OPEN_API_FILES}])

### FORMATTING
.PHONY: format
format: ## Runs 'go fmt' over all go files
	go fmt ./...

### CLEANING
.PHONY: clean-app
clean-app: ## Removes the config binary
	echo ">> cleaning output (binary)"
	rm -f output/assets

.PHONY: clean
clean: clean-app ## Cleans all temp artefacts

### DEPENDENCIES
.PHONY: build-dependencies
build-dependencies:
	echo ">> Building dependencies..."
	go get -u github.com/rakyll/gotest; \
	go get -d -v ./...;


# The `gen` target depends on the `validate` target as
# it will only succesfully generate the code if the specification
# is valid.
#
# Here we're specifying some flags:
# --target              the base directory for generating the files;
# --spec                path to the swagger specification;
# --exclude-main        generates only the library code and not a
#                       sample CLI application;
# --name   							the name of the application.
define generate_server_api_file
# $(1) is the api file to gen
		( BASE_PATH=`yq r $(1) servers[0].url | sed 's/https\?:\/\/[^\/]\+\/\(my-app\)\?//'`; \
		echo ">> Generating Server API for $(1)"; \
		echo ">> Base Path: $$BASE_PATH"; \
		TITLE=`yq r $(1) info.title | sed "s/ /_/g" | sed "s/_API//g"| tr '[A-Z]' '[a-z]'`; \
		echo ">> Title: $$TITLE"; \
		PACKAGE=`echo $${TITLE}$${BASE_PATH} | sed "s/[ \/]//g"`; \
		echo ">> Package: $$PACKAGE"; \
		mkdir -p ./internal/gen/api/$${PACKAGE}/server; \
		go run github.com/deepmap/oapi-codegen/cmd/oapi-codegen -package $${PACKAGE}_svr \
			-o ./internal/gen/api/$${PACKAGE}/server/server.go \
			-generate types,server,spec $(1) \
		)
endef

.PHONY: generate-server-apis
generate-server-apis: $(GOSWAGGER) $(YQ) $(OPEN_API_FILES) ## Generate the server API files
		$(foreach API_FILE,$(OPEN_API_FILES), $(call generate_server_api_file,${API_FILE}))

.PHONY: generate-server-apis-quiet
generate-server-apis-quiet: $(GOSWAGGER) $(YQ) $(OPEN_API_FILES) ## Generate the server API files
		$(foreach API_FILE,$(OPEN_API_FILES), $(call generate_server_api_file,${API_FILE},-q))


### Go Application
.PHONY: check-go-version
check-go-version:
	echo -n "Checking for go version $(GO_VERSION)... "; \
	if go version | grep --silent "go$(GO_VERSION)"; then \
		echo -e "\e[32mOK\e[0m"; \
	else \
		echo -e "\e[31mwrong version!\e[0m"; \
		exit 1; \
	fi;

### TEST
.PHONY: test
test: check-go-version clean build-dependencies ## Runs tests e.g. go test ./...
	set +e; \
	gotest -v ./... -count=1; \
	EXIT_CODE=$$?; \
	set -e; \
	if [[ "$$EXIT_CODE" != "0" ]]; then \
		echo -e "\e[31m#######################################################################################################\e[0m"; \
	  	echo -e "\e[31mTESTS FAILED!!!!\e[0m"; \
		echo -e "\e[31m#######################################################################################################\e[0m"; \
  		exit 1; \
	else \
		echo -e "\e[32m#######################################################################################################\e[0m"; \
  		echo -e "\e[32mTests Passed\e[0m"; \
		echo -e "\e[32m#######################################################################################################\e[0m"; \
	fi


.PHONY: build-standalone
build-standalone:
	go build \
    -a \
    -installsuffix cgo \
    -o ./output/assets ./cmd/main.go
	echo "#######################################################################################################"
	echo -e "\e[32mSuccessfully built application in ./output/asserts\e[0m"
	echo "#######################################################################################################"

.PHONY: build
build: test format generate-server-apis-quiet build-standalone ## Builds the app and places it in output folder.
