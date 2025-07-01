terraform {
  required_version = ">= 1.2.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.100.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.17.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    spotinst = {
      source  = "spotinst/spotinst"
      version = ">= 1.96.0"
    }
  }
}

provider "spotinst" {
  enabled = var.enabled_provider_spotinst ##Boolean value to enable or disable the provider.

  token   = var.token
  account = var.account_spotinst
}
