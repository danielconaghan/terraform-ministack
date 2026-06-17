# terraform-ministack

A self-contained local development stack that mimics a serverless AWS environment on your laptop. It runs a PHP 8.3 Lambda function behind an HTTP API Gateway, provisioned with Terraform — all without touching a real AWS account.

The stack is built from three pieces:

- **LocalStack** ("ministack") — emulates AWS services (Lambda, API Gateway, IAM) inside Docker
- **Bref** — supplies the PHP runtime as a Lambda layer pulled straight from the official Docker image
- **Terraform** — provisions and wires everything together using the same infrastructure-as-code you'd use in production

The included `index.php` is a minimal "hello world" HTTP handler, but the stack is structured so you can drop in any Bref-compatible PHP application.

---

## Prerequisites

- Docker & Docker Compose
- `make`
- `composer`
- `nc` (netcat, for health checks)
- `python3` (for JSON formatting in test output)

## Quick start

```sh
make start     # Full bootstrap: start ministack, publish layer, build, and deploy
make test-local
make stop
```

## Makefile reference

| Command | Description |
|---|---|
| `make help` | List all available targets with descriptions |
| `make start` | Full bootstrap — runs `up`, `layer`, `init`, and `deploy-local` in sequence |
| `make stop` | Destroy deployed infra (if any) then stop ministack |
| `make up` | Start ministack (LocalStack) via Docker Compose and wait until ready |
| `make down` | Stop and remove ministack containers |
| `make layer` | Pull Bref PHP 8.3 image, extract `/opt`, zip it, and publish as a Lambda layer to ministack |
| `make build` | Install Composer deps (no-dev) and package `lambda.zip` |
| `make init` | Run `terraform init` inside the container |
| `make deploy-local` | Build and deploy to ministack via `terraform apply` (uses `local.tfvars`) |
| `make test-local` | Invoke the `GET /` endpoint on the local API Gateway and pretty-print the JSON response |
| `make destroy-local` | Tear down all ministack Terraform resources via `terraform destroy` |
| `make clean` | Remove `lambda.zip`, `vendor/`, and the cached layer directory |

## How it works

1. **LocalStack** runs inside Docker and emulates AWS services (Lambda, API Gateway, IAM) on `http://localhost:4566`.
2. **Bref** provides the PHP runtime as a Lambda layer. The `layer` target pulls the official Docker image, extracts `/opt`, and publishes the zip to LocalStack.
3. **Terraform** (also containerised) provisions the Lambda function, layer attachment, and HTTP API Gateway using `terraform/local.tfvars` for local overrides.
4. The PHP entry point is `index.php`, packaged alongside `bootstrap` and `vendor/` into `lambda.zip`.
