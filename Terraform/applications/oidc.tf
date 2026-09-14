# Permission for managed identity to push to ACR in github actions workflow. In it's own file as common across compute and container apps
resource "azurerm_role_assignment" "github_actions_oidc_acr" {
  scope                 = data.terraform_remote_state.core.outputs.container_registry.id
  role_definition_name  = "AcrPush"
  principal_id          = data.terraform_remote_state.core.outputs.github_oidc.principal_id
}