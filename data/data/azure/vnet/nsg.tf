resource "azurerm_network_security_group" "master" {
  name                = "${var.cluster_id}-master-nsg"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  tags = "${merge(map(
    "Name", "${var.cluster_id}-master-nsg",
  ), var.tags)}"
}

resource "azurerm_subnet_network_security_group_association" "master" {
  subnet_id                 = "${azurerm_subnet.master_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.master.id}"
}

