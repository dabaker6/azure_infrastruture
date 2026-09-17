output "resource_group" {
  value = {
    name            = azurerm_resource_group.main.name
    id              = azurerm_resource_group.main.id
    location        = azurerm_resource_group.main.location
    }
}

output "service_plan" {
  value = {
    name            = azurerm_service_plan.main.name
    id              = azurerm_service_plan.main.id
    }
}

output "container_registry" {
  value = {
    name            = azurerm_container_registry.main.name
    login_server    = azurerm_container_registry.main.login_server
    id              = azurerm_container_registry.main.id
    }
}

output "virtual_network" {
  value = {
    name            = azurerm_virtual_network.main.name
    }
}

output "cosmos_db" {
  value = {
    account_name    = azurerm_cosmosdb_account.db.name
    account_id      = azurerm_cosmosdb_account.db.id
    endpoint        = azurerm_cosmosdb_account.db.endpoint
    database_name   = azurerm_cosmosdb_sql_database.cric.name
    container_name  = azurerm_cosmosdb_sql_container.cric.name
  }  
}

output "container_app_environment" {
  value = {
    id              = azurerm_container_app_environment.main.id
  }
}

output "servicebus_namespace" {
  value = {
    name          = azurerm_servicebus_namespace.main.name
    endpoint      = azurerm_servicebus_namespace.main.endpoint
    id            = azurerm_servicebus_namespace.main.id
  }
}

output "dns_zone" {
  value = {
    name          = azurerm_dns_zone.main.name
    id            = azurerm_dns_zone.main.id
  }
}

output "github_oidc" {
  value = {
    client_id     = azurerm_user_assigned_identity.github_oidc.client_id
    principal_id  = azurerm_user_assigned_identity.github_oidc.principal_id
    }
}