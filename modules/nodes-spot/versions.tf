terraform {
  required_version = ">= 1.2.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.9"
    }
    spotinst = {
      source  = "spotinst/spotinst"
      version = ">= 1.96.0"
    }
  }
} 