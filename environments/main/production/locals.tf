locals {
  default_region = "ap-northeast-1"
  env            = "production"
  zone_names     = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {
  state = "available"
}
