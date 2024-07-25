terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.52.0"
      configuration_aliases = [aws, aws.virginia]
    }
  }

  required_version = ">=1.8.4"
}