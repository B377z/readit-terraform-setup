resource "random_string" "inventory_suffix" {
  count = var.deploy_inventory_app_service ? 1 : 0

  length  = 5
  upper   = false
  special = false
  numeric = true

  keepers = {
    application = var.application_name
    environment = var.environment_name
  }
}

resource "azurerm_service_plan" "inventory" {
  count = var.deploy_inventory_app_service ? 1 : 0

  name                = "asp-${var.application_name}-inventory-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  os_type  = "Linux"
  sku_name = var.inventory_app_service_sku

  tags = local.common_tags
}

resource "azurerm_linux_web_app" "inventory" {
  count = var.deploy_inventory_app_service ? 1 : 0

  name = join(
    "-",
    [
      var.application_name,
      "inventory",
      var.environment_name,
      random_string.inventory_suffix[0].result
    ]
  )

  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.inventory[0].id

  https_only                    = true
  public_network_access_enabled = true
  virtual_network_subnet_id     = azurerm_subnet.app_service_integration.id

  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    ASPNETCORE_ENVIRONMENT   = "Production"
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  site_config {
    always_on           = true
    http2_enabled       = true
    minimum_tls_version = "1.2"

    application_stack {
      dotnet_version = "8.0"
    }
  }

  logs {
    detailed_error_messages = false
    failed_request_tracing  = false

    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  tags = local.common_tags
}
