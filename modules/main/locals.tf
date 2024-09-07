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
    web_app    = "web-app"
    web_server = "web-server"
    log_router = "log-router"
  }
}
