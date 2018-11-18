variable "name" {
  description = "Name of the cluster to create"
  type        = "string"
}

variable "vpc_config" {
  description = "VPC configuration as object"
  type        = "map"
}

variable "kops_state" {
  description = "S3 URL of the kops state bucket to use"
  type        = "string"
}

variable "ssh_public_key" {
  description = "SSH public key to use for node access"
  type        = "string"
}

variable "ssh_access" {
  description = "List of CIDR blocks that have SSH access to the cluster"
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "api_access" {
  description = "List of CIDR blocks that have API access to the cluster"
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "cluster_config" {
  default = {}
}

variable "update_cluster" {
  description = "If set to true, any changes to the cluster will be applied immediately. If set to false, you need to run `kops update cluster` yourself."
  default     = false
}
