variable "kubeconfig" {
  type    = "string"
  default = "~/.kube/config"
}

variable "tiller_namespace" {
  description = "Kube namespace to deploy the default Tiller deployment into"
  default     = "kube-system"
}

variable "tiller_history_max" {
  default = 5
}

variable "tiller_version" {
  default = "v2.8.2"
}
