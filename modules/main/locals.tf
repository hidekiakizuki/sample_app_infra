locals {
  open_access = {
    ipv4 = {
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = null
    },
    ipv6 = {
      cidr_block      = null
      ipv6_cidr_block = "::/0"
    }
  }

  ipv6_translation_prefix = "64:ff9b::/96"
}

locals {
  container_names = {
    web_app       = "web-app"
    web_server    = "web-server"
    log_router    = "log-router"
    batch_default = "batch-default"
  }
}

data "external" "ecr_main_latest_tag" {
  program = [
    "aws", "ecr", "describe-images",
    "--repository-name", aws_ecr_repository.main.name,
    "--no-paginate",
    "--query", "{\"tag\": to_string(sort_by(imageDetails[?imageTags != `null`], &imagePushedAt)[-1].imageTags[0])}"
  ]

  depends_on = [aws_ecr_repository.main]
}

locals {
  ecr_main_latest_tag = data.external.ecr_main_latest_tag.result.tag != "null" ? data.external.ecr_main_latest_tag.result.tag : "dummy"
}

data "external" "ecr_web_server_latest_tag" {
  program = [
    "aws", "ecr", "describe-images",
    "--repository-name", aws_ecr_repository.web_server.name,
    "--no-paginate",
    "--query", "{\"tag\": to_string(sort_by(imageDetails[?imageTags != `null`], &imagePushedAt)[-1].imageTags[0])}"
  ]

  depends_on = [aws_ecr_repository.web_server]
}

locals {
  ecr_web_server_latest_tag = data.external.ecr_web_server_latest_tag.result.tag != "null" ? data.external.ecr_web_server_latest_tag.result.tag : "dummy"
}
