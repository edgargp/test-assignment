terraform {
  backend "s3" {
    bucket = "test-assignment-terraform"
    key    = "terraform/state/terraform.tfstate"
    region = "eu-west-3"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.93.0"
    }
  }
}