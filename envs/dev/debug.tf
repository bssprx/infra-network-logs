resource "null_resource" "whoami" {
  provisioner "local-exec" {
    command = "aws sts get-caller-identity"
  }
}