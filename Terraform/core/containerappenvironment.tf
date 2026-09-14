# Create a Container App Environment in Azure using Terraform. 

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.product}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  identity {
    type                     = "SystemAssigned"
    }
}