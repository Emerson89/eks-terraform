## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks-master"></a> [eks-master](#module\_eks-master) | github.com/Emerson89/modules-terraform.git//eks//master | main |
| <a name="module_eks-node-infra"></a> [eks-node-infra](#module\_eks-node-infra) | github.com/Emerson89/modules-terraform.git//eks//nodes | main |
| <a name="module_iam-eks"></a> [iam-eks](#module\_iam-eks) | github.com/Emerson89/modules-terraform.git//eks//iam-eks | main |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_endpoint_private_access"></a> [endpoint\_private\_access](#input\_endpoint\_private\_access) | Endpoint access private | `bool` | `true` | no |
| <a name="input_endpoint_public_access"></a> [endpoint\_public\_access](#input\_endpoint\_public\_access) | Endpoint access public | `bool` | `true` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Version cluster | `string` | `"1.23"` | no |

## Outputs

No outputs.
