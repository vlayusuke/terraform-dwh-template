# ===============================================================================
# AWS IAM OIDC Provider for GitHub
# ===============================================================================
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint,
  ]

  client_id_list = [
    "sts.amazonaws.com",
  ]

  tags = {
    Name = "${local.project}-${local.env}-iam-oidc-provider-idp"
  }
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}


# ===============================================================================
# AWS IAM for GitHub Actions Deploy
# ===============================================================================
resource "aws_iam_role" "github_actions_deploy" {
  name               = "${local.project}-${local.env}-iam-github-actions-deploy-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.github_actions_deploy_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-github-actions-deploy-role"
  }
}

data "aws_iam_policy_document" "github_actions_deploy_assume" {
  statement {
    sid    = "OIDCFederate"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repository_name}/*",
      ]
    }
  }

  statement {
    sid    = "OIDCFederateRef"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repository_name}:ref:refs/heads/main",
        "repo:${local.repository_name}:ref:refs/heads/*",
      ]
    }
  }
}


# ===============================================================================
# AWS IAM for Source Code Backup
# ===============================================================================
resource "aws_iam_role" "github_actions_backup" {
  name               = "${local.project}-${local.env}-iam-github-actions-backup-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.github_actions_backup_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-github-actions-backup-role"
  }
}

data "aws_iam_policy_document" "github_actions_backup_assume" {
  statement {
    sid    = "OIDCFederate"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repository_name}/*",
      ]
    }
  }
}

resource "aws_iam_policy" "github_actions_backup" {
  name   = "${local.project}-${local.env}-iam-github-actions-backup-policy"
  policy = data.aws_iam_policy_document.github_actions_backup.json

  tags = {
    Name = "${local.project}-${local.env}-iam-github-actions-backup-policy"
  }
}

data "aws_iam_policy_document" "github_actions_backup" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${local.project}-*-*",
      "arn:aws:s3:::${local.project}-*-*/*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_backup" {
  role       = aws_iam_role.github_actions_backup.name
  policy_arn = aws_iam_policy.github_actions_backup.arn
}


# ===============================================================================
# AWS IAM for AWS Lambda (House keeping)
# ===============================================================================
resource "aws_iam_role" "lambda_cloudwatch" {
  name               = "${local.project}-${local.env}-iam-lmd-cwt-logs-error-alert-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_cloudwatch_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-lmd-cwt-logs-error-alert-role"
  }
}

data "aws_iam_policy_document" "lambda_cloudwatch_assume" {
  statement {
    sid    = "LambdaAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "lambda_cloudwatch" {
  name   = "${local.project}-${local.env}-iam-lmd-cwt-logs-error-alert-policy"
  policy = data.aws_iam_policy_document.lambda_cloudwatch.json

  tags = {
    Name = "${local.project}-${local.env}-iam-lmd-cwt-logs-error-alert-policy"
  }
}

data "aws_iam_policy_document" "lambda_cloudwatch" {
  statement {
    sid    = "LogAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.project}-${local.env}-*:*",
    ]
  }

  statement {
    sid    = "SNSPublish"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.event_alarm.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  role       = aws_iam_role.lambda_cloudwatch.name
  policy_arn = aws_iam_policy.lambda_cloudwatch.arn
}
