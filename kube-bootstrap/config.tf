provider "kubernetes" {
  config_path = "${var.kubeconfig}"
  version     = "~> 1.3"
}
