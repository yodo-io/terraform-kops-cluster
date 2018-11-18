variable "kubeconfig" {
  type    = "string"
  default = "~/.kube/config"
}

variable "bin_kubectl" {
  default = "kubectl"
}

variable "bin_helm" {
  default = "helm"
}
