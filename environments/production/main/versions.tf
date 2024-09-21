terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.67.0"
      configuration_aliases = [aws, aws.virginia]
    }
  }

  required_version = ">=1.9.5"
}