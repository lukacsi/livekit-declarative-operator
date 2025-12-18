provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host  = "https://${google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.primary.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      google_container_cluster.primary.master_auth[0].cluster_ca_certificate
    )
  }
}

resource "google_container_cluster" "primary" {
  name     = "szakdoga"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-node-pool"
  location = var.zone
  cluster  = google_container_cluster.primary.name

  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }

  node_config {
    machine_type = "e2-standard-4"

    disk_size_gb = 60
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_compute_address" "envoy" {
  count        = var.reserve_static_ips ? 1 : 0
  name         = var.envoy_ip_name
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# resource "kubernetes_namespace_v1" "cert_manager" {
#   metadata { name = "cert-manager" }
#   depends_on = [google_container_node_pool.primary_nodes]
# }
# resource "kubernetes_namespace_v1" "stunner" {
#   metadata { name = "stunner" }
#   depends_on = [google_container_node_pool.primary_nodes]

# }
# resource "kubernetes_namespace_v1" "egw" {
#   metadata { name = "envoy-gateway-system" }
#   depends_on = [google_container_node_pool.primary_nodes]
# }

# CERT MANAGER
# resource "helm_release" "cert_manager" {
#   name       = "cert-manager"
#   namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"
#   version    = var.cert_manager_version
#   timeout    = 600

#   set {
#     name  = "crds.enabled"
#     value = true
#   }
#   set {
#     name  = "global.leaderElection.namespace"
#     value = "cert-manager"
#   }
# }

# resource "kubernetes_secret_v1" "cloudflare" {
#   count = var.cloudflare_api_token == "" ? 0 : 1
#   metadata {
#     name      = "cloudflare-api-token-secret"
#     namespace = "cert-manager"
#   }
#   data       = { "api-token" = var.cloudflare_api_token }
#   depends_on = [helm_release.cert_manager]
# }

# # STUNNER
# resource "helm_release" "stunner" {
#   name       = "stunner"
#   namespace  = kubernetes_namespace_v1.stunner.metadata[0].name
#   repository = "https://l7mp.io/stunner/"
#   chart      = "stunner"
# }

# # ENVOY GATEWAY
# resource "helm_release" "envoy_gateway" {
#   name      = "eg"
#   namespace = kubernetes_namespace_v1.egw.metadata[0].name
#   chart     = "oci://docker.io/envoyproxy/gateway-helm"
#   version   = var.envoy_gateway_version
# }

# # DCONTROLLER
# resource "helm_release" "dcontroller" {
#   name       = "dcontroller"
#   namespace  = "default"
#   repository = "https://l7mp.github.io/dcontroller/"
#   chart      = "dcontroller"
# }

output "kubectl_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}
