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
    environment      = "dev"
    project          = "sds"
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
    environment      = "dev"
    project          = "sds"
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
    environment   = "dev"
    project       = "sds"
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

  tags = {
    environment   = "dev"
    project       = "sds"
  }

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

# -- --
# Azure Data Factory
# -- --
resource "azurerm_data_factory" "sds-adf01-dev-eastus" {
  name                = "sds-adf01-dev-eastus"
  location            = azurerm_resource_group.sds-rg01-dev-eastus.location
  resource_group_name = azurerm_resource_group.sds-rg01-dev-eastus.name

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment   = "dev"
    project       = "sds"
  }

}

# access policy del Data Factory
resource "azurerm_key_vault_access_policy" "sds-kvap01-dev-eastus" {
  depends_on   = [azurerm_data_factory.sds-adf01-dev-eastus]
  key_vault_id = azurerm_key_vault.sds-kv02-dev-eastus.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_data_factory.sds-adf01-dev-eastus.identity.0.principal_id

  secret_permissions = [
    "get",
    "list",
  ]
}


# linked service key vault
resource "azurerm_data_factory_linked_service_key_vault" "sds-lskv01-dev-eastus-to-kvault" {
  name                = "sds-lskv01-dev-eastus-to-kvault"
  resource_group_name = azurerm_resource_group.sds-rg01-dev-eastus.name
  data_factory_name   = azurerm_data_factory.sds-adf01-dev-eastus.name
  key_vault_id        = azurerm_key_vault.sds-kv02-dev-eastus.id
}

# linked service azure to blob storage
resource "azurerm_data_factory_linked_service_azure_blob_storage" "sds-lser01-dev-eastus-to-st02" {
  name                = "sds-lser01-dev-eastus-to-st02"
  resource_group_name = azurerm_resource_group.sds-rg01-dev-eastus.name
  data_factory_name   = azurerm_data_factory.sds-adf01-dev-eastus.name

  sas_uri = "https://storageaccountname.blob.core.windows.net"
  key_vault_sas_token {
    linked_service_name = azurerm_data_factory_linked_service_key_vault.sds-lskv01-dev-eastus-to-kvault.name
    secret_name         = "sds-sect01-dev-connection-string-st01"
  }
}

# linked service azure to sql database
# resource "azurerm_data_factory_linked_service_sql_server" "sds-lser02-dev-eastus-to-sql01" {
#   name                = "sds-lser02-dev-eastus-to-sql01"
#   resource_group_name = azurerm_resource_group.sds-rg01-dev-eastus.name
#   data_factory_name   = azurerm_data_factory.sds-adf01-dev-eastus.name

#   connection_string = "Integrated Security=False;Data Source=test;Initial Catalog=test;User ID=test;"
#   key_vault_password {
#     linked_service_name = azurerm_data_factory_linked_service_key_vault.sds-lskv01-dev-eastus-to-kvault.name
#     secret_name         = "secret"
#   }

# }
