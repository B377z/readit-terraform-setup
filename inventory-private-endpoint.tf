resource "azurerm_private_endpoint" "inventory" {
  count = var.deploy_inventory_private_endpoint ? 1 : 0

  name                = "pep-${var.application_name}-inventory-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-${var.application_name}-inventory-${var.environment_name}"
    private_connection_resource_id = azurerm_linux_web_app.inventory[0].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "inventory-app-service"
    private_dns_zone_ids = [azurerm_private_dns_zone.app_service[0].id]
  }

  tags = local.common_tags
}
