terraform {
  backend "s3" {
    bucket         = "bssprx-terraform-state"
    key            = "envs/infra-network-logs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bssprx-terraform-state-lock"
    encrypt        = true
  }
}