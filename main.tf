terraform {
  cloud {
    organization = "fancycorp"

    workspaces {
      name = "admin-updates"
    }
  }
}



#
# Get Latest TF Version
#

data "http" "checkpoint-terraform" {
  url = "https://checkpoint-api.hashicorp.com/v1/check/terraform"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

locals {
  latest_version = jsondecode(data.http.checkpoint-terraform.response_body).current_version
}

output "latest_version" {
  value = local.latest_version
}



#
# List all Workspaces
#


variable "tfc_org" {
  default = "fancycorp"
}


data "tfe_workspace_ids" "all" {
  names        = ["*"]
  organization = var.tfc_org
}



data "tfe_workspace" "workspace" {
  for_each = data.tfe_workspace_ids.all.ids

  name         = each.key
  organization = var.tfc_org
}



#
# List all workspaces which do not use the latest TF Version
#


locals {
  workspaces_and_versions = {
    for k, v in data.tfe_workspace.workspace :
    k => v.terraform_version
  }

  workspaces_with_old_versions = {
    for k, v in data.tfe_workspace.workspace :
    k => v.terraform_version if
    v.terraform_version != local.latest_version
  }

  num_workspaces = length(keys(local.workspaces_with_old_versions))

  workspace_names = join("\n\t -", keys(local.workspaces_with_old_versions))
}



output "ws" {
  value = local.workspaces_with_old_versions
}
output "num" {
  value = local.num_workspaces
}



#
# Assert that there are no workspaces using old versions
#


resource "null_resource" "assert" {
  lifecycle {
    precondition {
      condition     = local.num_workspaces == 0
      error_message = "Detected workspaces with old Terraform:\n\t- ${local.workspace_names}"
    }
  }
}
