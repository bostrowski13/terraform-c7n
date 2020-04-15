locals {
  bucket_name = lower("${var.resource_prefix}-policy-results")
}

# Data sources
data "aws_caller_identity" "current" {}

# KMS Key for encryption data at Rest in SQS and S3
resource "aws_kms_key" "c7n" {
  description             = "Key to encrypt data at rest for resources holding inforamtion for Cloud Custodian"
  deletion_window_in_days = 10
  tags                    = var.tags
}

# IAM Role and Policies
## AssumeRole
data "aws_iam_policy_document" "c7n_lambda_execution" {
  version = "2012-10-17"
  statement {
    sid     = "AllowApiGatewayToAssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Role for the Lmabda to run as
resource "aws_iam_role" "c7n_role" {
  name                 = "${var.resource_prefix}-c7n-role"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/CloudCoreL3Permissions"
  assume_role_policy   = data.aws_iam_policy_document.c7n_lambda_execution.json
  tags                 = var.tags
}

# Policy attachment to role
resource "aws_iam_role_policy" "c7n_policy" {
  role   = aws_iam_role.c7n_role.id
  policy = data.aws_iam_policy_document.c7n_policy.json
}

# Policy that maps permissions for c7n to execute
data "aws_iam_policy_document" "c7n_policy" {
  statement {
    sid    = "CanListIAMInfo"
    effect = "Allow"
    actions = [
      "iam:ListAccountAliases",
      "iam:ListAttachedRolePolicies",
      "iam:GetRole",
      "iam:GetGroup",
      "iam:GetUser",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:PassRole"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CanManageLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
      "logs:DeleteLogStream",
      "logs:DeleteLogGroup"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CanGetAndSendToSQSQeueue"
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [
      aws_sqs_queue.queue.arn
    ]
  }

  statement {
    sid    = "CanGetAndPubCWMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:PutMetricData",
      "cloudtrail:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CanManageLambdaFunctions"
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:CreateNetworkInterface",
      "events:PutRule",
      "events:PutTargets",
      "events:DescribeRule",
      "events:EnableRule",
      "events:ListTargetsByRule",
      "lambda:GetFunction",
      "lambda:CreateFunction",
      "lambda:TagResource",
      "lambda:CreateEventSourceMapping",
      "lambda:UntagResource",
      "lambda:PutFunctionConcurrency",
      "lambda:DeleteFunction",
      "lambda:UpdateEventSourceMapping",
      "lambda:InvokeFunction",
      "lambda:UpdateFunctionConfiguration",
      "lambda:UpdateAlias",
      "lambda:UpdateFunctionCode",
      "lambda:AddPermission",
      "lambda:DeleteAlias",
      "lambda:DeleteFunctionConcurrency",
      "lambda:DeleteEventSourceMapping",
      "lambda:RemovePermission",
      "lambda:CreateAlias",
      "lambda:ListTags",
      "lambda:GetAlias"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CanStopAndStartEC2Instances"
    effect = "Allow"
    actions = [
      "ec2:StopInstances",
      "ec2:StartInstances"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CanGetS3Info"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CanWriteResultsToC7NBucket"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.bucket.arn
    ]
  }

  statement {
    sid    = "CanReadAndWriteDBInfo"
    effect = "Allow"
    actions = [
      "rds:Describe*",
      "rds:ListTagsForResource",
      #rds:Delete xxxxxxxxxx,
      #rds:Remove xxxxxxxxxx,
      #rds:Start xxxxxxxxxx,
      #rds:Stop xxxxxxxxxx,
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CanManageTags"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DescribeTags",
      "tag:getResources",
      "tag:getTagKeys",
      "tag:getTagValues",
      "tag:addResourceTags"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CanUseKMS"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.c7n.arn
    ]
  }
}

# SQS for Alert Delivery to Slack
locals {
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

# The desired queue and its config, including standard redrive policy from DLQ (below)
resource "aws_sqs_queue" "queue" {
  name                      = "${var.resource_prefix}-notify-queue"
  message_retention_seconds = var.message_retention_seconds
  redrive_policy            = local.redrive_policy
  kms_master_key_id         = aws_kms_key.c7n.arn
  tags                      = var.tags
}

# The DLQ for the Queue above
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.resource_prefix}-notify-dlq"
  message_retention_seconds = var.message_retention_seconds
  kms_master_key_id         = aws_kms_key.c7n.arn
  tags                      = var.tags
}

# S3 Bucket
# The private bucket with prescribed config
resource "aws_s3_bucket" "bucket" {
  bucket        = local.bucket_name
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.c7n.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    prefix  = "${var.c7n_reports_root_folder}/"
    enabled = true

    noncurrent_version_transition {
      days          = var.noncurrent_version_transition_days_slow_storage
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = var.noncurrent_version_transition_days_archive_storage
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload_days = 2
  }

  lifecycle {
    # stuck with hardcoding this until https://github.com/hashicorp/terraform/issues/3116 is fixed
    prevent_destroy = false
  }

  tags = var.tags
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  depends_on = [aws_s3_bucket_public_access_block.bucket]
  bucket     = aws_s3_bucket.bucket.id
  policy     = data.aws_iam_policy_document.c7n_bucket_policy.json
}

data "aws_iam_policy_document" "c7n_bucket_policy" {
  statement {
    sid    = "LambdaCanWriteResultsToS3"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.c7n_role.arn
      ]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.bucket.arn}",
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}

# Block public access on the bucket and objects
resource "aws_s3_bucket_public_access_block" "bucket" {
  depends_on              = [aws_s3_bucket.bucket]
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Precreation of the cloudwatch logs group for policy execution logs
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = var.c7n_cw_log_group
  retention_in_days = var.logging_retention_days
  tags              = var.tags
}
