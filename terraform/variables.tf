variable "project_id" {
  type    = string
}
variable "region" {
  type    = string
}

variable "zone" {
  type    = string
}

variable "network_name" {
  type    = string
  default = "vpc-livekit"
}
variable "subnet_name" {
  type    = string
  default = "subnet-livekit"
}
variable "subnet_cidr" {
  type    = string
  default = "10.20.0.0/20"
}

variable "pods_range_name" {
  type    = string
  default = "pods-range"
}
variable "pods_range_cidr" {
  type    = string
  default = "10.40.0.0/14"
}
variable "svc_range_name" {
  type    = string
  default = "services-range"
}
variable "svc_range_cidr" {
  type    = string
  default = "10.60.0.0/20"
}

variable "cluster_name" {
  type    = string
  default = "gke-livekit"
}

variable "reserve_static_ips" {
  type    = bool
  default = true
}
variable "envoy_ip_name" {
  type    = string
  default = "envoy-ip"
}

variable "cert_manager_version" {
  type    = string
  default = "v1.15.1"
}
variable "envoy_gateway_version" {
  type    = string
  default = "v1.5.3"
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}
