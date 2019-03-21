variable "tags" {
  type        = "map"
  default     = {}
  description = "AWS tags to be applied to created resources."
}

variable "cluster_domain" {
  description = "The domain for the cluster that all DNS records must belong"
  type        = "string"
}

variable "api_external_lb_dns_name" {
  description = "External API's LB DNS name"
  type        = "string"
}

variable "api_internal_lb_dns_name" {
  description = "External API's LB DNS name"
  type        = "string"
}

variable "resource_group_name" {
  type = "string"
  description = "Resource group for the deployment"
}

