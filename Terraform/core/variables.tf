variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "westeurope"
}

variable "product" {
  description = "The name of the product to create."
  type        = string
  default     = ""
}

variable "app_service_plan_sku" {
  description = "The SKU of the App Service Plan to create."
  type        = string
  default     = "B1"
}

variable "app_service_plan_kind" {
  description = "The kind of the App Service Plan to create."
  type        = string
  default     = "Linux"
}

variable "cric_api_cosmos_container_name" {
  type    = string
}

variable "cric_api_cosmos_database_name" {
  type    = string
}

variable "cric_api_partition_key" {
  type    = string
  default = "/id"
}

variable "personal_website_vnet_prefixes" {
  type    = list(string)
}

variable "dns_zone_name" {
  type    = string
  default = "david-baker.co.uk"
}

variable "dns_zone_email" {
  type    = string
  default = "azuredns-hostmaster.microsoft.com"
}

variable "github_oidc_personal_website_organisation" {
  type    = string
  default = "dabaker6"
}

variable "github_oidc_personal_website_webapp_repo" {
  type    = string
  default = "personal_website"
}

variable "github_oidc_personal_website_webapp_branch" {
  type    = string
  default = "main"
}

variable "github_oidc_personal_website_cric_api_repo" {
  type    = string
  default = "cricsheet_api"
}

variable "github_oidc_personal_website_cric_api_branch" {
  type    = string
  default = "main"
}

variable "github_oidc_personal_website_scaling_api_repo" {
  type = string
  default = "scaling_api"
}

variable "github_oidc_personal_website_scaling_api_branch" {
  type    = string
  default = "master"
}