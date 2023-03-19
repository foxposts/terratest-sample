terraform {
  backend "s3" {
    bucket = "your s3"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}