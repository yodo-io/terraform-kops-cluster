# Tiller service account
resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "${var.tiller_namespace}"

    labels = {
      "k8s-addon" = "tiller.addons.k8s.io"
    }
  }
}

# Cluster role binding - cluster-admin/tiller SA
resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller"

    labels = {
      "k8s-addon" = "tiller.addons.k8s.io"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    api_group = ""
  }
}

# Deployment
resource "kubernetes_deployment" "tiller" {
  count = 0

  metadata {
    name      = "tiller-deploy"
    namespace = "${var.tiller_namespace}"

    labels = {
      "k8s-addon" = "tiller.addons.k8s.io"
      "app"       = "helm"
      "name"      = "tiller"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels {
        "app"  = "helm"
        "name" = "tiller"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = 1
        max_unavailable = 1
      }
    }

    template {
      metadata {
        labels = {
          "app"  = "helm"
          "name" = "tiller"
        }
      }

      spec {
        dns_policy           = "ClusterFirst"
        service_account_name = "tiller"

        container {
          name              = "tiller"
          command           = ["/tiller"]
          args              = ["-listen=localhost:44134"]
          image             = "gcr.io/kubernetes-helm/tiller:${var.tiller_version}"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "TILLER_NAMESPACE"
            value = "${var.tiller_namespace}"
          }

          env {
            name  = "TILLER_HISTORY_MAX"
            value = "${var.tiller_history_max}"
          }

          liveness_probe {
            failure_threshold     = 3
            initial_delay_seconds = 30
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 1

            http_get {
              path   = "/liveness"
              port   = "44135"
              scheme = "HTTP"
            }
          }

          readiness_probe {
            failure_threshold     = 3
            initial_delay_seconds = 30
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 1

            http_get {
              path   = "/liveness"
              port   = "44135"
              scheme = "HTTP"
            }
          }
        }
      }
    }
  }
}
