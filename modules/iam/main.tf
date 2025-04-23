data "aws_iam_policy_document" "this" {
  for_each = var.iam_roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = each.value.string
      variable = "${replace("${each.value.openid_url}", "https://", "")}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.serviceaccount}"]
    }

    condition {
      test     = each.value.string
      variable = "${replace("${each.value.openid_url}", "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [each.value.openid_connect]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = var.iam_roles

  assume_role_policy = data.aws_iam_policy_document.this[each.key].json
  name               = each.key

  lifecycle {
    ignore_changes = [assume_role_policy]
  }

  tags = merge(
    {
      "Name"     = each.key
      "Platform" = "IAM"
      "Type"     = "role"
    },
    var.tags,
  )
}

resource "aws_iam_role_policy" "this" {
  for_each = var.iam_roles

  name = each.key
  role = aws_iam_role.this[each.key].id

  policy = each.value.policy

}
