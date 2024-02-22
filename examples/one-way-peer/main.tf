terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  min = 0
  max = length(module.regions.regions) - 1
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "vnet1-rg" {
  name     = module.naming.resource_group.name_unique
  location = module.regions.regions[random_integer.region_index.result].name
}

resource "azurerm_resource_group" "vnet2-rg" {
  name     = module.naming.resource_group.name_unique
  location = module.regions.regions[random_integer.region_index.result].name
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.

locals {
  subnets = {
    for i in range(3) : "subnet${i}" => {
      address_prefixes = [cidrsubnet(local.virtual_network_address_space, 8, i)]
    }
  }
  virtual_network_address_space = "10.0.0.0/16"

}

# Creating a virtual network
resource "azurerm_virtual_network" "example1" {
  name                = "example-network1"
  location            = azurerm_resource_group.vnet1-rg.location
  resource_group_name = azurerm_resource_group.vnet1-rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_virtual_network" "example2" {
  name                = "example-network2"
  location            = azurerm_resource_group.vnet2-rg.location
  resource_group_name = azurerm_resource_group.vnet2-rg.name
  address_space       = ["192.0.0.0/24"]

}

module "vnet_peering" {
  resource_group_name = azurerm_resource_group.vnet2-rg.name
  source              = "../../"
  virtual_networks = {
    vnet1_to_vnet2 = {
      hub_resource_id         = "/subscriptions/47d02a61-9001-41bd-b4e7-6be9289027f4/resourceGroups/rg-hfdx/providers/Microsoft.Network/virtualNetworks/example-network1"
      spoke_resource_id       = "/subscriptions/47d02a61-9001-41bd-b4e7-6be9289027f4/resourceGroups/rg-hfdx/providers/Microsoft.Network/virtualNetworks/example-network2"
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  }

  subscription_ids = [
    "47d02a61-9001-41bd-b4e7-6be9289027f4",
    "47d02a61-9001-41bd-b4e7-6be9289027f4"
  ]

  peering_direction = "one_way"
}

 