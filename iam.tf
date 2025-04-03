resource "aws_iam_role" "ec2_s3_read_role" {
  name = "ec2_s3_read_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_policy" {
  name        = "s3_read_policy"
  description = "Policy to allow EC2 instances to read from bucket-code"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.python_code_bucket.arn}",
          "${aws_s3_bucket.python_code_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_read_attach" {
  role       = aws_iam_role.ec2_s3_read_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

resource "aws_iam_instance_profile" "ec2_s3_read_role" {
  name_prefix = "ec2_s3_read_role"
  role        = aws_iam_role.ec2_s3_read_role.name
}