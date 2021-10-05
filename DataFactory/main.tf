terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.78.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Create a resource group
resource "azurerm_resource_group" "sds-rg01-dev-eastus" {
  name     = "sds-rg01-dev-eastus"
  location = "East  US"

  tags = {
    "environment"      = "dev"
  }

}

# -- --
# Key Vault
# -- --
resource "azurerm_key_vault" "sds-kv01-dev-eastus" {
  name                = "sds-kv01-dev-eastus"
  location            = azurerm_resource_group.sds-rg01-dev-eastus.location
  resource_group_name = azurerm_resource_group.sds-rg01-dev-eastus.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  tags = {
    "environment"      = "dev"
  }

}

# Key Vault Access Policy del creador el key Vault (Cliente).
resource "azurerm_key_vault_access_policy" "sds-kvap01-dev-eastus" {
  key_vault_id = azurerm_key_vault.sds-kv01-dev-eastus.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    # Key Management Operations
    "get",
    "list",
    "update",
    "create",
    "import",
    "delete",
    "recover",
    "backup",
    "restore",
    ## Cryptographic Operations
    # "decrypt",
    # "encrypt",
    # "unwrapKey",
    # "wrapKey",
    # "verify",
    # "sign",
    ## Privileged Key Operations
    # "purge",
  ]

  secret_permissions = [
    ## Secret Management Operations
    "get",
    "list",
    "set",
    "delete",
    "recover",
    "backup",
    "restore",
    ## Privileged Secret Operations
    # "purge",
  ]

  certificate_permissions = [
    ## Certificate Management Operations
    "get",
    "list",
    "update",
    "create",
    "import",
    "delete",
    "recover",
    "backup",
    "restore",
    "managecontacts",
    "manageissuers",
    "getissuers",
    "listissuers",
    "setissuers",
    "deleteissuers",
    ## Privileged Certificate Operations
    # "purge",
  ]

}

# -- --
# Storage Account
# El nombre solo permite minusculas y numeros | sds-st01-dev-eastus => sdsst01deveastus
# -- --
resource "azurerm_storage_account" "sdsst01deveastus" {
  name                     = "sdsst01deveastus"
  resource_group_name      = azurerm_resource_group.sds-rg01-dev-eastus.name
  location                 = azurerm_resource_group.sds-rg01-dev-eastus.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }

}

# Container - Data Lake Store
resource "azurerm_storage_container" "sds-dls01-dev-eastus" {
  name                  = "sds-dls01-dev-eastus"
  storage_account_name  = azurerm_storage_account.sdsst01deveastus.name
  container_access_type = "private"
}

# Secreto - connection string de storage container en Key Vault
resource "azurerm_key_vault_secret" "sds-sect01-dev-connection-string-st01" {
  name         = "sds-sect01-dev-connection-string-st01"
  value        = azurerm_storage_account.sdsst01deveastus.primary_connection_string
  key_vault_id = azurerm_key_vault.sds-kv01-dev-eastus.id
}

# -- --
# eee
# -- --
