terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.44.1"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "aws" {
    region = "enterhere"
    access_key = "enterhere"
    secret_key = "enterhere"
}
