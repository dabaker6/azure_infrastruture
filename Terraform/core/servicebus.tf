# Create a Service Bus in Azure using Terraform.

resource "azurerm_servicebus_namespace" "main" {
  name                      = "sbns-${var.product}"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  sku                       = "Basic"  
  identity {
    type                    = "SystemAssigned"
    }
}