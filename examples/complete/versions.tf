# terraform {
#   required_version = ">= 0.13.1"

#   backend "s3" {
#     bucket   = "thanos-storetest"
#     endpoint = "http://192.168.3.108:30920"
#     key      = "terraform-ecs-states"
#     profile  = "minio"

#     region                      = "main" # Region validation will be skipped
#     skip_credentials_validation = true   # Skip AWS related checks and validations
#     skip_metadata_api_check     = true
#     skip_region_validation      = true
#     force_path_style            = true
#   }

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 3.72"
#     }
#   }
# }
