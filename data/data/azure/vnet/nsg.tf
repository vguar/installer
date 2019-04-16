resource "azurerm_network_security_group" "master" {
  name                = "${var.cluster_id}-controlplane-nsg"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet_network_security_group_association" "master" {
  subnet_id                 = "${azurerm_subnet.master_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.master.id}"
}

resource "azurerm_network_security_group" "worker" {
  name                = "${var.cluster_id}-node-nsg"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet_network_security_group_association" "worker" {
  subnet_id                 = "${azurerm_subnet.node_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.worker.id}"
}
