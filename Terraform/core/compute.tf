# Create App Service Plan

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.product}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = var.app_service_plan_kind
  sku_name            = var.app_service_plan_sku    
}