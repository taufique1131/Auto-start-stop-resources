resource "aws_lambda_function" "stop_rds_function" {
  function_name = "stop_rds_instances"
  runtime       = "python3.11"
  handler       = "stop.lambda_handler"
  role          = aws_iam_role.lambda_exec_role.arn  # Using the same IAM role as start lambda
  filename      = "./package/stop_lambda.zip"
  source_code_hash = filebase64sha256("./package/stop_lambda.zip")
  timeout       = 30 # increase timeout to 30 seconds

  depends_on = [aws_iam_role_policy_attachment.lambda_rds_policy_attach]

  environment {
    variables = {
      AutoStop = "True"
    }
  }
}

resource "aws_cloudwatch_event_rule" "stop_event" {
  name                = "trigger_rds_stop_lambda"
  description         = "Triggers Lambda at 10:00 PM IST (4:30 PM UTC) from Mon-Sat."
  schedule_expression = "cron(30 16 ? * MON-SAT *)"
}

# CloudWatch Event Target to invoke the Stop Lambda
resource "aws_cloudwatch_event_target" "stop_lambda_target" {
  rule      = aws_cloudwatch_event_rule.stop_event.name  # Reference to stop_event
  target_id = "stop_lambda_target"
  arn       = aws_lambda_function.stop_rds_function.arn

input = jsonencode({
    "AutoStop" = "True"
  })

}

# Lambda permission to allow CloudWatch Event to invoke the Stop Lambda
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_stop" {
  statement_id  = "AllowExecutionFromCloudWatchForStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_rds_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_event.arn  # Reference to stop_event
}
