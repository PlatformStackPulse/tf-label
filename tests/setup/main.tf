################################################################################
# Test Scenario Inputs — shared across all test runs
# This file is used by terraform test (.tftest.hcl) to exercise the module
################################################################################

# Scenario 1: Basic ID generation
module "basic" {
  source = "../../"

  namespace = "eg"
  stage     = "prod"
  name      = "bastion"
}

# Scenario 2: Full labels with all elements
module "full" {
  source = "../../"

  namespace   = "eg"
  tenant      = "client1"
  environment = "uw2"
  stage       = "prod"
  name        = "app"
  attributes  = ["public", "v2"]
}

# Scenario 3: Custom delimiter
module "custom_delimiter" {
  source = "../../"

  namespace = "eg"
  stage     = "prod"
  name      = "app"
  delimiter = "."
}

# Scenario 4: Custom label order
module "custom_order" {
  source = "../../"

  namespace   = "eg"
  environment = "uw2"
  stage       = "prod"
  name        = "app"
  label_order = ["name", "namespace", "stage"]
}

# Scenario 5: Upper case values
module "upper_case" {
  source = "../../"

  namespace        = "eg"
  stage            = "prod"
  name             = "app"
  label_value_case = "upper"
}

# Scenario 6: Title case values (Pascal Case with no delimiter)
module "pascal_case" {
  source = "../../"

  namespace        = "eg"
  stage            = "prod"
  name             = "my app"
  delimiter        = ""
  label_value_case = "title"
}

# Scenario 7: No case transformation
module "no_case" {
  source = "../../"

  namespace        = "EG"
  stage            = "Prod"
  name             = "App"
  label_value_case = "none"
}

# Scenario 8: ID length limit (triggers truncation + hash)
module "truncated" {
  source = "../../"

  namespace       = "acme"
  environment     = "production"
  stage           = "release"
  name            = "my-very-long-service"
  attributes      = ["primary"]
  id_length_limit = 24
}

# Scenario 9: Disabled module
module "disabled" {
  source = "../../"

  enabled   = false
  namespace = "eg"
  stage     = "prod"
  name      = "app"
}

# Scenario 10: Regex replace chars
module "regex_chars" {
  source = "../../"

  namespace           = "eg"
  stage               = "prod"
  name                = "app@v2!"
  regex_replace_chars = "/[^a-zA-Z0-9-]/"
}

# Scenario 11: Chaining via context
module "parent" {
  source = "../../"

  namespace   = "acme"
  environment = "uw2"
  stage       = "prod"
  name        = "platform"

  tags = {
    ManagedBy = "Terraform"
  }
}

module "child" {
  source = "../../"

  name       = "worker"
  attributes = ["queue"]

  context = module.parent.context
}

# Scenario 12: Tags generation with label_key_case
module "tags_lower_key" {
  source = "../../"

  namespace      = "eg"
  stage          = "prod"
  name           = "app"
  label_key_case = "lower"
}

# Scenario 13: Tags generation with label_key_case upper
module "tags_upper_key" {
  source = "../../"

  namespace      = "eg"
  stage          = "prod"
  name           = "app"
  label_key_case = "upper"
}

# Scenario 14: Selective labels_as_tags
module "selective_tags" {
  source = "../../"

  namespace      = "eg"
  environment    = "uw2"
  stage          = "prod"
  name           = "app"
  labels_as_tags = ["namespace", "stage", "name"]
}

# Scenario 15: Empty labels_as_tags (no generated tags)
module "no_gen_tags" {
  source = "../../"

  namespace      = "eg"
  stage          = "prod"
  name           = "app"
  labels_as_tags = []

  tags = {
    Custom = "tag"
  }
}

# Scenario 16: Attributes only in ID
module "attrs_only" {
  source = "../../"

  name       = "service"
  attributes = ["a", "b", "c"]
}

# Scenario 17: Tenant in label_order
module "with_tenant_order" {
  source = "../../"

  namespace   = "eg"
  tenant      = "t1"
  environment = "uw2"
  stage       = "prod"
  name        = "app"
  label_order = ["namespace", "tenant", "environment", "stage", "name", "attributes"]
}

# Scenario 18: Descriptor formats
module "descriptors" {
  source = "../../"

  namespace   = "acme"
  environment = "uw2"
  stage       = "prod"
  name        = "api"

  descriptor_formats = {
    stack = {
      format = "%s/%s/%s"
      labels = ["namespace", "environment", "stage"]
    }
    qualified = {
      format = "%s::%s"
      labels = ["namespace", "name"]
    }
  }
}

################################################################################
# Outputs for comparison
################################################################################

output "basic_id" {
  value = module.basic.id
}

output "full_id" {
  value = module.full.id
}

output "full_tags" {
  value = module.full.tags
}

output "custom_delimiter_id" {
  value = module.custom_delimiter.id
}

output "custom_order_id" {
  value = module.custom_order.id
}

output "upper_case_id" {
  value = module.upper_case.id
}

output "pascal_case_id" {
  value = module.pascal_case.id
}

output "no_case_id" {
  value = module.no_case.id
}

output "truncated_id" {
  value = module.truncated.id
}

output "truncated_id_full" {
  value = module.truncated.id_full
}

output "disabled_id" {
  value = module.disabled.id
}

output "disabled_enabled" {
  value = module.disabled.enabled
}

output "disabled_tags" {
  value = module.disabled.tags
}

output "regex_chars_id" {
  value = module.regex_chars.id
}

output "child_id" {
  value = module.child.id
}

output "child_tags" {
  value = module.child.tags
}

output "tags_lower_key" {
  value = module.tags_lower_key.tags
}

output "tags_upper_key" {
  value = module.tags_upper_key.tags
}

output "selective_tags" {
  value = module.selective_tags.tags
}

output "no_gen_tags" {
  value = module.no_gen_tags.tags
}

output "attrs_only_id" {
  value = module.attrs_only.id
}

output "with_tenant_order_id" {
  value = module.with_tenant_order.id
}

output "descriptors" {
  value = module.descriptors.descriptors
}
