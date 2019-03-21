resource "azurerm_dns_zone" "private" {
  name                = "${var.cluster_domain}"
  resource_group_name = "${var.resource_group_name}"
  zone_type           = "Private"
}

resource "azurerm_dns_zone" "public" {
  name                = "${var.cluster_domain}"
  resource_group_name = "${var.resource_group_name}"
  zone_type           = "Public"
}

resource "azurerm_dns_cname_record" "api_internal" {
  name                = "api"
  zone_name           = "${azurerm_dns_zone.private.name}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  record              = "${var.api_internal_lb_dns_name}"
}

resource "azurerm_dns_a_record" "api_external" {
  name                = "api"
  zone_name           = "${azurerm_dns_zone.public.name}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  record              = "${var.api_external_lb_dns_name}"
}