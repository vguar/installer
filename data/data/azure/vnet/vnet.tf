locals {
  vnet_name = "${azurerm_virtual_network.new_vnet.name}"
}

resource "azurerm_virtual_network" "new_vnet" {
  name                = "${var.cluster_id}-vnet"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.region}"
  address_space       = ["${var.vnet_cidr}"]
}

resource "azurerm_route_table" "route_table" {
  name                = "${var.cluster_id}-route-table"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  tags = "${merge(map(
    "Name", "${var.cluster_id}-route-table",
  ), var.tags)}"
}

resource "azurerm_subnet" "master_subnet" {
  resource_group_name  = "${var.resource_group_name}"
  address_prefix       = "${var.master_subnet_cidr}"
  virtual_network_name = "${local.vnet_name}"
  name                 = "${var.cluster_id}-subnet"
}
