locals {
  tags = "${merge(map(
    "kubernetes.io_cluster.${var.cluster_id}", "owned"
  ), var.azure_extra_tags)}"

  master_subnet_cidr = "${cidrsubnet(var.machine_cidr, 3, 0)}"    #master subnet is a smaller subnet within the new subnet. i.e from /21 to /24
  bootstrap_ip       = "${cidrhost(local.master_subnet_cidr, 4)}" #azure reserves the 3 first ips in a subnet, so we start at 4
}

provider "azurerm" {
  # version = "~>1.5"
}

module "bootstrap" {
  source              = "./bootstrap"
  resource_group_name = "${azurerm_resource_group.main.name}"
  region              = "${var.azure_region}"
  vm_size             = "${var.azure_bootstrap_vm_type}"

  cluster_id              = "${var.cluster_id}"
  ignition                = "${var.ignition_bootstrap}"
  subnet_id               = "${module.vnet.public_subnet_id}"
  elb_backend_pool_id     = "${module.vnet.elb_backend_pool_id}"
  ilb_backend_pool_id     = "${module.vnet.ilb_backend_pool_id}"
  tags                    = "${local.tags}"
  boot_diag_blob_endpoint = "${azurerm_storage_account.bootdiag.primary_blob_endpoint}"
  ip_address              = "${local.bootstrap_ip}"
}

module "vnet" {
  source              = "./vnet"
  resource_group_name = "${azurerm_resource_group.main.name}"
  vnet_cidr           = "${var.machine_cidr}"
  master_subnet_cidr  = "${local.master_subnet_cidr}"
  cluster_id          = "${var.cluster_id}"
  region              = "${var.azure_region}"
  dns_label           = "${var.cluster_id}"
  tags                = "${local.tags}"
}

module "master" {
  source                  = "./master"
  resource_group_name     = "${azurerm_resource_group.main.name}"
  cluster_id              = "${var.cluster_id}"
  region                  = "${var.azure_region}"
  vm_size                 = "${var.azure_master_vm_type}"
  ignition                = "${var.ignition_master}"
  external_lb_id          = "${module.vnet.external_lb_id}"
  elb_backend_pool_id     = "${module.vnet.elb_backend_pool_id}"
  ilb_backend_pool_id     = "${module.vnet.ilb_backend_pool_id}"
  subnet_id               = "${module.vnet.public_subnet_id}"
  master_subnet_cidr      = "${local.master_subnet_cidr}"
  instance_count          = "${var.master_count}"
  tags                    = "${local.tags}"
  boot_diag_blob_endpoint = "${azurerm_storage_account.bootdiag.primary_blob_endpoint}"
  os_volume_size          = "${var.azure_master_root_volume_size}"
}

module "dns" {
  source                          = "./dns"
  cluster_domain                  = "${var.cluster_domain}"
  base_domain                     = "${var.base_domain}"
  external_lb_fqdn                = "${module.vnet.external_lb_pip_fqdn}"
  internal_lb_ipaddress           = "${module.vnet.internal_lb_ip_address}"
  resource_group_name             = "${azurerm_resource_group.main.name}"
  base_domain_resource_group_name = "${var.azure_base_domain_resource_group_name}"
  internal_dns_resolution_vnet_id = "${module.vnet.vnet_id}"
  etcd_count                      = "${var.master_count}"
  etcd_ip_addresses               = "${module.master.ip_addresses}"
}

resource "random_string" "resource_group_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = "${var.cluster_id}-rg"
  location = "${var.azure_region}"
}

resource "azurerm_storage_account" "bootdiag" {
  name                     = "bootdiagmasters${random_string.resource_group_suffix.result}"
  resource_group_name      = "${azurerm_resource_group.main.name}"
  location                 = "${var.azure_region}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
