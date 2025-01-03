# 概要
RailsアプリケーションをECS上でBlue/Greenデプロイできるように構成されています。  
一部、terraform対象外のリソースも含まれます。  
(SSMパラメータストア、Route53やChatbotなどです。)

# terraform実行
terraformコマンドの実行は各環境ごとのディレクトリで実行してください。
```
cd environments/main/xxx
terraform init -backend-config=backend_config.tfvars
```

# 構築方法
次の順番でリソースを作成や設定を行います。  
リソースファイルは末尾に`.bck`等をつけてリソース作成の対象外としておき、一つずつリソースを作成していってください。

### 1. 設定ファイルの作成
各環境ごとにサンプルファイルを元にファイルを作成してください。
- `environments/main/xxx/backend_config.tfvars.example`
- `environments/main/xxx/terraform.tfvars.example`

### 2. tfstate用にS3バケット、DynamoDBテーブル作成
上記で設定したbackend_config.tfvarsに従い、該当するS3バケットとDynamoDBテーブルをAWSマネジメントコンソールから手動で作成します。

#### 2-1. S3
- バケットタイプ
  - 汎用
- バケット名
  - terraform-state-xxxxxxxxxxxx
- オブジェクト所有者
  - ACL無効
- このバケットのブロックパブリックアクセス設定
  - パブリックアクセスをすべてブロック
- バケットのバージョニング
  - 有効にする
- デフォルトの暗号化
  - Amazon S3マネージドキーを使用したサーバー側の暗号化
- バケットキー
  - 有効にする	

#### 2-2. DynamoDB
- テーブル名
  - terraform-state-lock
- パーティションキー
  - `LockID` 文字列
- テーブル設定
  - テーブルクラス
    - DynamoDB標準
  - キャパシティーモード
    - プロビジョンド
  - 読み込みキャパシティー
    - AutoScaling
      - オフ
    - プロビジョンドキャパシティユニット
      - 1
  - 書き込みキャパシティー
    - AutoScaling
      - オフ
    - プロビジョンドキャパシティユニット
      - 1
  - セカンダリインデックス
    - なし
  - 保管時の暗号化
    - Amazon DynamoDBが所有
  - 削除保護
    - 削除保護をオンにする
  - リソースベースのポリシー
    - なし

### 3. terraform初期化
```
cd environments/main/xxx
terraform init -backend-config=backend_config.tfvars
```

### 4. インポート
手動で作成したS3バケットとDynamoDBテーブルをインポートします。
```
terraform import module.production.aws_s3_bucket.terraform_state terraform-state-xxxxxxxxxxxx

terraform import module.production.aws_s3_bucket_versioning.terraform_state terraform-state-xxxxxxxxxxxx

terraform import module.production.aws_dynamodb_table.terraform_state_lock terraform-state-lock
```

### 5. S3作成

### 6. DynamoDB作成

### 7. VPC、SecurityGroup、VPC Endpoint作成

### 8. SQS作成

### 9. IAM、Firehose、CloudWatch Logs作成

### 10. KMS作成

### 11. SSMパラメータストアでパラメータ登録
以下をAWSマネジメントコンソールから手動で登録します。
- `/app/rails/secret_key_base`
- `/rds/postgres/host` （※ 値はdummyで登録します。リソース作成後に正しいホストをセットします）
- `/rds/postgres/user`
- `/rds/postgres/password`
- `/rds/postgres/database`
- `/sqs/queue/default` （※ エンドポイントをセットします）
- `/elasticache/default/host` （※ 値はdummyで登録します。リソース作成後に正しいホストをセットします）
- `/elasticache/default-dummy/password`
- `/elasticache/default-admin/user`
- `/elasticache/default-admin/password`
- `/elasticache/default-custom/user`
- `/elasticache/default-custom/password`

### 12. ACMでSSL証明書を作成
AWSマネジメントコンソールから手動で作成します。  
アプリケーションを配置するメインのregionとus-east-1リージョンでそれぞれ作成してください。  
ALBとCloudFrontそれぞれで利用します。

ドメインは別のAWSアカウントで管理する想定なので注意してください。

### 13. RDS、 ElastiCache作成
インスタンス作成後、SSMパラメータストアの `/rds/postgres/host` と `/elasticache/default/host` に値をセットします。

### 14. ECR作成

### 15. ALB作成

### 16. ECS作成
設定は正しいのに下記エラーが出る場合があります。
> reading ECS Task Definition (web): ClientException: Unable to describe task definition.

その場合は、一旦stateを削除すると問題が解説することがあります。
> terraform state rm module.production.aws_ecs_task_definition.web

### 17. Batch作成
リソース作成後、AWSマネジメントコンソールからアクセス許可設定のジョブログとContainer Insightsを有効化してください。

### 18. CodeDeploy作成

### 19. CloudWatch Alarm作成

### 20. SNS作成
メールが届いたら「Confirm subscription」のリンクをクリックせずに、そのリンク先のURLに含まれているTokenを抜き出し、
AWS CLI経由で認証します。  
これにより unsubscribe リンクを誤ってクリックしてしまうことを防止できます。

