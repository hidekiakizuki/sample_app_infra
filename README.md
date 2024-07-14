# 概要
RailsアプリケーションをECS上でBlue/Greenデプロイできるように構成されています。  
一部、terraform対象外のリソースも含まれます。  
(SSMパラメータストア、Route53やtfstateファイルのバックアップなどです。)

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

### 4. VPC作成

### 5. IAM作成

### 6. KMS作成

### 7. SSMパラメータストアでパラメータ登録
以下をAWSマネジメントコンソールから手動で登録します。
- `/app/rails/secret_key_base`
- `/rds/postgres/host`（※ 値はdummyで登録）
- `/rds/postgres/user`
- `/rds/postgres/password`
- `/rds/postgres/database`

### 8. ACMでSSL証明書を作成
AWSマネジメントコンソールから手動で作成します。  
アプリケーションを配置するメインのregionとus-east-1リージョンでそれぞれ作成してください。  
ALBとCloudFrontそれぞれで利用します。

ドメインは別のAWSアカウントで管理する想定なので注意してください。

### 9. RDS作成
インスタンス作成後、SSMパラメータストアの`/rds/postgres/host`に値をセットします。

### 10. ECR作成

### 11. ALB作成
以下のリソースを一時的にコメントアウトしてterraform applyします。
- `data.aws_lb_listener.current_https`
- `data.external.current_https_target_group_arn`
- `local.current_https_target_group_arn`

terraform apply後、コメントを戻します。  

### 12. CloudWatch Logs作成

### 13. ECS作成

### 14. CodeDeploy作成

### 15. CloudWatch Alarm作成

### 16. SNS作成

### 17. Chatbot作成
AWSマネジメントコンソールから手動で作成します。
予めSlackで通知先チャンネルを作成しておき、SNS topicを設定してください。

### 18. WAF作成

### 19. CloudFront作成
ドメインを管理しているAWSアカウントのRoute53でAレコード作成し、エイリアスにこのディストリビューションを指定します。

### 20. GitHubのIDプロバイダを追加
IAMにてIDプロバイダを追加します。
- プロバイダのタイプ: `OpenID Connect`
- プロバイダのURL: `https://token.actions.githubusercontent.com`
- 対象者: `sts.amazonaws.com`

# TODO
- LBでアクセスログ、コネクションログ追加
- アプリログ改善（JSON化、FireLensで出力先変更）
