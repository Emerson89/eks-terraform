resource "aws_eks_addon" "addons" {
  for_each = var.addons != {} ? var.addons : {}

  cluster_name             = aws_eks_cluster.eks_cluster.id
  addon_name               = each.value.name
  addon_version            = each.value.version
  service_account_role_arn = aws_iam_role.this[each.key].arn
  resolve_conflicts        = "OVERWRITE"
}

data "aws_iam_policy_document" "example_assume_role_policy" {
  for_each = var.addons != {} ? var.addons : {}

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:${each.value.data}"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = var.addons != {} ? var.addons : {}

  assume_role_policy = data.aws_iam_policy_document.example_assume_role_policy[each.key].json
  name               = each.key
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.addons != {} ? var.addons : {}

  policy_arn = each.value.policy_arn
  role       = aws_iam_role.this[each.key].name
}
