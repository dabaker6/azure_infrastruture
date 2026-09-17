# Create user assigned identity for github oidc to use. The user assigned identity will be used by the federated identity credential to access the azure resources.

resource "azurerm_user_assigned_identity" "github_oidc" {
  location              = azurerm_resource_group.main.location
  name                  = "github-oidc"
  resource_group_name   = azurerm_resource_group.main.name
}

# Federated credential for github oidc to use for the webapp. The federated identity credential will be used by the github actions workflow to access the azure resources.
resource "azurerm_federated_identity_credential" "github_oidc_web_app" {
  name                      = "github-oidc-webapp"
  audience                 = ["api://AzureADTokenExchange"] 
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_oidc.id
  subject                   = "repo:${var.github_oidc_personal_website_organisation}/${var.github_oidc_personal_website_webapp_repo}:ref:refs/heads/${var.github_oidc_personal_website_webapp_branch}"
}

# Federated credential for github oidc to use for cric api. The federated identity credential will be used by the github actions workflow to access the azure resources.
resource "azurerm_federated_identity_credential" "github_oidc_cric_api" {
  name                      = "github-oidc-cric-api"
  audience                 = ["api://AzureADTokenExchange"] 
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_oidc.id
  subject                   = "repo:${var.github_oidc_personal_website_organisation}/${var.github_oidc_personal_website_cric_api_repo}:ref:refs/heads/${var.github_oidc_personal_website_cric_api_branch}"
}

# Federated credential for github oidc to use for the scaling api. The federated identity credential will be used by the github actions workflow to access the azure resources.
resource "azurerm_federated_identity_credential" "github_oidc_scaling_api" {
  name                      = "github-oidc-scaling-api"
  audience                 = ["api://AzureADTokenExchange"] 
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_oidc.id
  subject                   = "repo:${var.github_oidc_personal_website_organisation}/${var.github_oidc_personal_website_scaling_api_repo}:ref:refs/heads/${var.github_oidc_personal_website_scaling_api_branch}"
}