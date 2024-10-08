module "production" {
  source = "../../../modules/main"

  env        = local.env
  zone_names = local.zone_names

  app_name                      = var.app_name
  root_domain_name              = var.root_domain_name
  app_domain_name               = var.app_domain_name
  app_repository                = var.app_repository
  sns_subscription_email        = var.sns_subscription_email
  rds                           = var.rds
  ecs                           = var.ecs
  appautoscaling_target         = var.appautoscaling_target
  allowed_ips_in_maintenance    = var.allowed_ips_in_maintenance
  delete_before_ecs_task_update = var.delete_before_ecs_task_update
  service_suspend_mode          = var.service_suspend_mode

  providers = {
    aws          = aws
    aws.virginia = aws.virginia
  }
}
