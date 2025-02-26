variable "master" {}
variable "permissions" {}


locals {
    # Get each posssible user
    user_list = [for k,v in var.permissions.iam_groups_users[*].user: "${v}"]
    # Get each possible Group
    group_list = distinct(flatten([for k,v in var.permissions.iam_groups_users[*].groups: "${v}"]))
    #flatten the variables and map each group to each user
    user_group_flat=[for k, v in var.permissions.iam_groups_users:{for k1,v1 in v.groups: k1 =>{"group" = v1, "user" = v.user} } ]
    user_group_map=merge([for k,v in local.user_group_flat : { for v1 in v :"${k}-${v1.group}" => v1 }]...) 

    # Policies
    #list of each policy to create
    policy_list = [for k,v in var.permissions.iam_policies[*].name: "${v}"]
    #flatten the variables and map each group to each policy
    policy_group_flat=[for k, v in var.permissions.iam_policies:{for k1,v1 in v.groups: k1 =>{"group" = v1, "name" = v.name} } ]
    policy_group_map=merge([for k,v in local.policy_group_flat : { for v1 in v :"${k}-${v1.group}" => v1 }]...) 
    #flatten the variables and map each group to each aws policy
    aws_policy_group_flat=[for k, v in var.permissions.iam_aws_policies:{for k1,v1 in v.policies: k1 =>{"policy" = v1, "group" = v.group} } ]
    aws_policy_group_map=merge([for k,v in local.aws_policy_group_flat : { for v1 in v :"${k}-${v1.policy}" => v1 }]...) 



    # Roles
    #flatten the variables and map each role to each policy
    role_policy_flat=[for k, v in var.permissions.iam_roles:{for k1,v1 in v.aws_policies: k1 =>{"policy" = v1, "name" = v.name} } ]
    role_policy_map=merge([for k,v in local.role_policy_flat : { for v1 in v :"${k}-${v1.policy}" => v1 }]...) 




 }
 #call the name of the owner for use later
 data "aws_caller_identity" "current" {}

####################################################################################################
# Users and Groups
####################################################################################################
#Create user accounts
resource "aws_iam_user" "user_accounts" {
  for_each = { for k, v in local.user_list : k => v if var.permissions.iam_groups_users_enabled }
  name     = "${each.value}-${var.master.convention}"
}
#create groups
resource "aws_iam_group" "iam_groups" {
  for_each = { for k, v in local.group_list : k => v if var.permissions.iam_groups_users_enabled } 
  name = "${var.master.convention}-${each.value}"
  path = "/"
}
#Assign users to groups
resource "aws_iam_user_group_membership" "group_members" {
  for_each = { for k, v in local.user_group_map : k => v if var.permissions.iam_groups_users_enabled } 
  groups = ["${var.master.convention}-${each.value.group}"]
  user   = "${each.value.user}-${var.master.convention}"
  depends_on = [  aws_iam_group.iam_groups, aws_iam_user.user_accounts]
}



####################################################################################################
# Policies create and attatch to groups
####################################################################################################
#create local policies
resource "aws_iam_policy" "create_policies" {
  for_each = { for k, v in local.policy_list : k => v if var.permissions.iam_policies_enabled }
  name        = "${var.master.convention}-${each.value}"
  path        = "/"
  description = "${var.master.convention}-${each.value}-policy"
  policy = file("../configs/policies/${each.value}.json")
}

#Attatch local policies to groups
resource "aws_iam_group_policy_attachment" "group_policy_attach" {
  for_each = { for k, v in local.policy_group_map : k => v if var.permissions.iam_policies_enabled } 
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.master.convention}-${each.value.name}"
  group = "${var.master.convention}-${each.value.group}"
  depends_on = [ aws_iam_policy.create_policies, aws_iam_group.iam_groups ]
}
#Attatch aws policies to groups
resource "aws_iam_group_policy_attachment" "group_aws_policy_attach" {
  for_each = { for k, v in local.aws_policy_group_map : k => v if var.permissions.iam_aws_policies_enabled } 
  policy_arn = "arn:aws:iam::aws:policy/${each.value.policy}"
  group = "${var.master.convention}-${each.value.group}"
  depends_on = [ aws_iam_group.iam_groups ]
}

####################################################################################################
# Roles
####################################################################################################
#create local roles
resource "aws_iam_role" "create_roles" {
  for_each = { for k, v in local.role_policy_map : k => v if var.permissions.iam_roles_enabled }
  name        = "${var.master.convention}-${each.value.name}"
  path        = "/"
  description = "${var.master.convention}-${each.value.name}-role"
  assume_role_policy = file("../configs/roles/${each.value.name}.json")
}

resource "aws_iam_role_policy_attachment" "role_policy_attach" {
  for_each = { for k, v in local.role_policy_map : k => v if var.permissions.iam_roles_enabled }
  role       = aws_iam_role.create_roles[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/${each.value.policy}"
}

