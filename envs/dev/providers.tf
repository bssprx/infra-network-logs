provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::954976316824:role/bssprx-iam-terraform-admin"
    session_name = "terraform-sandbox"
  }
}