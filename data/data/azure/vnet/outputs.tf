output "vnet_id" {
  value = "${local.vnet_id}"
}

output "cluster-pip" {
  value = "${azurerm_public_ip.cluster_public_ip.ip_address}"
}

output "public_subnet_id" {
  value = "${local.subnet_ids}"
}

output "elb_backend_pool_id" {
  value = "${local.elb_backend_pool_id}"
}

output "ilb_backend_pool_id" {
  value = "${local.ilb_backend_pool_id}"
}

output "external_lb_id" {
  value = "${local.external_lb_id}"
}

output "external_lb_pip_fqdn" {
  value = "${data.azurerm_public_ip.cluster_public_ip.fqdn}"
}

output "internal_lb_ip_address" {
  value = "${azurerm_lb.internal.private_ip_address}"
}

output "master_nsg_id" {
  value = "${azurerm_network_security_group.master.id}"
}
