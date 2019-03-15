
resource "random_string" "storage_suffix" {
  length = 5
  upper = false
  special = false
  keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${var.resource_group_name}"
    }
}

resource "azurerm_storage_account" "ignition" {
  name = "ignitiondata${random_string.storage_suffix.result}"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.region}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "ignition" {
  resource_group_name   = "${var.resource_group_name}"
  name                  = "ignition"
  storage_account_name  = "${azurerm_storage_account.ignition.name}"
  container_access_type = "private"
}

resource "local_file" "ignition_bootstrap" {
    content     = "${var.ignition}"
    filename = "${path.module}/ignition_bootstrap.ign"
}

resource "azurerm_storage_blob" "ignition" {

  name                    = "bootstrap.ign"
  source                  = "${local_file.ignition_bootstrap.filename}"
  resource_group_name     = "${var.resource_group_name}"
  storage_account_name    = "${azurerm_storage_account.ignition.name}"
  storage_container_name  = "${azurerm_storage_container.ignition.name}"
  type = "block"
}

data "ignition_config" "redirect" {
  replace {
    source = "${azurerm_storage_blob.ignition.url}"
  }
}

data "azurerm_subscription" "primary" {}

resource "azurerm_network_interface" "ignition" {
  name                = "${var.cluster_id}-bootstrap-nic"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    subnet_id                               = "${var.subnet_id}"
    name                                    = "bootstrap"
    private_ip_address_allocation           = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "ignition" {
  network_interface_id = "${azurerm_network_interface.ignition.id}"
  backend_address_pool_id = "${var.elb_backend_pool_id}"
  ip_configuration_name = "bootstrap" #must be the same as nic's ip configuration name.
}

resource "azurerm_network_interface_nat_rule_association" "ignition" {
  network_interface_id  = "${azurerm_network_interface.ignition.id}"
  ip_configuration_name = "bootstrap"
  nat_rule_id           = "${var.elb_bootstrap_ssh_natrule_id}"
}

resource "azurerm_virtual_machine" "bootstrap" {
  name                  = "${var.cluster_id}-bootstrap"
  location              = "${var.region}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.ignition.id}"]
  vm_size               = "${var.vm_size}"

  delete_os_disk_on_termination = true
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 100
  }

  storage_image_reference {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "Beta"
    version   = "latest"
  }

  #  lifecycle {
  #   # Ignore changes in the AMI which force recreation of the resource. This
  #   # avoids accidental deletion of nodes whenever a new OS release comes out.
  #   ignore_changes = ["ami"]
  # }

  os_profile {
    computer_name  = "${var.cluster_id}-bootstrap-vm"
    admin_username = "king"
    admin_password = "P@ssword1234!"
    custom_data = "${data.ignition_config.redirect.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled = true
    storage_uri = "${var.boot_diag_blob_endpoint}"
  }

  tags = "${merge(map(
    "Name", "${var.cluster_id}-bootstrap",
  ), var.tags)}"

}

// TODO :
// LB?
// Public IP
// NSG for SSH (tcp 22) + Journald gateway (tcp 19531)
// TESTS :)

