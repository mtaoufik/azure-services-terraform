# ----------------------------------------
# Azure Hub-Spoke Topology with On-Premise Connectivity and Virtual Appliance
# ----------------------------------------

# Define the provider
provider "azurerm" {
  features {}
}

# Variables
variable "resource_group_name" {
  default = "HubSpokeResourceGroup"
}

variable "location" {
  default = "EastUS"
}

variable "hub_vnet_address_prefix" {
  default = "10.0.0.0/16"
}

variable "spoke_vnet_address_prefix" {
  default = "10.1.0.0/16"
}

variable "onpremise_address_prefix" {
  default = "192.168.0.0/16"
}

variable "jump_vm_username" {
  default = "adminuser"
}

variable "jump_vm_password" {
  default = "YourPassword123!"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Hub Virtual Network
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "HubVNet"
  address_space       = [var.hub_vnet_address_prefix]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Hub Gateway Subnet
resource "azurerm_subnet" "hub_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Hub Jump Subnet
resource "azurerm_subnet" "hub_jump_subnet" {
  name                 = "JumpSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Spoke Virtual Network
resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "SpokeVNet"
  address_space       = [var.spoke_vnet_address_prefix]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Spoke Subnet
resource "azurerm_subnet" "spoke_subnet" {
  name                 = "SpokeSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Virtual Network Peering: Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "HubToSpoke"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

# Virtual Network Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "SpokeToHub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
  use_remote_gateways       = true
}

# Public IP for Virtual Network Gateway
resource "azurerm_public_ip" "vpn_gateway_ip" {
  name                = "VPNGatewayPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Standard"
}

# Virtual Network Gateway for Hub
resource "azurerm_virtual_network_gateway" "hub_vpn_gateway" {
  name                = "HubVPNGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = "GatewayIPConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub_gateway_subnet.id
  }
}

# Local Network Gateway (On-Premise)
resource "azurerm_local_network_gateway" "onpremise_gateway" {
  name                = "OnPremiseGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  gateway_address     = "203.0.113.1" # Replace with on-premise gateway public IP
  address_space       = [var.onpremise_address_prefix]
}

# Connection between Hub and On-Premise
resource "azurerm_virtual_network_gateway_connection" "hub_to_onpremise" {
  name                = "HubToOnPremiseConnection"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  type                = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub_vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.onpremise_gateway.id
  shared_key          = "YourSharedKey123" # Replace with a secure shared key
}

# Jump Server Network Interface
resource "azurerm_network_interface" "jump_server_nic" {
  name                = "JumpServerNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "JumpServerIPConfig"
    subnet_id                     = azurerm_subnet.hub_jump_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Jump Server VM
resource "azurerm_windows_virtual_machine" "jump_server" {
  name                  = "JumpServer"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B2ms"
  admin_username        = var.jump_vm_username
  admin_password        = var.jump_vm_password
  network_interface_ids = [azurerm_network_interface.jump_server_nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
