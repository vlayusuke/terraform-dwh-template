# ================================================================================
# Amazon S3 Bucket for Source Code Backup (Osaka)
# ================================================================================
resource "aws_s3_bucket" "source_backup_osaka" {
  bucket   = "${local.project}-${local.env}-s3-github-backup-osaka-bucket"
  provider = aws.osaka

  tags = {
    Name = "${local.project}-${local.env}-s3-github-backup-osaka-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  provider = aws.osaka

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  acl      = "private"
  provider = aws.osaka

  depends_on = [
    aws_s3_bucket_ownership_controls.source_backup_osaka,
  ]
}

resource "aws_s3_bucket_public_access_block" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  provider = aws.osaka

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.bucket
  provider = aws.osaka

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  provider = aws.osaka

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  policy   = data.aws_iam_policy_document.source_backup_osaka.json
  provider = aws.osaka
}

data "aws_iam_policy_document" "source_backup_osaka" {
  provider = aws.osaka

  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.source_backup_osaka.arn,
      "${aws_s3_bucket.source_backup_osaka.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}
