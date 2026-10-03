resource "azurerm_private_dns_zone" "internal" {
  name                = "readit.internal"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal" {
  name                  = "link-${var.application_name}-${var.environment_name}-vnet"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal_ingress" {
  name                  = "link-${var.application_name}-${var.environment_name}-ingress"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = azurerm_virtual_network.ingress.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal_weather" {
  name                  = "link-${var.application_name}-${var.environment_name}-weather"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = azurerm_virtual_network.weather.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_a_record" "catalog" {
  name                = "catalog"
  zone_name           = azurerm_private_dns_zone.internal.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = ["10.0.0.4"]

  tags = local.common_tags
}

resource "azurerm_private_dns_a_record" "weather" {
  name                = "weather"
  zone_name           = azurerm_private_dns_zone.internal.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = ["10.30.0.5"]

  tags = local.common_tags
}

