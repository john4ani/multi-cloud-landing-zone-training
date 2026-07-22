terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.11.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
