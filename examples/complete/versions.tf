terraform {
  required_version = ">= 1.2.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1"
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
