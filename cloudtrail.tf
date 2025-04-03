# Get current AWS Account ID - needed for the bucket policy resource path
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket to store CloudTrail logs
resource "aws_s3_bucket" "trail_bucket" {
  bucket = "cloudtrail-logs-${random_string.bucket_suffix.result}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "trail_bucket_versioning" {
  bucket = aws_s3_bucket.trail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}




# --- CloudTrail Trail ---

resource "aws_cloudtrail" "main_trail" {
  depends_on                    = [aws_s3_bucket.trail_bucket]
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  include_global_service_events = false
}

# S3 Bucket Policy allowing CloudTrail to write
data "aws_iam_policy_document" "trail_bucket_policy_doc" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/example"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail_bucket.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/example"]
    }
  }
}



# Apply the bucket policy
resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.trail_bucket.id
  policy = data.aws_iam_policy_document.trail_bucket_policy_doc.json
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = "cloudtrail-logs-t932t7tv" // Replace with the actual bucket name if different

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::cloudtrail-logs-t932t7tv"
      },
      {
        Sid    = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::cloudtrail-logs-t932t7tv/AWSLogs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}