output "label1" {
  value = {
    id          = module.label1.id
    id_full     = module.label1.id_full
    namespace   = module.label1.namespace
    tenant      = module.label1.tenant
    environment = module.label1.environment
    stage       = module.label1.stage
    name        = module.label1.name
    attributes  = module.label1.attributes
    delimiter   = module.label1.delimiter
    tags        = module.label1.tags
    descriptors = module.label1.descriptors
  }
}

output "label2" {
  value = {
    id          = module.label2.id
    id_full     = module.label2.id_full
    namespace   = module.label2.namespace
    tenant      = module.label2.tenant
    environment = module.label2.environment
    stage       = module.label2.stage
    name        = module.label2.name
    attributes  = module.label2.attributes
    tags        = module.label2.tags
  }
}

output "label3_truncated" {
  value = {
    id      = module.label3.id
    id_full = module.label3.id_full
  }
}

output "label4_disabled" {
  value = {
    id      = module.label4_disabled.id
    enabled = module.label4_disabled.enabled
    tags    = module.label4_disabled.tags
  }
}

output "label5_selective_tags" {
  value = {
    id   = module.label5.id
    tags = module.label5.tags
  }
}

output "label6_upper" {
  value = {
    id   = module.label6_upper.id
    tags = module.label6_upper.tags
  }
}

output "label7_pascal" {
  value = {
    id   = module.label7_pascal.id
    tags = module.label7_pascal.tags
  }
}
