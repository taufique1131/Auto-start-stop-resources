# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-execution-role-rds"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Custom IAM Policy for RDS Start/Stop
resource "aws_iam_policy" "lambda_rds_start_stop" {
  name        = "lambda-rds-start-stop"
  description = "Policy to allow Lambda to start/stop RDS instances and clusters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Statement1",
        Effect = "Allow",
        Action = [
          "rds:DescribeDBClusterParameters",
          "rds:StartDBCluster",
          "rds:StopDBCluster",
          "rds:StopDBInstance",
          "rds:StartDBInstance",
          "rds:ListTagsForResource",
          "rds:DescribeDBInstances",
          "rds:DescribeSourceRegions",
          "rds:DescribeDBClusterEndpoints",
          "rds:DescribeDBClusters"
        ],
        Resource = "*"
      }
    ]
  })
}

# 3. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_rds_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_rds_start_stop.arn
}

resource "aws_lambda_function" "start_rds_function" {
  function_name = "start_rds_instances"
  runtime       = "python3.11"
  handler       = "start.lambda_handler"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      =  "./package/start_lambda.zip"

  source_code_hash = filebase64sha256("./package/start_lambda.zip")
  timeout       = 30 # increase timeout to 30 seconds

  depends_on = [aws_iam_role_policy_attachment.lambda_rds_policy_attach]

  environment {
    variables = {
      AutoStart = "True"
    }
  }

}

resource "aws_cloudwatch_event_rule" "start_event" {
  name        = "trigger_rds_start_lambda"
  description = "Triggers Lambda at 8:00 AM IST (2:30 AM UTC) from Mon-Sat."
  schedule_expression = "cron(30 2 ? * MON-SAT *)"
}

resource "aws_cloudwatch_event_target" "start_lambda_target" {
  rule      = aws_cloudwatch_event_rule.start_event.name
  target_id = "start_lambda_target"
  arn       = aws_lambda_function.start_rds_function.arn

input = jsonencode({
    "AutoStart" = "True"  
  })

}

# Allow CloudWatch to invoke Lambda
resource "aws_lambda_permission" "allow_start_events" {
  statement_id  = "AllowExecutionFromCloudWatchStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_rds_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_event.arn
}
