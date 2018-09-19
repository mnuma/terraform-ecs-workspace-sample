terraform {
  required_version = "v0.11.8"
  backend "s3" {
    bucket = "sample-terraform"
    key    = "sample-terraform.tfstate"
    region = "ap-northeast-1"
  }
}
