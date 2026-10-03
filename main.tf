locals {
  common_tags = {
    Application = var.application_name
    Environment = var.environment_name
    ManagedBy   = "Terraform"
    Purpose     = "Learning"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.application_name}-${var.environment_name}"
  location = var.primary_location
  tags     = local.common_tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.application_name}-${var.environment_name}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5
  tags                = local.common_tags
}
