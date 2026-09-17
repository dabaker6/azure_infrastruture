terraform {
  required_version = ">= 0.12"

  required_providers {
    azaapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.0"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "azurerm" {
  features {}
}