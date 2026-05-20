################################################################################
# tf-null-label — Modern Terraform Naming & Tagging Module
#
# Modernized rewrite of cloudposse/terraform-null-label leveraging:
#   - optional() object attributes (Terraform 1.3+)
#   - Native null handling (no more sentinel values)
#   - sha256() instead of md5() for truncation hashing
#   - Removed deprecated tags_as_list_of_maps / additional_tag_map
#   - Proper type constraints throughout
#   - Simplified merging logic
################################################################################

locals {
  ############################################################################
  # Defaults — single source of truth for fallback values
  ############################################################################
  defaults = {
    label_order         = ["namespace", "environment", "stage", "name", "attributes"]
    regex_replace_chars = "/[^-a-zA-Z0-9]/"
    delimiter           = "-"
    replacement         = ""
    id_length_limit     = 0
    id_hash_length      = 5
    label_key_case      = "title"
    label_value_case    = "lower"
  }

  ############################################################################
  # Input Resolution — Variables override context; attributes & tags merge
  ############################################################################
  input = {
    enabled             = var.enabled != null ? var.enabled : var.context.enabled
    namespace           = var.namespace != null ? var.namespace : var.context.namespace
    tenant              = var.tenant != null ? var.tenant : var.context.tenant
    environment         = var.environment != null ? var.environment : var.context.environment
    stage               = var.stage != null ? var.stage : var.context.stage
    name                = var.name != null ? var.name : var.context.name
    delimiter           = var.delimiter != null ? var.delimiter : var.context.delimiter
    attributes          = compact(distinct(concat(coalesce(var.context.attributes, []), coalesce(var.attributes, []))))
    tags                = merge(coalesce(var.context.tags, {}), coalesce(var.tags, {}))
    label_order         = var.label_order != null ? var.label_order : var.context.label_order
    regex_replace_chars = var.regex_replace_chars != null ? var.regex_replace_chars : var.context.regex_replace_chars
    id_length_limit     = var.id_length_limit != null ? var.id_length_limit : var.context.id_length_limit
    label_key_case      = var.label_key_case != null ? var.label_key_case : var.context.label_key_case
    label_value_case    = var.label_value_case != null ? var.label_value_case : var.context.label_value_case
    labels_as_tags      = var.labels_as_tags != null ? var.labels_as_tags : var.context.labels_as_tags
    descriptor_formats  = merge(coalesce(var.context.descriptor_formats, {}), coalesce(var.descriptor_formats, {}))
  }

  ############################################################################
  # Resolved values with defaults applied
  # Note: delimiter uses explicit null check because "" is a valid value
  # that coalesce() would incorrectly skip (it treats "" as falsy).
  ############################################################################
  enabled             = local.input.enabled
  regex_replace_chars = coalesce(local.input.regex_replace_chars, local.defaults.regex_replace_chars)
  delimiter           = local.input.delimiter != null ? local.input.delimiter : local.defaults.delimiter
  label_order         = coalesce(local.input.label_order, local.defaults.label_order)
  id_length_limit     = coalesce(local.input.id_length_limit, local.defaults.id_length_limit)
  label_key_case      = coalesce(local.input.label_key_case, local.defaults.label_key_case)
  label_value_case    = coalesce(local.input.label_value_case, local.defaults.label_value_case)
  id_hash_length      = local.defaults.id_hash_length
  replacement         = local.defaults.replacement

  # labels_as_tags: null means "all labels" (the default)
  labels_as_tags = local.input.labels_as_tags != null ? local.input.labels_as_tags : toset(keys(local.tags_context))

  ############################################################################
  # Label Normalization
  ############################################################################
  string_label_names = ["namespace", "tenant", "environment", "stage", "name"]

  normalized_labels = { for k in local.string_label_names : k =>
    local.input[k] == null ? "" : replace(local.input[k], local.regex_replace_chars, local.replacement)
  }

  normalized_attributes = compact(distinct([
    for v in local.input.attributes : replace(v, local.regex_replace_chars, local.replacement)
  ]))

  ############################################################################
  # Case Transformation
  ############################################################################
  formatted_labels = { for k in local.string_label_names : k =>
    local.label_value_case == "none" ? local.normalized_labels[k] :
    local.label_value_case == "title" ? title(lower(local.normalized_labels[k])) :
    local.label_value_case == "upper" ? upper(local.normalized_labels[k]) :
    lower(local.normalized_labels[k])
  }

  attributes = compact(distinct([
    for v in local.normalized_attributes :
    local.label_value_case == "none" ? v :
    local.label_value_case == "title" ? title(lower(v)) :
    local.label_value_case == "upper" ? upper(v) :
    lower(v)
  ]))

  # Expose individual labels
  namespace   = local.formatted_labels["namespace"]
  tenant      = local.formatted_labels["tenant"]
  environment = local.formatted_labels["environment"]
  stage       = local.formatted_labels["stage"]
  name        = local.formatted_labels["name"]

  ############################################################################
  # ID Construction
  ############################################################################
  id_context = {
    namespace   = local.namespace
    tenant      = local.tenant
    environment = local.environment
    stage       = local.stage
    name        = local.name
    attributes  = join(local.delimiter, local.attributes)
  }

  labels  = [for l in local.label_order : local.id_context[l] if length(local.id_context[l]) > 0]
  id_full = join(local.delimiter, local.labels)

  # Truncation with sha256 hash (replaces old md5-based approach)
  delimiter_length          = length(local.delimiter)
  id_truncated_length_limit = local.id_length_limit - (local.id_hash_length + local.delimiter_length)
  id_truncated              = local.id_truncated_length_limit <= 0 ? "" : "${trimsuffix(substr(local.id_full, 0, local.id_truncated_length_limit), local.delimiter)}${local.delimiter}"

  # Use sha256 for a stronger hash — append alpha chars for cases that disallow digits
  id_hash_raw  = "${sha256(local.id_full)}qrstuvwxyz"
  id_hash_case = local.label_value_case == "title" ? title(local.id_hash_raw) : local.label_value_case == "upper" ? upper(local.id_hash_raw) : local.label_value_case == "lower" ? lower(local.id_hash_raw) : local.id_hash_raw
  id_hash      = replace(local.id_hash_case, local.regex_replace_chars, local.replacement)
  id_short     = substr("${local.id_truncated}${local.id_hash}", 0, local.id_length_limit)
  id           = local.id_length_limit != 0 && length(local.id_full) > local.id_length_limit ? local.id_short : local.id_full

  ############################################################################
  # Tag Generation
  ############################################################################
  tags_context = {
    namespace   = local.namespace
    tenant      = local.tenant
    environment = local.environment
    stage       = local.stage
    name        = local.id
    attributes  = local.id_context.attributes
  }

  generated_tags = {
    for l in setintersection(keys(local.tags_context), local.labels_as_tags) :
    local.label_key_case == "upper" ? upper(l) : (
      local.label_key_case == "lower" ? lower(l) : title(lower(l))
    ) => local.tags_context[l] if length(local.tags_context[l]) > 0
  }

  tags = merge(local.generated_tags, local.input.tags)

  ############################################################################
  # Descriptors
  ############################################################################
  descriptor_formats = local.input.descriptor_formats
  descriptor_labels = { for k, v in local.descriptor_formats : k => [
    for label in v.labels : local.id_context[label]
  ] }
  descriptors = { for k, v in local.descriptor_formats : k =>
    format(v.format, local.descriptor_labels[k]...)
  }

  ############################################################################
  # Output Context — for chaining to downstream modules
  ############################################################################
  output_context = {
    enabled             = local.enabled
    namespace           = local.namespace
    tenant              = local.tenant
    environment         = local.environment
    stage               = local.stage
    name                = local.name
    delimiter           = local.delimiter
    attributes          = local.attributes
    tags                = local.tags
    label_order         = local.label_order
    regex_replace_chars = local.regex_replace_chars
    id_length_limit     = local.id_length_limit
    label_key_case      = local.label_key_case
    label_value_case    = local.label_value_case
    labels_as_tags      = local.labels_as_tags
    descriptor_formats  = local.descriptor_formats
  }
}
