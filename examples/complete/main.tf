################################################################################
# Complete Example — tf-label
#
# Demonstrates all features: chaining, label_order, descriptor_formats,
# id_length_limit, tenant, and case control.
################################################################################

module "label1" {
  source = "../../"

  namespace   = "Acme"
  tenant      = "client-a"
  environment = "us-west-2"
  stage       = "prod"
  name        = "Platform API"
  attributes  = ["v2", "public"]

  label_order = ["namespace", "tenant", "environment", "stage", "name", "attributes"]

  tags = {
    BusinessUnit = "Engineering"
    CostCenter   = "CC-1234"
  }

  descriptor_formats = {
    stack = {
      format = "%s/%s/%s"
      labels = ["namespace", "environment", "stage"]
    }
    s3_bucket = {
      format = "%s-%s-%s-assets"
      labels = ["namespace", "stage", "name"]
    }
  }
}

# Chained module inheriting from label1
module "label2" {
  source = "../../"

  name       = "worker"
  attributes = ["queue"]
  stage      = "staging"

  context = module.label1.context
}

# Demonstrate id_length_limit with sha256 hash truncation
module "label3" {
  source = "../../"

  namespace       = "acme"
  environment     = "production"
  stage           = "release"
  name            = "my-very-long-microservice-name"
  attributes      = ["primary", "east"]
  id_length_limit = 32

  context = module.label1.context
}

# Demonstrate disabled module
module "label4_disabled" {
  source = "../../"

  enabled = false
  context = module.label1.context
}

# Demonstrate labels_as_tags control
module "label5" {
  source = "../../"

  name           = "database"
  labels_as_tags = ["namespace", "stage", "name"]

  context = module.label1.context
}

# Demonstrate case control
module "label6_upper" {
  source = "../../"

  name             = "cache"
  label_value_case = "upper"
  label_key_case   = "lower"

  context = module.label1.context
}

module "label7_pascal" {
  source = "../../"

  name             = "web app"
  delimiter        = ""
  label_value_case = "title"

  context = module.label1.context
}
