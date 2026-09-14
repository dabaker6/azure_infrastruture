# Web app configuration for the personal website, cric api and scaling api. 
locals {
    
    web_app_base_settings = {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    }

    web_app_dynamic_settings = {
      MATCHES_API_BASE_URL            = "https://${azurerm_linux_web_app.cric_api.default_hostname}/api/${var.cric_api_version}" #need to change to custom domain
      ACA_API_BASE_URL                = "https://${azurerm_linux_web_app.scaling_api.default_hostname}/api/${var.scaling_api_version}" #need to change to custom domain
      BACKGROUND_POLLING_INTERVAL_MS  = var.scaling_api_background_polling
      POLLING_INTERVAL_MS             = var.scaling_api_polling
    }

    cric_api_base_settings = {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    }

    cric_api_dynamic_settings = {
      Cosmos__AccountEndpoint         = data.terraform_remote_state.core.outputs.cosmos_db.endpoint
      Cosmos__DatabaseName            = "${data.terraform_remote_state.core.outputs.cosmos_db.database_name}"
      Cosmos__ContainerName           = data.terraform_remote_state.core.outputs.cosmos_db.container_name
      Cosmos__ManagedIdentityClientId = ""
    }

    scaling_api_base_settings = {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    }

    scaling_api_dynamic_settings = {
      ServiceBus__FullyQualifiedNamespace   = regex("https://(.*):d*",data.terraform_remote_state.core.outputs.servicebus_namespace.endpoint)[0]
      ServiceBus__ProcessingTime            = var.scaling_worker_processing_time
      ServiceBus__QueueName                 = azurerm_servicebus_queue.scaling.name
      ContainerApps__ContainerAppName       = azurerm_container_app.scaling.name
      ContainerApps__ResourceGroup          = data.terraform_remote_state.core.outputs.resource_group.name
      ContainerApps__SubscriptionId         = data.azurerm_subscription.current.subscription_id
    }
}

data "azurerm_subscription" "current" {
}

resource "time_sleep" "wait_for_webapp" {
  create_duration = "30s"
  depends_on      = [azurerm_linux_web_app.web_app]
}

# Create website webapp
resource "azurerm_linux_web_app" "web_app" {
  name                = "app-${var.product}"
  location            = data.terraform_remote_state.core.outputs.resource_group.location
  resource_group_name = data.terraform_remote_state.core.outputs.resource_group.name
  service_plan_id     = data.terraform_remote_state.core.outputs.service_plan.id

  site_config {
    always_on = true
    application_stack {
        docker_image_name   = "${var.web_app_image_name}:${var.web_app_image_tag}"
        docker_registry_url = "https://${data.terraform_remote_state.core.outputs.container_registry.login_server}"
    }
    minimum_tls_version = "1.3"
    container_registry_use_managed_identity = true
    
  }
  virtual_network_subnet_id = azurerm_subnet.web_app.id
  identity {
      type = "SystemAssigned"
    }
  https_only = true
  app_settings = merge(local.web_app_base_settings, local.web_app_dynamic_settings)
}

# Permission for webapp to pull from ACR
resource "azurerm_role_assignment" "web_app_acr" {  
  scope                = data.terraform_remote_state.core.outputs.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.web_app.identity[0].principal_id
  
  depends_on = [time_sleep.wait_for_webapp]
}

# Permission for managed identity to reset web app
resource "azurerm_role_assignment" "github_actions_oidc_web_app" {
  scope                 = azurerm_linux_web_app.web_app.id
  role_definition_name  = "Website Contributor"
  principal_id          = data.terraform_remote_state.core.outputs.github_oidc.principal_id
}

