data "terraform_remote_state" "core" {
  backend = "local"
  config = {
    path = "../Core/terraform.tfstate"
  }
}
