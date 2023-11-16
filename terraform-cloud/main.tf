# Copyright (c) HashiCorp, Inc.

terraform {
  required_providers {
    tfe = {
      version = "~> 0.38.0"
    }
  }
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Obtain name of the target organization from the particpant.
**** **** **** **** **** **** **** **** **** **** **** ****/

data "tfe_organization" "org" {
  name = var.tfc_organization
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 
 * DEPRECATED *
 
 Configure workspace with local execution mode so that plans 
 and applies occur on this workstation. And, Terraform Cloud 
 is only used to store and synchronize state. 

 * DEPRECATED *

**** **** **** **** **** **** **** **** **** **** **** ****/

# resource "tfe_workspace" "hashicat" {
#   name           = var.tfc_workspace
#   organization   = data.tfe_organization.org.name
#   tag_names      = var.tfc_workspace_tags
#   execution_mode = "local"
# }

/**** **** **** **** **** **** **** **** **** **** **** ****

 * DEPRECATED *

 Configure workspace with REMOTE execution mode so that plans 
 and applies occur on Terraform Cloud's infrastructure. 
 Terraform Cloud exectures code and stores state. 

* DEPRECATED *

**** **** **** **** **** **** **** **** **** **** **** ****/

# resource "tfe_workspace" "hashicat" {
#   name           = var.tfc_workspace
#   organization   = data.tfe_organization.org.name
#   tag_names      = var.tfc_workspace_tags
#   execution_mode = "remote"
# }

/**** **** **** **** **** **** **** **** **** **** **** ****

 * DEPRECATED *

 Configure workspace with REMOTE execution mode so that plans 
 and applies occur on Terraform Cloud's infrastructure. 
 Terraform Cloud exectures code and stores state. 

* DEPRECATED *

**** **** **** **** **** **** **** **** **** **** **** ****/

# resource "tfe_workspace" "hashicat" {
#   name         = var.tfc_workspace
#   organization = data.tfe_organization.org.name
#   tag_names    = ["hashicat", "CLOUD_ENV"]
#   auto_apply   = true

#   vcs_repo {
#     identifier     = "${var.github_organization}/${var.github_repo}"
#     oauth_token_id = tfe_oauth_client.github.oauth_token_id
#   }
# }

/**** **** **** **** **** **** **** **** **** **** **** ****
 Configure workspace with REMOTE execution mode so that plans 
 and applies occur on Terraform Cloud's infrastructure. 
 Terraform Cloud exectures code and stores state.

 We are removing the VCS configuration so that GitHub Actions
 can trigger remote work.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_workspace" "hashicat" {
  name         = var.tfc_workspace
  organization = data.tfe_organization.org.name
  tag_names    = var.tfc_workspace_tags
  auto_apply   = true
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Configure organization-wide variables with Variables sets
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_variable_set" "hashicat" {
  name         = "Cloud Credentials"
  description  = "Dedicated Principal Account for Terraform Deployments"
  organization = data.tfe_organization.org.name
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Assing the Variables set to the hashicat workspace
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_workspace_variable_set" "hashicat" {
  variable_set_id = tfe_variable_set.hashicat.id
  workspace_id    = tfe_workspace.hashicat.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Add GOOGLE_CREDENTIALS to the Cloud Credentials variable set
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_variable" "google_cloud_credentials" {
  key             = "GOOGLE_CREDENTIALS"
  value           = var.google_credentials
  category        = "env"
  description     = "Google Credentials"
  variable_set_id = tfe_variable_set.hashicat.id
  sensitive       = true
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Add Google Cloud project ID to the Cloud Credentials variable set
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_variable" "google_cloud_project" {
  key             = "project"
  value           = var.project
  category        = "terraform"
  description     = "Google Cloud project ID"
  variable_set_id = tfe_variable_set.hashicat.id
  sensitive       = false
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Add PREFIX to the hashicat workspace variables
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_variable" "prefix" {
  key          = "prefix"
  value        = var.prefix
  category     = "terraform"
  description  = "Hashicat deployment prefix"
  workspace_id = tfe_workspace.hashicat.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Add REGION to the hashicat workspace variables
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_variable" "region" {
  key          = "region"
  value        = var.region
  category     = "terraform"
  description  = "Cloud region"
  workspace_id = tfe_workspace.hashicat.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Set up ADMINS team with the following permissions:

   * Manage policies 
   * Manage policy overrides
   * Workspaces
   * VCS settings
   * Run tasks
   * Private registry

**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_team" "admins" {
  name         = "admins"
  organization = data.tfe_organization.org.name
  organization_access {
    manage_policies         = true
    manage_policy_overrides = true
    manage_workspaces       = true
    manage_vcs_settings     = true
    manage_run_tasks        = true
    manage_providers        = true // Allows members to publish and delete modules in the organization's private registry.
    manage_modules          = true // Allows members to publish and delete modules in the organization's private registry.
  }
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Set up DEVELOPERS team without any organization-wide access.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_team" "developers" {
  name         = "developers"
  organization = data.tfe_organization.org.name
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Set up MANAGERS team without any organization-wide access.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_team" "managers" {
  name         = "managers"
  organization = data.tfe_organization.org.name
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Associate the ADMINS team to permissions on the hashicat
 workspace with the ADMIN access grants. Admin permissions
 provide Full control of the workspace:

  * All permissions of write
  * Manage team access
  * Delete workspace
  * VCS configuration
  * Execution mode
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_team_access" "admins" {
  access       = "admin"
  team_id      = tfe_team.admins.id
  workspace_id = tfe_workspace.hashicat.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Associate the DEVELOPERS team to permissions on the hashicat
 workspace with the WRITE access grants. Read permissions are:

  * All permissions of plan
  
    -- All permissions of read
    -- Create runs
    -- Add run comments

  * Can read and write
  * Approve runs
  * Lock/unlock workspace
  * Access to state
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_team_access" "developers" {
  access       = "write"
  team_id      = tfe_team.developers.id
  workspace_id = tfe_workspace.hashicat.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Associate the MANAGERS team to permissions on the hashicat
 workspace with the READ access grants. Baseline permissions 
for reading a workspace are:

  * Read runs
  * Read variables
  * Read TF config versions
  * Read workspace information
  * Read state
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_team_access" "managers" {
  access       = "read"
  team_id      = tfe_team.managers.id
  workspace_id = tfe_workspace.hashicat.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Invite LARS, AISHA and HIRO to the organization
**** **** **** **** **** **** **** **** **** **** **** ****/

locals {
  all_users = setunion(var.admins, var.developers, var.managers)
}

resource "tfe_organization_membership" "all_users" {
  for_each = local.all_users

  organization = data.tfe_organization.org.name
  email        = each.value
}

# /**** **** **** **** **** **** **** **** **** **** **** ****
#  Add LARS to the ADMIN team - workshops+lars@hashicorp.com
# **** **** **** **** **** **** **** **** **** **** **** ****/

# resource "tfe_team_members" "admins" {
#   team_id   = tfe_team.admins.id
#   usernames = ["demo-lars"]
# }

# /**** **** **** **** **** **** **** **** **** **** **** ****
#  Add AISHA to the DEVELOPERS team - workshops+aisha@hashicorp.com
# **** **** **** **** **** **** **** **** **** **** **** ****/

# resource "tfe_team_members" "developers" {
#   team_id   = tfe_team.developers.id
#   usernames = ["demo-aisha"]
# }

# /**** **** **** **** **** **** **** **** **** **** **** ****
#  Add HIRO to the MANAGERS - workshops+hiro@hashicorp.com
# **** **** **** **** **** **** **** **** **** **** **** ****/

# resource "tfe_team_members" "managers" {
#   team_id   = tfe_team.managers.id
#   usernames = ["demo-hiro"]
# }

/**** **** **** **** **** **** **** **** **** **** **** ****
 An OAuth Client represents the connection between an 
 organization and a VCS provider.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_oauth_client" "github" {
  name             = var.oauth_connection_name
  organization     = data.tfe_organization.org.name
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  oauth_token      = var.github_token
  service_provider = "github"
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Add a collection of policies to enhance the governance rules
 to support business rules and security guidelines.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_policy_set" "test" {
  name          = "Hashicat-Social"
  description   = "Policies for HashiCat Social"
  organization  = data.tfe_organization.org.name
  policies_path = "/policies"
  workspace_ids = [tfe_workspace.hashicat.id]

  vcs_repo {
    identifier         = "${var.github_organization}/${var.github_repo}"
    branch             = "main"
    ingress_submodules = false
    oauth_token_id     = tfe_oauth_client.github.oauth_token_id
  }
}

/**** **** **** **** **** **** **** **** **** **** **** ****
 Specifies the Terraform provider for our deployment. 
 For example: "aws_s3", "Azure Blob Storage", or "Google Cloud
 Storage" modules in the public Terraform Registry.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tfe_registry_module" "google-cloud-storage" {
  vcs_repo {
    display_identifier = "${var.github_organization}/${var.module_repo}"
    identifier         = "${var.github_organization}/${var.module_repo}"
    oauth_token_id     = tfe_oauth_client.github.oauth_token_id
  }
}
