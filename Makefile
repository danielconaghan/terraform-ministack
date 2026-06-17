ENDPOINT   := http://localhost:4566
INTERNAL   := http://ministack:4566
TF         := docker compose run --rm terraform -chdir=terraform
AWS_LOCAL  := docker run --rm --network ministack-net \
                -v $(CURDIR):/workspace -w /workspace \
                -e AWS_ACCESS_KEY_ID=000000000000 \
                -e AWS_SECRET_ACCESS_KEY=test \
                amazon/aws-cli \
                --endpoint-url=$(INTERNAL) --region us-east-1
PHP_IMG    := bref/php-83:latest
LAYER_NAME := bref-php-83
LAYER_DIR  := $(CURDIR)/.layer
LAYER_ZIP  := $(LAYER_DIR)/$(LAYER_NAME).zip

.DEFAULT_GOAL := help

.PHONY: help start stop up down layer build init deploy-local test-local destroy-local clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

start: up layer init deploy-local ## Full bootstrap: start ministack, publish layer, build, and deploy

stop: ## Tear everything down: destroy infra (if deployed) then stop ministack
	@if [ -f terraform/.terraform.lock.hcl ]; then \
	  $(MAKE) destroy-local; \
	fi
	$(MAKE) down

up: ## Start ministack
	docker compose up -d
	@echo "Waiting for ministack to be ready..."
	@until nc -z localhost 4566 2>/dev/null; do \
	  printf '.'; sleep 1; \
	done; echo " ministack ready."

down: ## Stop ministack
	docker compose down

layer: ## Pull Bref PHP 8.3 from Docker, extract /opt, and publish as a layer to ministack
	@echo "Pulling $(PHP_IMG)..."
	docker pull $(PHP_IMG)
	@echo "Extracting /opt from container..."
	@mkdir -p $(LAYER_DIR)
	@CID=$$(docker create $(PHP_IMG)); \
	  rm -rf $(LAYER_DIR)/opt; \
	  mkdir -p $(LAYER_DIR)/opt; \
	  docker cp $$CID:/opt/. $(LAYER_DIR)/opt/; \
	  docker rm $$CID
	@echo "Zipping layer..."
	@cd $(LAYER_DIR)/opt && zip -r $(LAYER_ZIP) . -q
	@echo "Publishing layer to ministack..."
	@$(AWS_LOCAL) lambda publish-layer-version \
	  --layer-name $(LAYER_NAME) \
	  --zip-file fileb:///workspace/.layer/$(LAYER_NAME).zip \
	  --compatible-runtimes provided.al2023 \
	  --query 'LayerVersionArn' \
	  --output text

build: ## Install Composer deps and package lambda.zip
	composer install --no-dev --optimize-autoloader
	@rm -f lambda.zip
	zip -r lambda.zip bootstrap index.php vendor/

init: ## Terraform init
	$(TF) init

deploy-local: build ## Build and deploy to local ministack (terraform apply)
	$(TF) apply -var-file=local.tfvars -auto-approve

test-local: ## Invoke the GET / endpoint via the local API Gateway
	@API_ID=$$($(AWS_LOCAL) apigatewayv2 get-apis \
	  --query 'Items[?Name==`hello-world-api`].ApiId' \
	  --output text); \
	STAGE='$$default'; \
	URL="$(ENDPOINT)/_aws/execute-api/$$API_ID/$$STAGE/"; \
	echo "GET $$URL"; \
	curl -s "$$URL" | python3 -m json.tool

destroy-local: init ## Destroy all ministack resources (terraform destroy)
	$(TF) destroy -var-file=local.tfvars -auto-approve

clean: ## Remove local build artifacts
	rm -f lambda.zip
	rm -rf vendor/ $(LAYER_DIR)
