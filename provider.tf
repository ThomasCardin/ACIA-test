terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }

  # Terraform cloud
  cloud {
    organization = "ACIA"

    workspaces {
      name = "ACIA-devops-test"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}