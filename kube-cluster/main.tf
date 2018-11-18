locals = {
  cluster_config = "${merge(local.default_cluster_config, var.cluster_config)}"

  cluster_values = {
    vpc_config     = "${var.vpc_config}"
    cluster_name   = "${var.name}"
    cluster_config = "${local.cluster_config}"
    kops_state     = "${var.kops_state}"
    ssh_access     = "[${join(",", var.ssh_access)}]"
    api_access     = "[${join(",", var.api_access)}]"
  }

  cluster_values_json = "${jsonencode(local.cluster_values)}"
  cluster_template    = "${path.module}/resources/cluster-template.yaml"

  out_dir          = "${path.module}/.generated"
  out_cluster_spec = "${local.out_dir}/cluster.yaml"
  out_kubeconfig   = "${local.out_dir}/kubeconfig"

  kops_env = {
    KOPS_CLUSTER_NAME  = "${var.name}"
    KOPS_STATE_STORE   = "s3://${var.kops_state}"
    AWS_DEFAULT_REGION = "ap-southeast-1"
  }
}

# TODO: using local exec we can't keep track of the actual resource state and we can't delete 
# the cluster. We should implement a custom provider to have this functionality

# Can't create a dir directly, but if we create a file it will create all parent dirs
resource "local_file" "out_dir" {
  filename = "${local.out_dir}/_"
  content  = ""
}

# Render cluster template
resource "null_resource" "cluster_spec" {
  depends_on = ["local_file.out_dir"]

  triggers = {
    cluster_template = "${data.local_file.cluster_template.content}"
    cluster_values   = "${local.cluster_values_json}"
    cluster_name     = "${var.name}"
    kops_state       = "${var.kops_state}"
  }

  provisioner "local-exec" {
    command     = "kops toolbox template --values=<( echo '${local.cluster_values_json}') --template=${local.cluster_template} --format-yaml > ${local.out_cluster_spec}"
    interpreter = ["bash", "-c"]
    environment = "${local.kops_env}"
  }
}

data "local_file" "cluster_template" {
  filename = "${local.cluster_template}"
}

# Set cluster
resource "null_resource" "replace_cluster" {
  depends_on = ["null_resource.cluster_spec"]

  # Can't set a trigger based on the rendered template because data sources aren't evaluated for tf plan
  # Cluster spec only depends the template and values, so we can trigger based on those two
  triggers = {
    cluster_template = "${data.local_file.cluster_template.content}"
    cluster_values   = "${local.cluster_values_json}"
    cluster_name     = "${var.name}"
    kops_state       = "${var.kops_state}"
  }

  provisioner "local-exec" {
    command     = "kops replace --force -f ${local.out_cluster_spec}"
    interpreter = ["bash", "-c"]
    environment = "${local.kops_env}"
  }
}

# This secret must exist and be called `admin` and kops _will_ create a new EC2 keypair from it,
# even if a keypair with the same public key already exists
resource "null_resource" "ssh_public_key" {
  depends_on = ["null_resource.replace_cluster"]

  triggers = {
    cluster_values = "${base64encode(local.cluster_values_json)}"
    public_key     = "${var.ssh_public_key}"
    cluster_name   = "${var.name}"
    kops_state     = "${var.kops_state}"
  }

  provisioner "local-exec" {
    command     = "kops create secret sshpublickey admin -i <( echo '${var.ssh_public_key}')"
    interpreter = ["bash", "-c"]
    environment = "${local.kops_env}"
  }
}

# Update cluster if requested. If var.update_cluster is false (default) we skip this step and the user
# is responsible to run kops update cluster and optionally generate the matching Terraform configs.
resource "null_resource" "update_cluster" {
  count      = "${var.update_cluster}"
  depends_on = ["null_resource.replace_cluster"]

  triggers = {
    cluster_template = "${data.local_file.cluster_template.content}"
    cluster_values   = "${local.cluster_values_json}"
    cluster_name     = "${var.name}"
    kops_state       = "${var.kops_state}"
  }

  provisioner "local-exec" {
    command     = "kops update cluster --yes"
    interpreter = ["bash", "-c"]
    environment = "${local.kops_env}"
  }
}

# FIXME: after the cluster has been created there seems to be a slight delay before we can export the 
# kube config for it - we need to figure out what to wait for an include that in a wrapper script (or 
# terraform provider)
resource "null_resource" "kube_config" {
  count      = "${var.update_cluster}"
  depends_on = ["null_resource.replace_cluster"]

  triggers = {
    cluster_name = "${var.name}"
    kops_state   = "${var.kops_state}"
  }

  provisioner "local-exec" {
    command     = "kops export kubecfg"
    environment = "${merge(local.kops_env, map("KUBECONFIG", "${local.out_kubeconfig}"))}"
  }
}

# In case the user set `update_cluster` to false, we generate a shell script that allows manual cluster 
# update and kube config generation. It's also useful for troubleshooting, so we generated it in any case
resource "local_file" "cluster_update_script" {
  depends_on = ["null_resource.replace_cluster"]
  filename   = "${path.module}/update-cluster.sh"

  content = <<EOF
export KOPS_CLUSTER_NAME="${var.name}"
export KOPS_STATE_STORE="s3://${var.kops_state}"
export KUBECONFIG="${local.out_kubeconfig}"

kops update cluster --yes
kops export kubecfg

EOF
}

# If we were a Terraform provider, we could use it to delete the cluster the proper way, for now just 
# generate a script to do it.
resource "local_file" "cluster_delete_script" {
  depends_on = ["null_resource.replace_cluster"]
  filename   = "${path.module}/delete-cluster.sh"

  content = <<EOF
export KOPS_CLUSTER_NAME="${var.name}"
export KOPS_STATE_STORE="s3://${var.kops_state}"
export KUBECONFIG="${local.out_kubeconfig}"

kops delete cluster --yes

EOF
}
