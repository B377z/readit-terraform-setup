output "resource_group_name" {
  description = "Name of the ReadIt resource group"
  value       = azurerm_resource_group.main.name
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "virtual_networks" {
  description = "ReadIt virtual networks"

  value = {
    application = {
      name          = azurerm_virtual_network.main.name
      address_space = azurerm_virtual_network.main.address_space
    }

    ingress = {
      name          = azurerm_virtual_network.ingress.name
      address_space = azurerm_virtual_network.ingress.address_space
    }

    weather = {
      name          = azurerm_virtual_network.weather.name
      address_space = azurerm_virtual_network.weather.address_space
    }
  }
}

output "subnet_ids" {
  description = "Resource IDs of the ReadIt subnets"

  value = {
    catalog                 = azurerm_subnet.catalog.id
    weather                 = azurerm_subnet.weather.id
    app_service_integration = azurerm_subnet.app_service_integration.id
    function_integration    = azurerm_subnet.function_integration.id
    private_endpoints       = azurerm_subnet.private_endpoints.id
    aks                     = azurerm_subnet.aks.id
    application_gateway     = azurerm_subnet.application_gateway.id
  }
}

output "network_security_group_ids" {
  description = "Resource IDs of the ReadIt network security groups"

  value = {
    catalog = azurerm_network_security_group.catalog.id
    weather = azurerm_network_security_group.weather.id
  }
}

output "internal_dns_zone_name" {
  description = "ReadIt internal private DNS zone"
  value       = azurerm_private_dns_zone.internal.name
}

output "internal_service_names" {
  description = "Internal DNS names for ReadIt services"

  value = {
    catalog = "catalog.${azurerm_private_dns_zone.internal.name}"
    weather = "weather.${azurerm_private_dns_zone.internal.name}"
  }
}

output "catalog_vm" {
  description = "Catalog VM connection information"

  value = var.deploy_catalog_vm ? {
    name       = azurerm_windows_virtual_machine.catalog[0].name
    private_ip = azurerm_network_interface.catalog[0].private_ip_address
    public_ip  = azurerm_public_ip.catalog[0].ip_address
    dns_name   = "catalog.${azurerm_private_dns_zone.internal.name}"
  } : null
}

output "weather_vm" {
  description = "Weather API VM information"

  value = var.deploy_weather_vm ? {
    name       = azurerm_linux_virtual_machine.weather[0].name
    private_ip = azurerm_network_interface.weather[0].private_ip_address
    dns_name   = "weather.${azurerm_private_dns_zone.internal.name}"
  } : null
}

output "inventory_app_service" {
  description = "Inventory App Service information"

  value = var.deploy_inventory_app_service ? {
    name            = azurerm_linux_web_app.inventory[0].name
    hostname        = azurerm_linux_web_app.inventory[0].default_hostname
    url             = "https://${azurerm_linux_web_app.inventory[0].default_hostname}"
    service_plan    = azurerm_service_plan.inventory[0].name
    outbound_subnet = azurerm_subnet.app_service_integration.name
    public_access   = azurerm_linux_web_app.inventory[0].public_network_access_enabled
  } : null
}

output "inventory_private_endpoint" {
  description = "Inventory private inbound connection information"

  value = var.deploy_inventory_private_endpoint ? {
    name       = azurerm_private_endpoint.inventory[0].name
    private_ip = azurerm_private_endpoint.inventory[0].private_service_connection[0].private_ip_address
    dns_zone   = azurerm_private_dns_zone.app_service[0].name
    hostname   = azurerm_linux_web_app.inventory[0].default_hostname
    url        = "https://${azurerm_linux_web_app.inventory[0].default_hostname}"
  } : null
}
