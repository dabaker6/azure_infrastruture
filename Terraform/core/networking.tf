# Create a Virtual Network in Azure using Terraform.

resource "azurerm_virtual_network" "main" {
  name                      = "vnet-${var.product}"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  address_space             = var.personal_website_vnet_prefixes
}