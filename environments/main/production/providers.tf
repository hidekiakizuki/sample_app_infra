provider "aws" {
  region = local.default_region

  default_tags {
    tags = {
      service   = var.app_name
      env       = local.env
      terraform = true
    }
  }
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      service   = var.app_name
      env       = local.env
      terraform = true
    }
  }
}