```:AWS CLIコマンド
aws sns confirm-subscription \
--topic-arn arn:aws:sns:ap-northeast-1:123456789012:info \
--token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
--authenticate-on-unsubscribe true \
--region ap-northeast-1
```

もし誤ってメールの「Confirm subscription」をクリックしてしまったら、該当サブスクリプションを削除して作り直し、上記を実行してください。（一度メールからクリックするとやり直しはできません。）

### 21. Chatbot作成
AWSマネジメントコンソールから手動でinfo, warn, error, batchを作成します。
予めSlackで通知先チャンネルを作成しておき、SNS topicを設定してください。

### 22. EventBridge、 EventBridge Scheduler作成

### 23. WAF作成

### 24. CloudFront作成
ドメインを管理しているAWSアカウントのRoute53でAレコード作成し、エイリアスにこのディストリビューションを指定します。

### 25. GitHubのIDプロバイダを追加
IAMにてIDプロバイダを追加します。
- プロバイダのタイプ: `OpenID Connect`
- プロバイダのURL: `https://token.actions.githubusercontent.com`
- 対象者: `sts.amazonaws.com`

# TODO
- 外部公開API対応

# 備考
- ECSからのログの流れ
```
ECS - Web
 ├─> CloudWatch Logs (/ecs/container/firelens: web) # Fluent Bitのログを出力
 └─> FireLens (Fluent Bit)
      ├─> Firehose (ecs-container-logs-web-server)
      │    ├─> S3 (ecs-container-logs-web-server-#{accountid}: logs/year=yyyy/... | errors/year=yyyy...) # コンテナのすべてのログを出力
      │    └─> CloudWatch Logs (/firehose/errors: ecs-web-server-firelens-firehose-s3) # Firehoseエラー
      ├─> Firehose (ecs-container-logs-web-app)
      │    ├─> S3 (ecs-container-logs-web-app-#{accountid}: logs/year=yyyy/... | errors/year=yyyy...) # コンテナのすべてのログを出力
      │    └─> CloudWatch Logs (/firehose/errors: ecs-web-app-firelens-firehose-s3) # Firehoseエラー
      └─> CloudWatch Logs (/ecs/container/error-logs: web) # webコンテナのエラーログのみを出力
```
```
ECS - Worker
 ├─> CloudWatch Logs (/ecs/container/firelens: worker) # Fluent Bitのログを出力
 └─> FireLens (Fluent Bit)
      ├─> Firehose (ecs-container-logs-worker)
      │    ├─> S3 (ecs-container-logs-worker-#{accountid}: logs/year=yyyy/... | errors/year=yyyy...) # コンテナのすべてのログを出力
      │    └─> CloudWatch Logs (/firehose/errors: ecs-worker-firelens-firehose-s3) # Firehoseエラー
      └─> CloudWatch Logs (/ecs/container/error-logs: worker) # workerコンテナのエラーログのみを出力
```

```
ECS - Batch
 * AWS BatchのECSがFirelens対応されるまでの暫定設定
 └─> CloudWatch Logs (/ecs/container/logs: batch-default) # batch-defaultコンテナのログを出力（AWS BatchのECSがFirelens対応されるまではこちらを利用します。）

 * AWS BatchのECSがFirelens対応された場合の将来設定
 ├─> CloudWatch Logs (/ecs/container/firelens: batch-default) # Fluent Bitのログを出力
 └─> FireLens (Fluent Bit)
      ├─> Firehose (ecs-container-logs-batch-default)
      │    ├─> S3 (ecs-container-logs-batch-default-#{accountid}: logs/year=yyyy/... | errors/year=yyyy...) # コンテナのすべてのログを出力
      │    └─> CloudWatch Logs (/firehose/errors: ecs-batch-default-fluentd-firehose-s3) # Firehoseエラー
      └─> CloudWatch Logs (/ecs/container/error-logs: batch-default) # batch defaultコンテナのエラーログのみを出力
```

- コンテナに入るコマンド
```
aws ecs execute-command --region ap-northeast-1 \
  --cluster {cluster name} \
  --task {ecs task arn} \
  --container {container name} \
  --interactive \
  --command "/bin/sh"
```

- バッチ実行コマンドサンプル
```
aws batch submit-job \
  --job-name example1 \
  --job-definition batch-default \
  --job-queue batch-default \
  --ecs-properties-override '{
    "taskProperties": [{
      "containers": [{
        "name": "batch-default",
        "command": ["bundle", "exec", "rake", "test[hoge,fuga]"]
      }]
    }]
  }'

aws batch submit-job \
  --job-name example2 \
  --job-definition batch-default \
  --job-queue batch-default \
  --ecs-properties-override '{
    "taskProperties": [{
      "containers": [{
        "name": "batch-default",
        "command": ["bash", "-c", "${COMMAND}"],
        "environment": [{
          "name": "COMMAND",
          "value": "bundle exec rake test[hoge,fuga]"
        }]
      }]
    }]
  }'
```
