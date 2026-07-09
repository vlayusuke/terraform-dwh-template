# ================================================================================
# Amazon S3 Bucket for Data Lake
# ================================================================================
resource "aws_s3_bucket" "data_lake" {
  bucket   = "${local.project}-${local.env}-s3-data-lake-bucket"
  provider = aws.osaka

  tags = {
    Name = "${local.project}-${local.env}-s3-data-lake-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.data_lake,
  ]
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.bucket

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

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.data_lake,
  ]
}

resource "aws_s3_bucket_policy" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  policy = data.aws_iam_policy_document.data_lake.json
}

data "aws_iam_policy_document" "data_lake" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.data_lake.arn,
      "${aws_s3_bucket.data_lake.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }
  }
}


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
