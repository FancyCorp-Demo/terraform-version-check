terraform {
  cloud {
    organization = "fancycorp"

    workspaces {
      tags = ["admin"]
    }
  }
}

module "versions" {
  source = "hashi-strawb/workspace-version-check/tfe"
}

output "workspaces_with_old_versions" {
  value = module.versions.workspaces_with_old_versions
}
output "workspaces_and_versions" {
  value = module.versions.workspaces_and_versions
}
output "num_workspaces_with_old_versions" {
  value = module.versions.num_workspaces_with_old_versions
}
