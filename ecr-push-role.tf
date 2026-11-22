# ---------------------------------------------------------------------------
# IAM role that the image-building GitHub Actions pipeline assumes (OIDC, no access keys) to push
# images to the ECR repositories in ecr.tf. Push-only: it cannot touch anything else in the project.
#
# Separate from the bootstrap "github-actions-terraform" role (AdministratorAccess, trusts only this
# Terraform repo). The trusted repo is var.ecr_push_github_repo.
# After apply, use the ecr_push_role_arn output as AWS_ROLE_ARN in that repo's docker-ecr workflow.
# ---------------------------------------------------------------------------

# Created once per account by the bootstrap stack (an account can have only one per URL).
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "ecr_push_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # main pushes release tags; pull requests push snapshot-* tags.
    # AWS cannot tell which branch a pull request comes from, so anyone who can open a PR in the repo
    # can push to the repositories below (tags are IMMUTABLE, so existing images are never overwritten).
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = concat(
        ["repo:${var.ecr_push_github_repo}:ref:refs/heads/main"],
        var.ecr_push_allow_pull_requests ? ["repo:${var.ecr_push_github_repo}:pull_request"] : [],
      )
    }
  }
}

resource "aws_iam_role" "ecr_push" {
  name               = "${var.cluster_name}-ecr-push"
  description        = "GitHub Actions (${var.ecr_push_github_repo}) pushes images to ${var.cluster_name}/* ECR repositories"
  assume_role_policy = data.aws_iam_policy_document.ecr_push_trust.json
}

data "aws_iam_policy_document" "ecr_push" {
  # Needed to docker login; this action does not support resource-level permissions.
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Matches every repository named <cluster_name>/<service>, including ones added to
  # ecr_repository_names later, so a missing repository gives a clear "does not exist" error.
  statement {
    sid = "PushImages"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
    ]
    resources = ["arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.cluster_name}/*"]
  }
}

resource "aws_iam_role_policy" "ecr_push" {
  name   = "ecr-push"
  role   = aws_iam_role.ecr_push.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
