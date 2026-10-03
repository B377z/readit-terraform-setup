locals {
  catalog_bootstrap_script = <<-POWERSHELL
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "SilentlyContinue"

    Write-Output "Installing IIS..."
    Install-WindowsFeature Web-Server -IncludeManagementTools

    $installer = Join-Path $env:TEMP "dotnet-hosting-8.exe"

    Write-Output "Downloading the .NET 8 Hosting Bundle..."
    Invoke-WebRequest `
      -Uri "https://aka.ms/dotnet/8.0/dotnet-hosting-win.exe" `
      -OutFile $installer `
      -UseBasicParsing

    Write-Output "Installing the .NET 8 Hosting Bundle..."
    $process = Start-Process `
      -FilePath $installer `
      -ArgumentList "/install", "/quiet", "/norestart" `
      -Wait `
      -PassThru

    if ($process.ExitCode -notin @(0, 3010)) {
      throw "The .NET Hosting Bundle installation failed with exit code $($process.ExitCode)."
    }

    Remove-Item $installer -Force -ErrorAction SilentlyContinue

    Set-Service W3SVC -StartupType Automatic
    Start-Service W3SVC

    & "$env:SystemRoot\System32\iisreset.exe"

    Write-Output "Catalog VM bootstrap completed successfully."
  POWERSHELL
}

resource "azurerm_public_ip" "catalog" {
  count = var.deploy_catalog_vm ? 1 : 0

  name                = "pip-${var.application_name}-catalog-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_network_interface" "catalog" {
  count               = var.deploy_catalog_vm ? 1 : 0
  name                = "nic-${var.application_name}-catalog-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig-catalog"
    subnet_id                     = azurerm_subnet.catalog.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.4"
    public_ip_address_id          = azurerm_public_ip.catalog[0].id
  }

  tags = local.common_tags
}

resource "azurerm_windows_virtual_machine" "catalog" {
  count               = var.deploy_catalog_vm ? 1 : 0
  name                = "vm-${var.application_name}-catalog-${var.environment_name}"
  computer_name       = "catalog-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  network_interface_ids = [
    azurerm_network_interface.catalog[0].id
  ]
  size           = var.catalog_vm_size
  admin_username = var.catalog_admin_username
  admin_password = var.catalog_admin_password

  patch_mode          = "AutomaticByOS"
  secure_boot_enabled = true
  vtpm_enabled        = true

  os_disk {
    name                 = "osdisk-${var.application_name}-catalog-${var.environment_name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "windowsserver2022"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

}

resource "azurerm_virtual_machine_extension" "catalog_bootstrap" {
  count = var.deploy_catalog_vm ? 1 : 0

  name                       = "catalog-bootstrap"
  virtual_machine_id         = azurerm_windows_virtual_machine.catalog[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(local.catalog_bootstrap_script, "UTF-16LE")}"
  })

  tags = local.common_tags
}
