# ===============================================================================
# AWS Lambda Function for Amazon CloudWatch Logs error alert
# ===============================================================================
resource "aws_lambda_function" "lambda_log_error_alert" {
  function_name    = "lmd-cwt-log-error-alert"
  description      = "Lambda function for CloudWatch Logs error alert"
  role             = aws_iam_role.lambda_cloudwatch.arn
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.lambda_log_error_alert.output_path
  source_code_hash = data.archive_file.lambda_log_error_alert.output_base64sha256
  runtime          = "python3.14"
  timeout          = 10
  memory_size      = 128

  architectures = [
    "arm64",
  ]

  environment {
    variables = {
      hook_url = var.hook_url_app
    }
  }

  lifecycle {
    ignore_changes = [
      source_code_hash,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-lmd-cwt-log-error-alert"
  }
}

data "archive_file" "lambda_log_error_alert" {
  type        = "zip"
  source_dir  = "${path.cwd}/files/lambda/log-error-alert"
  output_path = "${path.module}/artifacts/lmd-cwt-log-error-alert.zip"
}

resource "aws_lambda_permission" "lambda_cloudwatch_app" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_log_error_alert.function_name
  principal     = "logs.${local.region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
}


# ===============================================================================
# AWS Lambda Function for Amazon CloudWatch Metric Alarm
# ===============================================================================
resource "aws_lambda_function" "lambda_metric_alarm" {
  function_name    = "lmd-cwt-metric-alarm"
  description      = "Lambda function for CloudWatch Metric Alarm"
  role             = aws_iam_role.lambda_cloudwatch.arn
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.lambda_metric_alarm.output_path
  source_code_hash = data.archive_file.lambda_metric_alarm.output_base64sha256
  runtime          = "python3.14"
  timeout          = 10
  memory_size      = 128

  architectures = [
    "arm64",
  ]

  environment {
    variables = {
      hook_url = var.hook_url_app
      region   = local.region
    }
  }

  lifecycle {
    ignore_changes = [
      source_code_hash,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-lmd-cwt-metric-alarm"
  }
}

data "archive_file" "lambda_metric_alarm" {
  type        = "zip"
  source_dir  = "${path.cwd}/files/lambda/metric-alarm"
  output_path = "${path.module}/artifacts/lmd-cwt-metric-alarm.zip"
}

resource "aws_lambda_permission" "lambda_metric_alarm" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_metric_alarm.function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:${local.region}:${data.aws_caller_identity.current.account_id}:alarm:*"
}
