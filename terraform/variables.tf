variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "local_endpoint" {
  description = "Override all AWS service endpoints to point at a local emulator (e.g. ministack). Leave null for real AWS."
  type        = string
  default     = null
}

variable "bref_layer_arn" {
  description = "ARN of the Bref PHP 8.3 Lambda layer. Use a locally-published ARN for ministack, or the official Bref ARN for AWS."
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "hello-world"
}
