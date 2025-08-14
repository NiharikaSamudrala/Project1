terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

########################################
# IAM Role for Glue Job
########################################
data "aws_iam_policy_document" "glue_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue_role" {
  name               = "glue-job-role-mydemo"
  assume_role_policy = data.aws_iam_policy_document.glue_trust.json
}

data "aws_iam_policy_document" "glue_permissions" {
  statement {
    sid     = "S3Access"
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }

  statement {
    sid     = "CloudWatchLogs"
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "glue_custom_policy" {
  name   = "glue-job-policy-mydemo"
  policy = data.aws_iam_policy_document.glue_permissions.json
}

resource "aws_iam_role_policy_attachment" "glue_service_role_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_custom_policy_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_custom_policy.arn
}

########################################
# Glue Job
########################################
resource "aws_glue_job" "my_glue_job" {
  name     = "my-glue-job-mydemo"
  role_arn = aws_iam_role.glue_role.arn

  glue_version = "4.0"

  command {
    name            = "glueetl"
    script_location = var.script_s3_path
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--TempDir"                          = "s3://${var.bucket_name}/tmp/"
    "--job-bookmark-option"              = "job-bookmark-disable"
  }

  number_of_workers = 2
  worker_type       = "G.1X"
  max_retries       = 0
  timeout           = 30
  description       = "Glue job to process CSV files from S3"
}
