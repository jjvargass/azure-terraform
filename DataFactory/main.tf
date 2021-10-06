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
resource "azurerm_key_vault" "sds-kv02-dev-eastus" {
  name                = "sds-kv02-dev-eastus"
  location            = azurerm_resource_group.sds-rg01-dev-eastus.location
  resource_group_name = azurerm_resource_group.sds-rg01-dev-eastus.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  tags = {
    "environment"      = "dev"
  }

  access_policy {
    tenant_id    = data.azurerm_client_config.current.tenant_id
    object_id    = data.azurerm_client_config.current.object_id

    key_permissions = [
      # -Key Management Operations
      "Get",
      "List",
      "Update",
      "Create",
      "Import",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      # -Cryptographic Operations
      # "Decrypt",
      # "Encrypt",
      # "UnwrapKey",
      # "WrapKey",
      # "Verify",
      # "Sign",
      # -Privileged Key Operations
      # "Purge",
    ]

    secret_permissions = [
      # -Secret Management Operations
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      # -Privileged Secret Operations
      "Purge",
    ]

    certificate_permissions = [
      # -Certificate Management Operations
      "Get",
      "List",
      "Update",
      "Create",
      "Import",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "ManageContacts",
      "ManageIssuers",
      "GetIssuers",
      "ListIssuers",
      "SetIssuers",
      "DeleteIssuers",
      # -Privileged Certificate Operations
      # "Purge",
    ]
  }
}

# -- --
# Storage Account
# El nombre solo permite minusculas y numeros | sds-st01-dev-eastus => sdsst02deveastus
# -- --
resource "azurerm_storage_account" "sdsst02deveastus" {
  name                     = "sdsst02deveastus"
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
  storage_account_name  = azurerm_storage_account.sdsst02deveastus.name
  container_access_type = "private"
}

# Secreto - connection string de storage container en Key Vault
resource "azurerm_key_vault_secret" "sds-sect01-dev-connection-string-st01" {
  name         = "sds-sect01-dev-connection-string-st01"
  value        = azurerm_storage_account.sdsst02deveastus.primary_connection_string
  key_vault_id = azurerm_key_vault.sds-kv02-dev-eastus.id
}

# -- --
# Azure SQL Database
# -- --
resource "azurerm_sql_server" "sds-sql01-dev-eastus" {
  name                         = "sds-sql01-dev-eastus"
  resource_group_name          = azurerm_resource_group.sds-rg01-dev-eastus.name
  location                     = azurerm_resource_group.sds-rg01-dev-eastus.location
  version                      = "12.0"
  administrator_login          = var.user_sql01
  administrator_login_password = var.pass_sql01

  tags = {
    environment   = "dev"
    project       = "sds"
  }
}

# sdsstdb02deveastus storage account de bd
resource "azurerm_storage_account" "sdsstdb02deveastus" {
  name                     = "sdsstdb02deveastus"
  resource_group_name      = azurerm_resource_group.sds-rg01-dev-eastus.name
  location                 = azurerm_resource_group.sds-rg01-dev-eastus.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_sql_database" "sds-sqldb01-dev-eastus" {
  name                = "sds-sqldb01-dev-eastus"
  resource_group_name = azurerm_resource_group.sds-rg01-dev-eastus.name
  location            = azurerm_resource_group.sds-rg01-dev-eastus.location
  server_name         = azurerm_sql_server.sds-sql01-dev-eastus.name

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.sdsstdb02deveastus.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.sdsstdb02deveastus.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }

  tags = {
    environment   = "dev"
    project       = "sds"
  }
}