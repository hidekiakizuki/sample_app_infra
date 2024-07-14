variable "env" {
  type = string
}

variable "zone_names" {
  type = list(string)
}

variable "app_name" {
  type = string
}

variable "root_domain_name" {
  type = string
}

variable "app_domain_name" {
  type = string
}

variable "app_repository" {
  type = string
}

variable "rds" {
  type = object({
    engine_version        = string
    instance_class        = string
    storage_type          = string
    allocated_storage     = number
    max_allocated_storage = number
    multi_az              = bool
    db_parameter_group = object({
      family = string
    })
  })
}

variable "ecs" {
  type = object({
    service = object({
      platform_version = string
      desired_count    = number
    })
    task_definition = object({
      cpu    = string
      memory = string
    })
  })
}

variable "appautoscaling_target" {
  type = object({
    min_capacity = number
    max_capacity = number
  })
}

variable "delete_before_ecs_task_update" {
  type = bool
}
