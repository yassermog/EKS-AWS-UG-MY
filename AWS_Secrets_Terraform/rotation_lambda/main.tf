terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

############ S3 

resource "random_pet" "lambda_bucket_name" {
  prefix = "terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  acl           = "private"
  force_destroy = true
}

########## Zip 

data "archive_file" "lambda_rotation_zip" {
  type = "zip"

  source_dir  = "${path.module}/functions"
  output_path = "${path.module}/functions.zip"
}

resource "aws_s3_bucket_object" "lambda_rotation_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "functions.zip"
  source = data.archive_file.lambda_rotation_zip.output_path

  etag = filemd5(data.archive_file.lambda_rotation_zip.output_path)
}

############# Lambda ##########

resource "aws_lambda_function" "lambda_rotation" {
  function_name = "lambda_rotation"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_bucket_object.lambda_rotation_bucket.key

  runtime = "python3.7"
  handler = "index.lambda_handler"

  source_code_hash = data.archive_file.lambda_rotation_zip.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
  vpc_config {
    subnet_ids         = [var.subnet_id]
    security_group_ids = [var.subnsecurity_group_id]
  }

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://${aws_vpc_endpoint.vpc_endpoint.dns_entry[0]["dns_name"]}"
      EXCLUDE_CHARACTERS = "/@\"'"
    }
  }

}

######### Cloudwatch ############
resource "aws_cloudwatch_log_group" "lambda_rotation_log" {
  name = "/aws/lambda/${aws_lambda_function.lambda_rotation.function_name}"

  retention_in_days = 30
}

########### IAM ###############
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  }
  
  
  )
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "lambda_policy_VPC" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


resource "aws_iam_policy" "jsonpolicy" {
  name = "tf-iam-role-policy-replication-12345"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DetachNetworkInterface"
            ],
            "Resource": "*",
            "Effect": "Allow"
    },
    {
      "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetSecretValue",
                "secretsmanager:PutSecretValue",
                "secretsmanager:UpdateSecretVersionStage"
            ],
            "Resource": "*",
            "Effect": "Allow"
    },
    {
      "Action": ["secretsmanager:GetRandomPassword"],
        "Resource": "*",
            "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "jsonpolicy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.jsonpolicy.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "SecretsManagerAccess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
}

#################### VPC endpoint ############
resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.ap-southeast-1.secretsmanager"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    var.subnsecurity_group_id
  ]
  subnet_ids          =  [var.subnet_id]
}

################## API Gateway #################33

resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "lambda_rotation_integration" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.lambda_rotation.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda_rotation_route" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_rotation_integration.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_rotation.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