# Website subnet
resource "azurerm_subnet" "web_app" {  
  name                      = "snet-${var.product}-webapp"
  resource_group_name       = data.terraform_remote_state.core.outputs.resource_group.name
  virtual_network_name      = data.terraform_remote_state.core.outputs.virtual_network.name
  address_prefixes          = var.personal_website_subnet_web_app_prefixes
  service_endpoints         = ["Microsoft.Web"]

  delegation {
    name = "webapp-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Cric API webapp
resource "azurerm_linux_web_app" "cric_api" {
  name                = "app-${var.product}-cric-api"
  location            = data.terraform_remote_state.core.outputs.resource_group.location
  resource_group_name = data.terraform_remote_state.core.outputs.resource_group.name
  service_plan_id     = data.terraform_remote_state.core.outputs.service_plan.id

  site_config {
    always_on = true
    application_stack {
        docker_image_name   = "${var.cric_api_image_name}:${var.cric_api_image_tag}"
        docker_registry_url = "https://${data.terraform_remote_state.core.outputs.container_registry.login_server}"
    }
    minimum_tls_version = "1.3"
    container_registry_use_managed_identity = true
    ip_restriction {
      action                    = "Allow"
      priority                  = 100
      virtual_network_subnet_id = azurerm_subnet.web_app.id
      name                      = "web_app_allow"
      description               = "allows the web_app frontend to access the api"    
    }      
    ip_restriction {      
      action                    = "Deny"
      priority                  = 200
      ip_address                = "0.0.0.0/0"
      name                      = "cric_api_deny"
      description               = "Deny access the cric_api"    
    }
      
  }
  virtual_network_subnet_id = azurerm_subnet.cric_api.id
  identity {
      type = "SystemAssigned"
    }
  https_only = true
  app_settings = merge(local.cric_api_base_settings, local.cric_api_dynamic_settings)
}

# Permission for cric API to pull from ACR
resource "azurerm_role_assignment" "cric_api_acr" {  
  scope                = data.terraform_remote_state.core.outputs.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.cric_api.identity[0].principal_id
  
  depends_on = [time_sleep.wait_for_webapp]
}

# Permission for managed identity to reset web app
resource "azurerm_role_assignment" "github_actions_oidc_cric_api" {
  scope                 = azurerm_linux_web_app.cric_api.id
  role_definition_name  = "Website Contributor"
  principal_id          = data.terraform_remote_state.core.outputs.github_oidc.principal_id
}

# Subnet for cric api webapp
resource "azurerm_subnet" "cric_api" {  
  name                      = "snet-${var.product}-cric-api"
  resource_group_name       = data.terraform_remote_state.core.outputs.resource_group.name
  virtual_network_name      = data.terraform_remote_state.core.outputs.virtual_network.name
  address_prefixes          = var.personal_website_subnet_cric_api_prefixes

  delegation {
    name = "${var.product}-${var.cric_api_image_name}-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Create a Cosmos DB role definition for cric API, by default it is a read only role, but can be changed to any role by changing the variable cric_api_cosmos_permission
data "azurerm_cosmosdb_sql_role_definition" "permission" {
  resource_group_name   = data.terraform_remote_state.core.outputs.resource_group.name
  account_name          = data.terraform_remote_state.core.outputs.cosmos_db.account_name
  role_definition_id    = var.cric_api_cosmos_permission
}

# Assign the Cosmos DB role to the cric API web app
resource "azurerm_cosmosdb_sql_role_assignment" "cric" {  
  resource_group_name   = data.terraform_remote_state.core.outputs.resource_group.name
  account_name          = data.terraform_remote_state.core.outputs.cosmos_db.account_name
  role_definition_id    = data.azurerm_cosmosdb_sql_role_definition.permission.id
  principal_id          = azurerm_linux_web_app.cric_api.identity[0].principal_id
  scope                 = "${data.terraform_remote_state.core.outputs.cosmos_db.account_id}/dbs/${data.terraform_remote_state.core.outputs.cosmos_db.database_name}/colls/${data.terraform_remote_state.core.outputs.cosmos_db.container_name}"
}

# Scaling demo webapp
resource "azurerm_linux_web_app" "scaling_api" {
  name                = "app-${var.product}-${var.scaling_name}-api"
  location            = data.terraform_remote_state.core.outputs.resource_group.location
  resource_group_name = data.terraform_remote_state.core.outputs.resource_group.name
  service_plan_id     = data.terraform_remote_state.core.outputs.service_plan.id

  site_config {
    always_on = true
    application_stack {
        docker_image_name   = "aca-${var.scaling_name}-api:${var.scaling_api_image_tag}"
        docker_registry_url = "https://${data.terraform_remote_state.core.outputs.container_registry.login_server}"
    }
    minimum_tls_version = "1.3"
    container_registry_use_managed_identity = true
    ip_restriction {
      action                    = "Allow"
      priority                  = 100
      virtual_network_subnet_id = azurerm_subnet.web_app.id
      name                      = "web_app_allow"
      description               = "allows the web_app frontend to access the api"    
    }      
    ip_restriction {      
      action                    = "Deny"
      priority                  = 200
      ip_address                = "0.0.0.0/0"
      name                      = "scaling_api_deny"
      description               = "Deny access the cric_api"    
    }
      
  }
  virtual_network_subnet_id = azurerm_subnet.cric_api.id
  identity {
      type = "SystemAssigned"
    }
  https_only = true
  app_settings = merge(local.scaling_api_base_settings, local.scaling_api_dynamic_settings)

}

# Assign ACR pull to the scaling api webapp
resource "azurerm_role_assignment" "scaling_api_acr" {  
  scope                = data.terraform_remote_state.core.outputs.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.scaling_api.identity[0].principal_id
  
  depends_on = [time_sleep.wait_for_webapp]
}

# Permission for managed identity to reset web app
resource "azurerm_role_assignment" "github_actions_oidc_scaling_api" {
  scope                 = azurerm_linux_web_app.scaling_api.id
  role_definition_name  = "Website Contributor"
  principal_id          = data.terraform_remote_state.core.outputs.github_oidc.principal_id
}

# Assign ContainerApp Reader role to the scaling api webapp to get app replica data
resource "azurerm_role_assignment" "scaling_api_ca" {  
  scope                = azurerm_container_app.scaling.id
  role_definition_name = "ContainerApp Reader"
  principal_id         = azurerm_linux_web_app.scaling_api.identity[0].principal_id

}

# Assgin Service Bus Data Sender role to the scaling api webapp to send messages to the queue
resource "azurerm_role_assignment" "scaling_api_sbq" {  
  scope                = azurerm_servicebus_queue.scaling.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_linux_web_app.scaling_api.identity[0].principal_id
}