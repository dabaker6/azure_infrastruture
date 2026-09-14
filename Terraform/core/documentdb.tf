# Create a DocumentDB in Azure using Terraform.

resource "azurerm_cosmosdb_account" "db" {
  name                                  = "db-${var.product}"
  resource_group_name                   = azurerm_resource_group.main.name
  location                              = azurerm_resource_group.main.location
  offer_type                            = "Standard"
  kind                                  = "GlobalDocumentDB"
  free_tier_enabled                     = true
  capacity {
    total_throughput_limit = 1000
  }
  
  minimal_tls_version                   = "Tls12"
  local_authentication_disabled         = "false"
  
  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }
  geo_location {
    failover_priority = 0
    location          = "westeurope"
    zone_redundant    = true
  }
  geo_location {
    failover_priority = 1
    location          = "northeurope"
    zone_redundant    = true
  }    

  backup {
    interval_in_minutes = 240
    retention_in_hours  = 8
    storage_redundancy  = "Geo"
    type                = "Periodic"
  }  
}

# Create Cosmos db database
resource "azurerm_cosmosdb_sql_database" "cric" {
  name                  = "cosmos-${var.cric_api_cosmos_database_name}"
  resource_group_name   = azurerm_resource_group.main.name
  account_name          = azurerm_cosmosdb_account.db.name
}

# Create Cosmos db container
resource "azurerm_cosmosdb_sql_container" "cric" {
  name                  = var.cric_api_cosmos_container_name
  resource_group_name   = azurerm_resource_group.main.name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = azurerm_cosmosdb_sql_database.cric.name
  partition_key_paths   = [var.cric_api_partition_key]
}