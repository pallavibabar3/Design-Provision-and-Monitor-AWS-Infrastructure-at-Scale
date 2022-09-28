provider "aws" {
  region                  = var.aws_region
  access_key = "AKIA4DP5HHM6TPJN4JGG"
  secret_key = "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"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
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
EOF

}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Attaches a Managed IAM Policy to an IAM role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/greet_lambda.py"
  output_path = "${path.module}/greet_lambda.zip"
}

resource "aws_lambda_function" "lambda_greeting" {
  description      = "Sample lambda function"
  filename         = "greet_lambda.zip"
  runtime          = "python3.8"
  role             = aws_iam_role.iam_for_lambda.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = var.lambda_function_name
  handler          = "${var.lambda_function_name}.lambda_handler"

  environment {
    variables = {
      greeting = "Hello World :) !!!!"
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 30
}