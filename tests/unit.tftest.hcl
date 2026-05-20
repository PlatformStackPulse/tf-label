################################################################################
# Unit Tests for tf-null-label
# Uses Terraform native test framework (terraform test)
################################################################################

run "basic_id_generation" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 1: Basic — namespace-stage-name (environment empty, excluded)
  assert {
    condition     = output.basic_id == "eg-prod-bastion"
    error_message = "Basic ID should be 'eg-prod-bastion', got '${output.basic_id}'"
  }
}

run "full_labels" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 2: All elements — default order is namespace, environment, stage, name, attributes
  # tenant is NOT in default label_order
  assert {
    condition     = output.full_id == "eg-uw2-prod-app-public-v2"
    error_message = "Full ID should be 'eg-uw2-prod-app-public-v2', got '${output.full_id}'"
  }
}

run "full_tags_generated" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 2: Tags should include all label elements
  assert {
    condition     = output.full_tags["Namespace"] == "eg"
    error_message = "Tag 'Namespace' should be 'eg'"
  }

  assert {
    condition     = output.full_tags["Tenant"] == "client1"
    error_message = "Tag 'Tenant' should be 'client1'"
  }

  assert {
    condition     = output.full_tags["Environment"] == "uw2"
    error_message = "Tag 'Environment' should be 'uw2'"
  }

  assert {
    condition     = output.full_tags["Stage"] == "prod"
    error_message = "Tag 'Stage' should be 'prod'"
  }

  assert {
    condition     = output.full_tags["Attributes"] == "public-v2"
    error_message = "Tag 'Attributes' should be 'public-v2'"
  }
}

run "custom_delimiter" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 3: Dot delimiter
  assert {
    condition     = output.custom_delimiter_id == "eg.prod.app"
    error_message = "Custom delimiter ID should be 'eg.prod.app', got '${output.custom_delimiter_id}'"
  }
}

run "custom_label_order" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 4: name-namespace-stage
  assert {
    condition     = output.custom_order_id == "app-eg-prod"
    error_message = "Custom order ID should be 'app-eg-prod', got '${output.custom_order_id}'"
  }
}

run "upper_case_values" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 5: UPPER case
  assert {
    condition     = output.upper_case_id == "EG-PROD-APP"
    error_message = "Upper case ID should be 'EG-PROD-APP', got '${output.upper_case_id}'"
  }
}

run "pascal_case_values" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 6: Title case with empty delimiter = PascalCase
  # Note: title() capitalizes the first char of each "word". Since regex strips
  # the space from "my app" → "myapp" (one word), title gives "Myapp" not "MyApp"
  assert {
    condition     = output.pascal_case_id == "EgProdMyapp"
    error_message = "Pascal case ID should be 'EgProdMyapp', got '${output.pascal_case_id}'"
  }
}

run "no_case_transformation" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 7: No case change — preserves original
  assert {
    condition     = output.no_case_id == "EG-Prod-App"
    error_message = "No-case ID should be 'EG-Prod-App', got '${output.no_case_id}'"
  }
}

run "id_length_truncation" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 8: Truncated ID should be <= 24 chars and id_full should be unrestricted
  assert {
    condition     = length(output.truncated_id) <= 24
    error_message = "Truncated ID length should be <= 24, got ${length(output.truncated_id)}"
  }

  assert {
    condition     = output.truncated_id_full == "acme-production-release-my-very-long-service-primary"
    error_message = "Full ID should be 'acme-production-release-my-very-long-service-primary', got '${output.truncated_id_full}'"
  }

  assert {
    condition     = length(output.truncated_id_full) > 24
    error_message = "Full ID should be longer than limit"
  }
}

run "disabled_module" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 9: Disabled — all outputs empty
  assert {
    condition     = output.disabled_id == ""
    error_message = "Disabled ID should be empty"
  }

  assert {
    condition     = output.disabled_enabled == false
    error_message = "Disabled enabled should be false"
  }

  assert {
    condition     = length(output.disabled_tags) == 0
    error_message = "Disabled tags should be empty"
  }
}

