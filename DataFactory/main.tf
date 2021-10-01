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
resource "azurerm_resource_group" "rg-sdssandbox-dev-eastUS-001" {
  name     = "rg-sdssandbox-dev-eastUS-001"
  location = "East  US"
}
# -- --
# Key Vault
# -- --
resource "azurerm_key_vault" "kv-sdssandbox-dev" {
  name                = "kv-sdssandbox-dev"
  location            = azurerm_resource_group.rg-sdssandbox-dev-eastUS-001.location
  resource_group_name = azurerm_resource_group.rg-sdssandbox-dev-eastUS-001.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  tags = {
    "environment"      = "dev"
  }

}

# Key Vault Access Policy del creador el key Vault (Cliente).
resource "azurerm_key_vault_access_policy" "kvap-sdssandbox-dev-client" {
  key_vault_id = azurerm_key_vault.kv-sdssandbox-dev.id
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
    # Cryptographic Operations
    # "decrypt",
    # "encrypt",
    # "unwrapKey",
    # "wrapKey",
    # "verify",
    # "sign",
    # Privileged Key Operations
    # "purge",
  ]

  secret_permissions = [
    # Secret Management Operations
    "get",
    "list",
    "set",
    "delete",
    "recover",
    "backup",
    "restore",
    # Privileged Secret Operations
    # "purge",
  ]

  certificate_permissions = [
    # Certificate Management Operations
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
    # Privileged Certificate Operations
    # "purge",
  ]

}

# -- --
# Storage Account
# El nombre solo permite minusculas y numeros | st-sdssandbox-dev
# -- --
resource "azurerm_storage_account" "stsdssandboxdev" {
  name                     = "stsdssandboxdev"
  resource_group_name      = azurerm_resource_group.rg-sdssandbox-dev-eastUS-001.name
  location                 = azurerm_resource_group.rg-sdssandbox-dev-eastUS-001.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }

}

# Container
resource "azurerm_storage_container" "dls-sdssandbox-dev-empleados-fuente" {
  name                  = "dls-sdssandbox-dev-empleados-fuente"
  storage_account_name  = azurerm_storage_account.stsdssandboxdev.name
  container_access_type = "private"
}

# access policy del storage container
resource "azurerm_key_vault_access_policy" "kvap-sdssandbox-dev-storage-container" {
  key_vault_id = azurerm_key_vault.kv-sdssandbox-dev.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_storage_account.stsdssandboxdev.identity.0.principal_id

  secret_permissions = [
    "get",
    "list",
  ]
}


# -- --
# eee
# -- --
