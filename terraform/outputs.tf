output "api_endpoint" {
  description = "Base URL of the API Gateway endpoint"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.hello_world.function_name
}
