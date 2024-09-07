resource "aws_cloudwatch_metric_alarm" "web_alarm_high" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  alarm_name          = "TargetTracking-service/${aws_ecs_cluster.web.name}/${aws_ecs_service.web[0].name}-AlarmHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  unit                = "Percent"

  dimensions = {
    ClusterName = aws_ecs_cluster.web.name
    ServiceName = aws_ecs_service.web[0].name
  }

  alarm_description = "DO NOT EDIT OR DELETE. For TargetTrackingScaling policy ${aws_appautoscaling_policy.web[0].arn}."
  actions_enabled   = true
  alarm_actions     = [aws_appautoscaling_policy.web[0].arn, aws_sns_topic.warn.arn]
  ok_actions        = [aws_sns_topic.warn.arn]
}

resource "aws_cloudwatch_metric_alarm" "web_alarm_low" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  alarm_name          = "TargetTracking-service/${aws_ecs_cluster.web.name}/${aws_ecs_service.web[0].name}-AlarmLow"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 15
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 63
  unit                = "Percent"

  dimensions = {
    ClusterName = aws_ecs_cluster.web.name
    ServiceName = aws_ecs_service.web[0].name
  }

  alarm_description = "DO NOT EDIT OR DELETE. For TargetTrackingScaling policy ${aws_appautoscaling_policy.web[0].arn}."
  actions_enabled   = true
  alarm_actions     = [aws_appautoscaling_policy.web[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_web_task_count_zero" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  alarm_name          = "ECS/ContainerInsights RunningTaskCount ServiceName=${aws_ecs_service.web[0].name} ClusterName=${aws_ecs_cluster.web.name}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    ClusterName = aws_ecs_cluster.web.name
    ServiceName = aws_ecs_service.web[0].name
  }

  alarm_description   = "このアラームは、ECS サービスの実行タスク数が少なくなっていないかどうかを検出するのに役立ちます。実行中のタスク数が少なすぎる場合、アプリケーションがサービス負荷を処理できない可能性があり、パフォーマンスに関する問題が発生することがあります。実行中のタスクがない場合は、ECS サービスが利用できないか、またはデプロイに関する問題が発生している可能性があります。"
  datapoints_to_alarm = 5
  treat_missing_data  = "breaching"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.error.arn]
  ok_actions          = [aws_sns_topic.error.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_web_cpu_util" {
  alarm_name          = "ECS CPUUtilized/web"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 80

  metric_query {
    id          = "e1"
    label       = "web-cpu-utilized"
    expression  = "100*(m1/m2)"
    return_data = true
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "CpuUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = 300
      stat        = "Average"

      dimensions = {
        ClusterName          = aws_ecs_cluster.web.name
        TaskDefinitionFamily = aws_ecs_task_definition.web.family
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "CpuReserved"
      namespace   = "ECS/ContainerInsights"
      period      = 300
      stat        = "Average"

      dimensions = {
        ClusterName          = aws_ecs_cluster.web.name
        TaskDefinitionFamily = aws_ecs_task_definition.web.family
      }
    }
  }

  alarm_description   = "タスク定義 ${aws_ecs_task_definition.web.family} のCPU使用率が高くなっています。"
  datapoints_to_alarm = 1
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.warn.arn]
  ok_actions          = [aws_sns_topic.warn.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_web_memory_util" {
  alarm_name          = "ECS MemoryUtilized/web"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 80

  metric_query {
    id          = "e1"
    label       = "web-memory-utilized"
    expression  = "100*(m1/m2)"
    return_data = true
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "MemoryUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = 300
      stat        = "Average"

      dimensions = {
        ClusterName          = aws_ecs_cluster.web.name
        TaskDefinitionFamily = aws_ecs_task_definition.web.family
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "MemoryReserved"
      namespace   = "ECS/ContainerInsights"
      period      = 300
      stat        = "Average"

      dimensions = {
        ClusterName          = aws_ecs_cluster.web.name
        TaskDefinitionFamily = aws_ecs_task_definition.web.family
      }
    }
  }

  alarm_description   = "タスク定義 ${aws_ecs_task_definition.web.family} のメモリ使用率が高くなっています。"
  datapoints_to_alarm = 1
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.warn.arn]
  ok_actions          = [aws_sns_topic.warn.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_web_storage_util" {
  alarm_name          = "ECS Ephemeral Storage Utilized | web"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 80

  metric_query {
    id          = "e1"
    label       = "web-ephemeral-storage-utilized"
    expression  = "100*(m1/m2)"
    return_data = true
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "EphemeralStorageUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = 300
      stat        = "Average"

      dimensions = {
        ClusterName          = aws_ecs_cluster.web.name
        TaskDefinitionFamily = aws_ecs_task_definition.web.family
      }
    }
  }
  metric_query {
    id = "m2"

    metric {
      metric_name = "EphemeralStorageReserved"
      namespace   = "ECS/ContainerInsights"
      period      = 300
      stat        = "Average"

      dimensions = {
        ClusterName          = aws_ecs_cluster.web.name
        TaskDefinitionFamily = aws_ecs_task_definition.web.family
      }
    }
  }

  alarm_description   = "タスク定義 ${aws_ecs_task_definition.web.family} のエフェメラルストレージ使用率が高くなっています。"
  datapoints_to_alarm = 1
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.warn.arn]
  ok_actions          = [aws_sns_topic.warn.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_util" {
  alarm_name          = "AWS/RDS CPUUtilization DBInstanceIdentifier=${aws_db_instance.rds.identifier}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 90

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds.identifier
  }

  alarm_description   = "このアラームは、CPU 使用率が一貫して高くなっていないかどうかをモニタリングするのに役立ちます。CPU 使用率は非アイドル時間を測定します。MariaDB、MySQL、Oracle、PostgreSQL について、[拡張モニタリング](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.Enabling.html) または [Performance Insights](https://aws.amazon.com/rds/performance-insights/) を使用して、どの [待機時間](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring-Available-OS-Metrics.html) が CPU 時間のほとんどを消費しているかを確認することを検討してください (`guest`、`irq`、`wait`、`nice` など)。その後、どのクエリが最も多くの CPU を消費するかを評価してください。ワークロードを調整できない場合は、より大きな DB インスタンスクラスに移行することを検討してください。"
  datapoints_to_alarm = 5
  treat_missing_data  = "breaching"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.warn.arn]
  ok_actions          = [aws_sns_topic.warn.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_db_load" {
  alarm_name          = "AWS/RDS DBLoad DBInstanceIdentifier=${aws_db_instance.rds.identifier}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 15
  metric_name         = "DBLoad"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 1 # TODO: vCPU数

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds.identifier
  }

  alarm_description   = "このアラームは、DB の負荷が高くなっていないかどうかをモニタリングするのに役立ちます。プロセスの数が vCPU の数を超えると、プロセスはキューイングを開始します。キューが増加すると、パフォーマンスに影響が生じます。DB 負荷が頻繁に最大 vCPU を超え、主な待機状態が CPU である場合、CPU は過負荷状態です。この場合、`CPUUtilization`、`DBLoadCPU`、およびキューに入れられたタスクを Performance Insights/拡張モニタリングでモニタリングできます。インスタンスへの接続のスロットリング、CPU 負荷の高い SQL クエリの調整、より大きなインスタンスクラスの検討が必要な場合があります。待機状態が頻繁に、かつ、一貫して発生する場合、解決すべきボトルネックまたはリソース競合に関する問題がある可能性があります。"
  datapoints_to_alarm = 15
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.warn.arn]
  ok_actions          = [aws_sns_topic.warn.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_free_memory" {
  alarm_name          = "AWS/RDS FreeableMemory DBInstanceIdentifier=${aws_db_instance.rds.identifier}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 15
  threshold           = 134217728 # TODO: aurora: 5% rds:総メモリの25%
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds.identifier
  }

  metric_name = "FreeableMemory"
  namespace   = "AWS/RDS"
  period      = 60
  statistic   = "Average"

  alarm_description   = "このアラームは解放可能なメモリが少なくなっていないかどうかをモニタリングするのに役立ちます。解放可能なメモリが少なくなっている場合、データベース接続が急増していたり、インスタンスで高いメモリ負荷が発生していたりする可能性があります。`FreeableMemory` に加えて `SwapUsage` の CloudWatch メトリクスをモニタリングして、メモリ負荷を確認してください。インスタンスが頻繁に多すぎるメモリを消費している場合は、ワークロードを確認したり、インスタンスクラスをアップグレードしたりする必要があります。Aurora リーダー DB インスタンスの場合は、クラスターにリーダー DB インスタンスをさらに追加することを検討してください。"
  datapoints_to_alarm = 15
  treat_missing_data  = "breaching"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.error.arn]
  ok_actions          = [aws_sns_topic.error.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "AWS/RDS FreeStorageSpace DBInstanceIdentifier=${aws_db_instance.rds.identifier}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  threshold           = 2147483648 # TODO: ディスク容量の10%
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds.identifier
  }

  metric_name = "FreeStorageSpace"
  namespace   = "AWS/RDS"
  period      = 60
  statistic   = "Minimum"

  alarm_description   = "このアラームは、使用可能なストレージ容量が少なくなっていないかどうかを監視します。ストレージキャパシティの制限に近づく頻度が高い場合は、データベースストレージのスケールアップを検討してください。アプリケーションからの予期せぬ需要の増加に対応するために、ある程度のバッファを含めてください。あるいは、RDS ストレージの自動スケーリングを有効にすることを検討してください。さらに、未使用または古くなったデータやログを削除して、より多くの容量を解放することを検討してください。詳細については、[RDS のストレージ不足に関するドキュメント](https://repost.aws/knowledge-center/rds-out-of-storage) および [PostgreSQL ストレージの問題に関するドキュメント](https://repost.aws/knowledge-center/diskfull-error-rds-postgresql) を確認してください。"
  datapoints_to_alarm = 5
  treat_missing_data  = "breaching"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.error.arn]
  ok_actions          = [aws_sns_topic.error.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "AWS/RDS DatabaseConnections DBInstanceIdentifier=${aws_db_instance.rds.identifier}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 72 # TODO: 最大コネクション数の90%

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds.identifier
  }

  metric_name = "DatabaseConnections"
  namespace   = "AWS/RDS"
  period      = 60
  statistic   = "Average"

  actions_enabled     = true
  datapoints_to_alarm = 5
  treat_missing_data  = "breaching"
  alarm_description   = "このアラームは、接続が多いことを検出します。既存の接続を確認し、`sleep` 状態の接続や、不適切に閉じられた接続を終了してください。新しい接続の数を制限するために、接続プーリングの使用を検討してください。あるいは、より多くのメモリを持ち、したがって `max_connections` についてより大きいデフォルト値を持つクラスを使用するために、DB インスタンスのサイズを大きくするか、または、ワークロードをサポートできる場合は、現在のクラスについて [RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html) と Aurora [MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Performance.html) および [PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Managing.html) の `max_connections` の値を大きくします。"
  alarm_actions       = [aws_sns_topic.warn.arn]
  ok_actions          = [aws_sns_topic.warn.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "AWS/RDS ReadLatency DBInstanceIdentifier=${aws_db_instance.rds.identifier}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 20
  extended_statistic  = "p90"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds.identifier
  }

  metric_name = "ReadLatency"
  namespace   = "AWS/RDS"
  period      = 60

  alarm_description   = "このアラームは、読み取りレイテンシーが増大していないかどうかをモニタリングするのに役立ちます。ストレージのレイテンシーが大きい場合、その原因は、ワークロードがリソースの制限を超えていることにあります。インスタンスおよび割り当てられたストレージ設定に関係する I/O 使用率を確認できます。[IOPS ボトルネックによって引き起こされる Amazon EBS ボリュームのレイテンシーのトラブルシューティング](https://repost.aws/knowledge-center/rds-latency-ebs-iops-bottleneck) を参照してください。Aurora の場合、[I/O 最適化ストレージ設定](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.storage-type.html) を持つインスタンスクラスに切り替えることができます。"
  actions_enabled     = true
  datapoints_to_alarm = 5
  alarm_actions       = [aws_sns_topic.error.arn]
  ok_actions          = [aws_sns_topic.error.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "AWS/RDS WriteLatency DBInstanceIdentifier=${aws_db_instance.rds.identifier}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 20
  extended_statistic  = "p90"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds.identifier
  }

  metric_name = "WriteLatency"
  namespace   = "AWS/RDS"
  period      = 60

  alarm_description   = "このアラームは、書き込みレイテンシーが増大していないかどうかをモニタリングするのに役立ちます。ストレージのレイテンシーが大きい場合、その原因は、ワークロードがリソースの制限を超えていることにあります。インスタンスおよび割り当てられたストレージ設定に関係する I/O 使用率を確認できます。[IOPS ボトルネックによって引き起こされる Amazon EBS ボリュームのレイテンシーのトラブルシューティング](https://repost.aws/knowledge-center/rds-latency-ebs-iops-bottleneck) を参照してください。Aurora の場合、[I/O 最適化ストレージ設定](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.storage-type.html) を持つインスタンスクラスに切り替えることができます。"
  actions_enabled     = true
  datapoints_to_alarm = 5
  alarm_actions       = [aws_sns_topic.error.arn]
  ok_actions          = [aws_sns_topic.error.arn]
}
