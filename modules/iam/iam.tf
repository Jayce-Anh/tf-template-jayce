locals {
  gha_prefix = "gha"
  gha_inline_policy = var.enable_github_action && try(var.github_action_options.assume_roles, null) != null ? {
    assume = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sts:AssumeRole",
          ],
          Resource = var.github_action_options.assume_roles
        }
      ]
    })
  } : {}
  gha_trustrel = var.enable_github_action ? {
    gha = {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals = {
        federated = [var.github_action_options.oidc_arn]
      }
      conditions = [
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values   = [format("repo:%s:*", var.github_action_options.repo)]
        },
      ]
    }
  } : {}

  has_gha_prefix = trimprefix(var.name, local.gha_prefix) != var.name
  name           = var.enable_github_action && !local.has_gha_prefix ? format("%s-%s", local.gha_prefix, var.name) : var.name
  trustrels      = merge(var.trustrels, local.gha_trustrel)
  inline_policy  = merge(var.inline_policy, local.gha_inline_policy)

  default_tags = {
    Project   = var.project.name
    ManagedBy = "terraform"
  }
}

#-------------------------------------IAM Role-------------------------------------#
resource "aws_iam_role" "role" {
  name                 = local.name
  assume_role_policy   = data.aws_iam_policy_document.trustrel.json
  max_session_duration = var.session_duration

  tags = local.default_tags
}

#-------------------------------------IAM Policy Document-------------------------------------#
data "aws_iam_policy_document" "trustrel" {
  dynamic "statement" {
    for_each = local.trustrels

    content {
      effect  = "Allow"
      actions = lookup(statement.value, "actions", ["sts:AssumeRole"])

      dynamic "principals" {
        for_each = lookup(statement.value, "principals", [])

        content {
          type        = lower(principals.key) == "aws" ? upper(principals.key) : title(principals.key)
          identifiers = principals.value
        }
      }

      dynamic "condition" {
        for_each = lookup(statement.value, "conditions", [])

        content {
          test     = lookup(condition.value, "test", null)
          variable = lookup(condition.value, "variable", null)
          values   = lookup(condition.value, "values", null)
        }
      }
    }
  }
}

#Attach aws managed policy to the role
resource "aws_iam_role_policy_attachment" "policy" {
  count = length(var.policy_arn)

  policy_arn = element(var.policy_arn, count.index)
  role       = aws_iam_role.role.name
}

#Attach inline policy to the role
resource "aws_iam_role_policy" "this" {
  for_each = local.inline_policy

  role   = aws_iam_role.role.id
  name   = each.key
  policy = each.value
}

#-------------------------------------IAM Instance Profile-------------------------------------#
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = local.name
  role = aws_iam_role.role.name

  tags = local.default_tags
}