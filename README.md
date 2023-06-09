# terraform-with-terratest


## 概要

S3 + CloudFront + WAFをterraformにて管理し、Github Actionsにてterraformのデプロイを自動化。

また、Github Actionsとterratestにて単体テスト実施。


## GitHub Actions動作

- feature/**ブランチにてPUSHした際にterratestにより一時的にリソースを作成しs3ウェブホスティングへのアクセステストを行う。


- stagingブランチへプルリクエストレビュー依頼した際にterraform planを実行する。


- 上記プルリクエスト承認後のマージした際にterraform applyを実行する。



## 実行確認の準備

以下の作業が必要。


- git clone後にconfig情報を変え自身のGithub RepositoryにPUSH。

- workflowの中でOIDC ID プロバイダー用のRoleをsecretsにて参照しているため、settingsからAWS_ROLE_ARNを設定。(このリポジトリには未設定)



```
env:
  TF_VERSION: "1.3.0"
  AWS_DEFAULT_REGION: ap-northeast-1
  AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }} 
```

- staging/terraform.tfに自身の依存関係用s3 bucket名をセット。


```
terraform {
  backend "s3" {
    bucket = "your s3" 
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}
```
