terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.116" }
    random   = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "azurerm" { features {} }

data "azurerm_shared_image_version" "runner" {
  name                    = var.runner_image_version
  image_gallery_name      = var.image_gallery_name
  resource_group_name     = var.image_resource_group_name
  gallery_image_name      = var.gallery_image_name
}

resource "azurerm_resource_group" "runners" {
  name     = var.resource_group_name
  location = var.location
}

module "vmss" {
  source = "./modules/vmss"
  
  resource_group_name = azurerm_resource_group.runners.name
  location            = var.location
  subnet_id           = var.subnet_id
  
  runner_image_id     = data.azurerm_shared_image_version.runner.id
  ghes_url            = var.ghes_url
  ghes_token          = var.ghes_runner_token
  runner_vm_size      = var.runner_vm_size
  runner_min_count    = var.runner_min_count
  runner_max_count    = var.runner_max_count
}
