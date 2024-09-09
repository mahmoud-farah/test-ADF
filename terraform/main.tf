provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "prod" {
  name     = "prod-resources"
  location = "West Europe"  
}

resource "azurerm_data_factory" "prod_adf" {
  name                = "prod-adf"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
}
