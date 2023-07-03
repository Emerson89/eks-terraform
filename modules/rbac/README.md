## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role_binding_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding_v1) | resource |
| [kubernetes_cluster_role_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_service_account.service-account](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Standard kubernetes metadata | `any` | n/a | yes |
| <a name="input_rules"></a> [rules](#input\_rules) | The Role to bind Subjects to | `any` | n/a | yes |
| <a name="input_service-account-create"></a> [service-account-create](#input\_service-account-create) | Create service account | `bool` | `false` | no |
| <a name="input_subjects"></a> [subjects](#input\_subjects) | The Users, Groups, or ServiceAccounts to grand permissions to | `any` | n/a | yes |

## Outputs

No outputs.
