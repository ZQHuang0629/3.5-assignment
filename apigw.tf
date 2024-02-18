resource "aws_api_gateway_rest_api" "example_api" {
  name = "${var.your_name}-lambda-api"
}
resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "hello"
}
resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.example_api.id
  resource_id             = aws_api_gateway_resource.example_resource.id
  http_method             = aws_api_gateway_method.example_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_lambda.invoke_arn
}
resource "aws_api_gateway_api_key" "zhangqin_api_key_terraform" {
  name = "zhangqin_api_key_terraform"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example_api.execution_arn}/*/*"
}
resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.example_api.body,
      aws_api_gateway_method.example_method
      ]))
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_method.example_method, aws_api_gateway_integration.integration]
}
resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  stage_name    = "dev"
}

resource "aws_api_gateway_usage_plan" "zhangqin_usage_plan-tf" {
  name         = "zhangqin-usage-plan-tf"
  description  = "zq description for tf"
 # product_code = "MYCODE"

  api_stages {
    api_id = aws_api_gateway_rest_api.example_api.id
    #stage  = aws_api_gateway_stage.development.stage_name
    stage = aws_api_gateway_stage.example.stage_name
  }
}

  # api_stages {
  #   api_id = aws_api_gateway_rest_api.example.id
  #   stage  = aws_api_gateway_stage.production.stage_name
  # }

  # quota_settings {
  #   limit  = 20
  #   offset = 2
  #   period = "WEEK"
  # }

  # throttle_settings {
  #   burst_limit = 5
  # #   rate_limit  = 5
  # }

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.zhangqin_api_key_terraform.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.zhangqin_usage_plan-tf.id


}
