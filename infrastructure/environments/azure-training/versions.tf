terraform {
  required_version = ">= 1.13.0, < 2.0.0"
  backend "azurerm" {}
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.11.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7"
    }
  }
}

provider "azapi" {
  enable_preflight = true
}

provider "azurerm" {
  features {}
}
