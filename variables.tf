variable "admin_source_cidr" {
  description = "Public IPV4 CIDR permitted to administer sandbox resources"
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_source_cidr, 0))
    error_message = "The admin_source_cidr must be a valid public IPv4 CIDR."
  }
}

variable "application_name" {
  type = string
}

variable "deploy_catalog_vm" {
  description = "Deploy the ReadIt Catalog Windows VM"
  type        = bool
  default     = false
}

variable "catalog_vm_size" {
  description = "Azure VM size for the Catalog server"
  type        = string
  default     = "Standard_B2s"
}

variable "catalog_admin_username" {
  description = "Local administrator username for the Catalog VM"
  type        = string
  default     = "azureadminuser"
}

variable "catalog_admin_password" {
  description = "Local administrator password for the Catalog VM"
  type        = string
  sensitive   = true
  default     = null
  nullable    = true

  validation {
    condition = var.deploy_catalog_vm ? (
      var.catalog_admin_password != null ?
      length(var.catalog_admin_password) >= 12 : false
    ) : true

    error_message = "A password of at least 12 characters is required when deploy_catalog_vm is true."
  }
}

variable "deploy_weather_vm" {
  description = "Deploy the ReadIt Weather Windows VM"
  type        = bool
  default     = false
}

variable "weather_vm_size" {
  description = "Azure VM size for the Weather server"
  type        = string
  default     = "Standard_B1s"
}

variable "weather_admin_username" {
  description = "Administrator username for the Weather VM"
  type        = string
  default     = "azureadminuser"
}

variable "weather_ssh_public_key" {
  description = "SSH public key for the Weather VM"
  type        = string
  sensitive   = true
  default     = null
  nullable    = true

  validation {
    condition = var.deploy_weather_vm ? (
      var.weather_ssh_public_key != null ?
      startswith(var.weather_ssh_public_key, "ssh-") : false
    ) : true
    error_message = "A valid SSH public key is required when deploy_weather_vm is true."
  }
}

variable "environment_name" {
  type = string
}
variable "primary_location" {
  type = string
}

variable "tags" {
  description = "Tags applied to ReadIt resources"
  type        = map(string)

  default = {
    Application = "ReadIt"
    ManagedBy   = "Terraform"
    Purpose     = "Learning"
  }
}

variable "deploy_inventory_app_service" {
  description = "Deploy the ReadIt Inventory App Service"
  type        = bool
  default     = false
}

variable "inventory_app_service_sku" {
  description = "SKU for the Inventory App Sevice Plan"
  type        = string
  default     = "S1"
}

variable "deploy_inventory_private_endpoint" {
  description = "Deploy the Inventory App Service private endpoint"
  type        = bool
  default     = false

  validation {
    condition = (
      !var.deploy_inventory_private_endpoint ||
      var.deploy_inventory_app_service
    )

    error_message = "Inventory App Service must be enabled before its private endpoint."
  }
}
