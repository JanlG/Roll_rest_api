# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "roll_dice.py"
  output_path = "roll_dice.zip"
}

data "archive_file" "zip2" {
  type        = "zip"
  source_file = "get_result.py"
  output_path = "get_result.zip"
}


resource "aws_dynamodb_table" "ddbtable" {
  name             = "rollDB"
  hash_key         = "n_dice_count_n_sides"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "n_dice_count_n_sides"
    type = "S"
  }
}


resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.role_for_roll.id

  policy = <<EOT
{  
  "Version": "2012-10-17",
  "Statement":[{
    "Effect": "Allow",
    "Action": [
     "dynamodb:BatchGetItem",
     "dynamodb:GetItem",
     "dynamodb:Query",
     "dynamodb:Scan",
     "dynamodb:BatchWriteItem",
     "dynamodb:PutItem",
     "dynamodb:UpdateItem"
    ],
    "Resource": "*"
   }
  ]
}
EOT
}


resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "roll_dice"
  principal     = "apigateway.amazonaws.com"


  source_arn = "${aws_api_gateway_rest_api.gateway.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "lambda_permission2" {
  statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "get_result"
  principal     = "apigateway.amazonaws.com"


  source_arn = "${aws_api_gateway_rest_api.gateway.execution_arn}/*/*/*"
}


resource "aws_iam_role" "role_for_roll" {
  name = "lambda_role"

  assume_role_policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOT
}


resource "aws_lambda_function" "lambda_post" {
  function_name = "roll_dice"

  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

  role    = "${aws_iam_role.role_for_roll.arn}"
  handler = "roll_dice.lambda_handler"
  runtime = "python3.8"

  environment {
    variables = {
      tablename = "rollDB"
    }
  }
}

resource "aws_lambda_function" "lambda_get" {
  function_name = "get_result"

  filename         = "${data.archive_file.zip2.output_path}"
  source_code_hash = "${data.archive_file.zip2.output_base64sha256}"

  role    = "${aws_iam_role.role_for_roll.arn}"
  handler = "get_result.lambda_handler"
  runtime = "python3.8"
}



resource "aws_api_gateway_rest_api" "gateway" {
  name = "roll_gateway"
}

resource "aws_api_gateway_resource" "main_resource" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  parent_id   = aws_api_gateway_rest_api.gateway.root_resource_id
  path_part   = "simulation"
}

resource "aws_api_gateway_resource" "roll_resource" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  parent_id   = aws_api_gateway_resource.main_resource.id
  path_part   = "roll"
}

resource "aws_api_gateway_resource" "fetch_resource" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  parent_id   = aws_api_gateway_resource.main_resource.id
  path_part   = "fetch"
}

resource "aws_api_gateway_method" "roll_method" {
  rest_api_id   = aws_api_gateway_rest_api.gateway.id
  resource_id   = aws_api_gateway_resource.roll_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "fetch_method" {
  rest_api_id   = aws_api_gateway_rest_api.gateway.id
  resource_id   = aws_api_gateway_resource.fetch_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.gateway.id
  resource_id             = aws_api_gateway_resource.roll_resource.id
  http_method             = aws_api_gateway_method.roll_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_post.invoke_arn
}

resource "aws_api_gateway_integration" "integration2" {
  rest_api_id             = aws_api_gateway_rest_api.gateway.id
  resource_id             = aws_api_gateway_resource.fetch_resource.id
  http_method             = aws_api_gateway_method.fetch_method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_get.invoke_arn
}



resource "aws_api_gateway_rest_api_policy" "gateway_policy" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id

policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "execute-api:Invoke",
        "Principal": {
          "AWS": "*"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

