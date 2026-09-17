# Create a Resource Group in Azure using Terraform.

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.product}"
  location = var.location
}