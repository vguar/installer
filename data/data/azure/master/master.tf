resource "azurerm_network_interface" "master" {
  count               = "${var.instance_count}"
  name                = "${var.cluster_id}-master-nic-${count.index}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    subnet_id                     = "${var.subnet_id}"
    name                          = "master-${count.index}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "master" {
  count                   = "${var.instance_count}"
  network_interface_id    = "${element(azurerm_network_interface.master.*.id, count.index)}"
  backend_address_pool_id = "${var.elb_backend_pool_id}"
  ip_configuration_name   = "master-${count.index}"                                          #must be the same as nic's ip configuration name.
}

resource "azurerm_network_interface_backend_address_pool_association" "master_internal" {
  count                   = "${var.instance_count}"
  network_interface_id    = "${element(azurerm_network_interface.master.*.id, count.index)}"
  backend_address_pool_id = "${var.ilb_backend_pool_id}"
  ip_configuration_name   = "master-${count.index}"                                          #must be the same as nic's ip configuration name.
}

#TODO : make FD/UD configurable
resource "azurerm_availability_set" "master" {
  name                         = "mater-as"
  location                     = "${var.region}"
  resource_group_name          = "${var.resource_group_name}"
  managed                      = true
  platform_update_domain_count = 5
  platform_fault_domain_count  = 3                            # the available fault domain number depends on the region, so this needs to be configurable or dynamic
}

resource "azurerm_virtual_machine" "master" {
  count                 = "${var.instance_count}"
  name                  = "${var.cluster_id}-master-${count.index}"
  location              = "${var.region}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.master.*.id, count.index)}"]
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${azurerm_availability_set.master.id}"

  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "masterosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "${var.os_volume_size}"
  }

  storage_image_reference {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "Alpha"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.cluster_id}-bootstrap-vm"
    admin_username = "king"
    admin_password = "P@ssword1234!"
    custom_data    = "${var.ignition}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${var.boot_diag_blob_endpoint}"
  }

  tags = "${merge(map(
    "Name", "${var.cluster_id}-master",
  ), var.tags)}"
}
