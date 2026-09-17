# Create container app for scaling worker
resource "azurerm_container_app" "scaling" {
  name                         = "ca-${var.scaling_name}-worker"
  container_app_environment_id = data.terraform_remote_state.core.outputs.container_app_environment.id
  resource_group_name          = data.terraform_remote_state.core.outputs.resource_group.name
  revision_mode                = "Single"

  # Configure ACR authentication
  registry {
    server   = data.terraform_remote_state.core.outputs.container_registry.login_server
    identity = azurerm_user_assigned_identity.aca_scaling_worker.id
  }

  template {
    container {
      name   = "${var.scaling_name}-worker"
      image  = "ghcr.io/${var.github_org}/${var.scaling_repo}-worker:${var.scaling_worker_image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      #env variables

      env {
        name  = "ServiceBus__FullyQualifiedNamespace"
        value = regex("https://(.*):d*", data.terraform_remote_state.core.outputs.servicebus_namespace.endpoint)[0]
      }
      env {
        name  = "ServiceBus__QueueName"
        value = azurerm_servicebus_queue.scaling.name
      }
      env {
        name  = "ServiceBus__ProcessingTime"
        value = var.scaling_worker_processing_time
      }
    }
    cooldown_period_in_seconds  = var.scaling_worker_cooldown_period_in_seconds
    polling_interval_in_seconds = var.scaling_worker_interval_in_seconds
    min_replicas                = var.scaling_worker_min_replicas
    max_replicas                = var.scaling_worker_max_replicas
    custom_scale_rule {
      name             = "${var.scaling_name}-rule"
      custom_rule_type = "azure-servicebus"
      metadata = {
        "queueName" : azurerm_servicebus_queue.scaling.name
        "namespace" : data.terraform_remote_state.core.outputs.servicebus_namespace.name
        "messageCount" : var.scaling_worker_message_count
      }
      identity_id = azurerm_user_assigned_identity.aca_scaling_worker.id
    }
  }

  # Assign managed identity
  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_scaling_worker.id]
  }
}

# Permission for managed identity to pull from ACR in container app.
resource "azurerm_role_assignment" "container_app_acr_pull" {
  scope                = data.terraform_remote_state.core.outputs.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_scaling_worker.principal_id
}

# Permission for managed identity to push to ACR in github actions workflow. In it's own file as common across compute and container apps
resource "azurerm_role_assignment" "github_actions_oidc_aca" {
  scope                = azurerm_container_app.scaling.id
  role_definition_name = "Container Apps Contributor"
  principal_id         = data.terraform_remote_state.core.outputs.github_oidc.principal_id
}

# Create user assinged identity for scale rule to use. This is required because the system assigned identity is not available at the time of scale rule creation. The user assigned identity will be used by the scale rule to access the service bus queue.
resource "azurerm_user_assigned_identity" "aca_scaling_worker" {
  location            = data.terraform_remote_state.core.outputs.resource_group.location
  name                = "id-${var.scaling_name}-worker"
  resource_group_name = data.terraform_remote_state.core.outputs.resource_group.name
}

# Create service bus queue for scaling worker to listen to. The queue will be used to trigger the scaling of the container app.
resource "azurerm_servicebus_queue" "scaling" {
  name                = "sbq-${var.scaling_name}"
  namespace_id        = data.terraform_remote_state.core.outputs.servicebus_namespace.id
  default_message_ttl = "P14D"
}

# Use system assigned for .net worker 

resource "azurerm_role_assignment" "container_app_servicebus" {
  scope                = azurerm_servicebus_queue.scaling.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_container_app.scaling.identity[0].principal_id
}

# Worker can receive messages from the service bus queue

resource "azurerm_role_assignment" "container_app_scale_rule_servicebus" {
  scope                = azurerm_servicebus_queue.scaling.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.aca_scaling_worker.principal_id
}