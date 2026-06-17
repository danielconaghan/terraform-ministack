terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # When local_endpoint is set, all requests go to ministack instead of AWS.
  # Setting access_key to a 12-digit number makes ministack use it as the account ID.
  access_key                  = var.local_endpoint != null ? "000000000000" : null
  secret_key                  = var.local_endpoint != null ? "test" : null
  skip_credentials_validation = var.local_endpoint != null
  skip_metadata_api_check     = var.local_endpoint != null
  skip_requesting_account_id  = var.local_endpoint != null

  dynamic "endpoints" {
    for_each = var.local_endpoint != null ? [1] : []
    content {
      lambda        = var.local_endpoint
      apigateway    = var.local_endpoint
      apigatewayv2  = var.local_endpoint
      iam           = var.local_endpoint
      sts           = var.local_endpoint
    }
  }
}
