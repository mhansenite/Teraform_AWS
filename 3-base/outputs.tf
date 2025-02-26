# output user_list {
#   value = module.iam.user_list
# }
# output group_list {
#   value = module.iam.group_list
# }

# output  user_group_flat {
#   value = module.iam.user_group_flat
# }

# output user_group_map {
#   value = module.iam.user_group_map
#   }

# output policy_group_list {
#   value = module.iam.policy_list
# }

# output  policy_group_flat {
#   value = module.iam.policy_group_flat
# }

# output policy_group_map {
#   value = module.iam.policy_group_map
#   }
# output role_policy_flat {
#   value = module.iam.role_policy_flat
#   }
# output role_policy_map {
#   value = module.iam.role_policy_map
#   }

output "vpc_resources" {
      value = { for k, v in module.vpcs.vpc_resources : k => v.id }
}
# # output "vpc_map" {
# #   value= module.vpcs.vpc_map
# # }

output "subnet_set" {
    value = module.vpcs.subnet_set
}  
# output "subnet_build" {
#     value = module.vpcs.subnet_build
# }  


# output "subnet_flat" {
#     value = module.vpcs.subnet_flat
# }
output "subnet_resources" {
  value = { for k, v in module.vpcs.subnet_resources : k => v.id }
}
output "working" {
    value = module.vpcs.working 
  
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_target_group_arn" {
  value = module.alb.target_group_arn
}

output "security_group_ids" {
  value = module.security.security_group_ids
}
