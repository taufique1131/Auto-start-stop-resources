 
# AWS Provider
provider "aws" {
  region = "ap-south-1"  # 
}

#IAM Role for Lambda execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_ec2_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# IAM Policy for Lambda to interact with EC2
resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "Auto-Start-Stop-ec2-Policy"
  description = "Policy to start/stop EC2 instances and describe EC2 details"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "VisualEditor0"
        Effect    = "Allow"
        Action    = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:DescribeTags",
          "logs:*",
          "ec2:DescribeInstanceTypes",
          "ec2:StopInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource  = "*"
      },
    ]
  })
}

# Attach the IAM policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}
# Lambda function to start EC2 instances
resource "aws_lambda_function" "start_ec2_function" {
  function_name = "start_ec2_instances"
  runtime       = "python3.9"
  handler       = "start.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn
  filename      =  "./package/start_lambda.zip"

  source_code_hash = filebase64sha256("./package/start_lambda.zip")
  timeout       = 30 # increase timeout to 30 seconds

depends_on = [aws_iam_role_policy_attachment.lambda_policy_attachment]
}
# CloudWatch Event rule to trigger Lambda every hour
resource "aws_cloudwatch_event_rule" "start_event" {
  name        = "trigger_ec2_start_lambda"
  description = "Triggers Lambda at 8:00 AM IST (2:30 AM UTC) from Mon-Sat."
  schedule_expression = "cron(30 2 ? * MON-SAT *)"
}

resource "aws_cloudwatch_event_target" "start_lambda_target" {
  rule      = aws_cloudwatch_event_rule.start_event.name
  target_id = "start_lambda_target"
  arn       = aws_lambda_function.start_ec2_function.arn

input = jsonencode({
    "start-time" = "08"  # Pass your custom start-time value here
  })

}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_ec2_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_event.arn
}
