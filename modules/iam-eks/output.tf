output "master-iam-name" {
  value = aws_iam_role.master.name
}

output "master-iam-arn" {
  value = aws_iam_role.master.arn
}

output "node-iam-name" {
  value = aws_iam_role.node.name
}

output "node-iam-arn" {
  value = aws_iam_role.node.arn
}

output "node-iam-name-profile" {
  value = aws_iam_instance_profile.iam-node-instance-profile-eks.name
}
