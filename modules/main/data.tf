# ここでは汎用的に利用されるものを定義します。
# リソース固有のものは該当リソースファイル内に記述してください。
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
