locals {
  weather_bootstrap_script = <<-BASH
    #!/usr/bin/env bash
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive

    echo "Installing prerequisites..."
    apt-get update
    apt-get install -y ca-certificates curl

    echo "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs

    echo "Creating service account..."
    id -u weatherapi >/dev/null 2>&1 || \
      useradd --system --home /opt/weather-api --shell /usr/sbin/nologin weatherapi

    install -d -o weatherapi -g weatherapi /opt/weather-api

    cat > /opt/weather-api/package.json <<'EOF'
    {
      "name": "readit-weather-api",
      "version": "1.0.0",
      "private": true,
      "main": "app.js",
      "scripts": {
        "start": "node app.js"
      },
      "dependencies": {
        "express": "4.21.2"
      }
    }
    EOF

    cat > /opt/weather-api/app.js <<'EOF'
    "use strict";

    const express = require("express");

    const app = express();
    const port = 8080;

    app.disable("x-powered-by");

    app.get("/health", (req, res) => {
      res.status(200).json({
        status: "healthy",
        service: "weather-api",
        timestamp: new Date().toISOString()
      });
    });

    app.get("/api/weather", (req, res) => {
      const temperature = Math.floor(Math.random() * 46) - 25;
      res.status(200).type("text/plain").send(String(temperature));
    });

    app.use((req, res) => {
      res.status(404).json({
        error: "Not found"
      });
    });

    app.listen(port, "0.0.0.0", () => {
      console.log("Weather API listening on port " + port);
    });
    EOF

    cd /opt/weather-api
    npm install --omit=dev

    chown -R weatherapi:weatherapi /opt/weather-api

    cat > /etc/systemd/system/weather-api.service <<'EOF'
    [Unit]
    Description=ReadIt Weather API
    Wants=network-online.target
    After=network-online.target

    [Service]
    Type=simple
    User=weatherapi
    Group=weatherapi
    WorkingDirectory=/opt/weather-api
    ExecStart=/usr/bin/node /opt/weather-api/app.js
    Restart=always
    RestartSec=5
    Environment=NODE_ENV=production

    NoNewPrivileges=true
    PrivateTmp=true
    ProtectSystem=full
    ProtectHome=true

    [Install]
    WantedBy=multi-user.target
    EOF

    systemctl daemon-reload
    systemctl enable weather-api
    systemctl restart weather-api

    for attempt in $(seq 1 30); do
      if curl --fail --silent http://localhost:8080/health; then
        echo
        echo "Weather API bootstrap completed successfully."
        exit 0
      fi

      sleep 2
    done

    echo "Weather API failed its health check."
    journalctl -u weather-api --no-pager -n 100
    exit 1
  BASH

  weather_bootstrap_script_lf = replace(
    local.weather_bootstrap_script,
    "\r\n",
    "\n"
  )
}

resource "azurerm_network_interface" "weather" {
  count = var.deploy_weather_vm ? 1 : 0

  name                = "nic-${var.application_name}-weather-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig-weather"
    subnet_id                     = azurerm_subnet.weather.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.30.0.5" # Replace with the desired static IP address within the subnet range
  }

  tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "weather" {
  count = var.deploy_weather_vm ? 1 : 0

  name                = "vm-${var.application_name}-weather-${var.environment_name}"
  computer_name       = "weather-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.weather_vm_size

  admin_username                  = var.weather_admin_username
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.weather[0].id
  ]

  admin_ssh_key {
    username   = var.weather_admin_username
    public_key = var.weather_ssh_public_key
  }

  os_disk {
    name                 = "osdisk-${var.application_name}-weather-${var.environment_name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_virtual_machine_extension" "weather_bootstrap" {
  count = var.deploy_weather_vm ? 1 : 0

  name                       = "weather-bootstrap"
  virtual_machine_id         = azurerm_linux_virtual_machine.weather[0].id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    commandToExecute = "echo '${base64encode(local.weather_bootstrap_script_lf)}' | base64 -d > /tmp/readit-weather-bootstrap.sh && chmod 700 /tmp/readit-weather-bootstrap.sh && /bin/bash /tmp/readit-weather-bootstrap.sh"
  })

  tags = local.common_tags
}