run "regex_replace_chars" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 10: Special chars stripped
  assert {
    condition     = output.regex_chars_id == "eg-prod-appv2"
    error_message = "Regex chars ID should be 'eg-prod-appv2', got '${output.regex_chars_id}'"
  }
}

run "context_chaining" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 11: Child inherits parent context
  assert {
    condition     = output.child_id == "acme-uw2-prod-worker-queue"
    error_message = "Child ID should be 'acme-uw2-prod-worker-queue', got '${output.child_id}'"
  }

  # Child should inherit parent's tags
  assert {
    condition     = output.child_tags["ManagedBy"] == "Terraform"
    error_message = "Child should inherit parent tag 'ManagedBy'"
  }
}

run "tag_key_case_lower" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 12: Tag keys in lower case
  assert {
    condition     = lookup(output.tags_lower_key, "namespace", null) == "eg"
    error_message = "Lower key tags should have 'namespace' key"
  }

  assert {
    condition     = lookup(output.tags_lower_key, "stage", null) == "prod"
    error_message = "Lower key tags should have 'stage' key"
  }
}

run "tag_key_case_upper" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 13: Tag keys in upper case
  assert {
    condition     = lookup(output.tags_upper_key, "NAMESPACE", null) == "eg"
    error_message = "Upper key tags should have 'NAMESPACE' key"
  }

  assert {
    condition     = lookup(output.tags_upper_key, "STAGE", null) == "prod"
    error_message = "Upper key tags should have 'STAGE' key"
  }
}

run "selective_labels_as_tags" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 14: Only selected labels appear as tags
  assert {
    condition     = lookup(output.selective_tags, "Namespace", null) == "eg"
    error_message = "Selective tags should include 'Namespace'"
  }

  assert {
    condition     = lookup(output.selective_tags, "Stage", null) == "prod"
    error_message = "Selective tags should include 'Stage'"
  }

  assert {
    condition     = lookup(output.selective_tags, "Environment", null) == null
    error_message = "Selective tags should NOT include 'Environment'"
  }

  assert {
    condition     = lookup(output.selective_tags, "Tenant", null) == null
    error_message = "Selective tags should NOT include 'Tenant'"
  }
}

run "no_generated_tags" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 15: labels_as_tags = [] means no generated tags, only custom
  assert {
    condition     = output.no_gen_tags["Custom"] == "tag"
    error_message = "Custom tag should still be present"
  }

  assert {
    condition     = lookup(output.no_gen_tags, "Namespace", null) == null
    error_message = "No generated tags should not have 'Namespace'"
  }

  assert {
    condition     = length(output.no_gen_tags) == 1
    error_message = "Should only have 1 tag (the custom one), got ${length(output.no_gen_tags)}"
  }
}

run "attributes_only" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 16: Only name and attributes
  assert {
    condition     = output.attrs_only_id == "service-a-b-c"
    error_message = "Attrs only ID should be 'service-a-b-c', got '${output.attrs_only_id}'"
  }
}

run "tenant_in_label_order" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 17: Tenant included in order
  assert {
    condition     = output.with_tenant_order_id == "eg-t1-uw2-prod-app"
    error_message = "With tenant ID should be 'eg-t1-uw2-prod-app', got '${output.with_tenant_order_id}'"
  }
}

run "descriptor_formats" {
  command = plan

  module {
    source = "./tests/setup"
  }

  # Scenario 18: Descriptors
  assert {
    condition     = output.descriptors["stack"] == "acme/uw2/prod"
    error_message = "Descriptor 'stack' should be 'acme/uw2/prod', got '${output.descriptors["stack"]}'"
  }

  assert {
    condition     = output.descriptors["qualified"] == "acme::api"
    error_message = "Descriptor 'qualified' should be 'acme::api', got '${output.descriptors["qualified"]}'"
  }
}
