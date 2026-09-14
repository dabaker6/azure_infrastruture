# This file contains the DNS zone configuration for Azure using Terraform.

resource "azurerm_dns_zone" "main" {
  name                  = var.dns_zone_name
  resource_group_name   = azurerm_resource_group.main.name
  soa_record {
    email               = var.dns_zone_email
  }
}