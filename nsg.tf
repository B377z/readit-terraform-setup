resource "azurerm_network_security_group" "catalog" {
  name                = "nsg-${var.application_name}-${var.environment_name}-catalog"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-RDP-From-Admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP-From-Admin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP-From-AppGateway"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = azurerm_subnet.application_gateway.address_prefixes[0]
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_network_security_group" "weather" {
  name                = "nsg-${var.application_name}-${var.environment_name}-weather"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-Catalog-To-Weather"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.0.0.4/32"
    destination_address_prefix = "10.30.0.5/32"
  }

  security_rule {
    name                       = "Deny-Other-VNet-To-Weather"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "10.30.0.5/32"
  }

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "catalog" {
  subnet_id                 = azurerm_subnet.catalog.id
  network_security_group_id = azurerm_network_security_group.catalog.id
}

resource "azurerm_subnet_network_security_group_association" "weather" {
  subnet_id                 = azurerm_subnet.weather.id
  network_security_group_id = azurerm_network_security_group.weather.id
}
