# tf-label

Terraform module to define a consistent naming convention by (namespace, tenant, environment, stage, name, \[attributes\]).

A modern rewrite of [cloudposse/terraform-null-label](https://github.com/cloudposse/terraform-null-label), updated for Terraform 1.5+ with proper type safety, simplified logic, and removal of deprecated patterns.

## Features

- Generates a consistent `id` from configurable label elements
- Produces a `tags` map for AWS resources with label values
- Supports context chaining between modules (parent → child inheritance)
- Configurable case transformation (`lower`, `upper`, `title`, `none`)
- ID length limiting with sha256-based hash suffix for uniqueness
- Custom `descriptor_formats` for alternative output strings
- Full type safety via `optional()` object types (no more `type = any`)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |

## Usage

```hcl
module "label" {
  source = "git::https://github.com/PlatformStackPulse/tf-label.git?ref=v1.0.0"

  namespace   = "eg"
  environment = "us-west-2"
  stage       = "prod"
  name        = "app"
  attributes  = ["public"]

  tags = {
    BusinessUnit = "Engineering"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = module.label.id   # => "eg-us-west-2-prod-app-public"
  tags   = module.label.tags
}
```

### Context Chaining

Pass a parent label's context to child modules to inherit all settings:

```hcl
module "parent" {
  source    = "git::https://github.com/PlatformStackPulse/tf-label.git?ref=v1.0.0"
  namespace = "acme"
  stage     = "prod"
  name      = "platform"
}

module "child" {
  source  = "git::https://github.com/PlatformStackPulse/tf-label.git?ref=v1.0.0"
  name    = "worker"
  context = module.parent.context
}
# child.id => "acme-prod-worker"
```

### Custom Label Order

```hcl
module "label" {
  source      = "git::https://github.com/PlatformStackPulse/tf-label.git?ref=v1.0.0"
  namespace   = "eg"
  stage       = "prod"
  name        = "app"
  label_order = ["name", "namespace", "stage"]
}
# label.id => "app-eg-prod"
```

### Pascal Case (No Delimiter)

```hcl
module "label" {
  source           = "git::https://github.com/PlatformStackPulse/tf-label.git?ref=v1.0.0"
  namespace        = "eg"
  stage            = "prod"
  name             = "myapp"
  delimiter        = ""
  label_value_case = "title"
}
# label.id => "EgProdMyapp"
```

### ID Length Limit

```hcl
module "label" {
  source          = "git::https://github.com/PlatformStackPulse/tf-label.git?ref=v1.0.0"
  namespace       = "acme"
  environment     = "production"
  name            = "my-long-service-name"
  id_length_limit = 32
}
# label.id => truncated with sha256 hash suffix for uniqueness
```

### Descriptor Formats

```hcl
module "label" {
  source    = "git::https://github.com/PlatformStackPulse/tf-label.git?ref=v1.0.0"
  namespace = "acme"
  stage     = "prod"
  name      = "api"

  descriptor_formats = {
    stack = {
      format = "%s/%s/%s"
      labels = ["namespace", "environment", "stage"]
    }
    qualified_name = {
      format = "%s::%s"
      labels = ["namespace", "name"]
    }
  }
}
# module.label.descriptors["stack"]          => "acme//prod"
# module.label.descriptors["qualified_name"] => "acme::api"
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `context` | `object(...)` | `{}` | Single object for passing entire context at once. See `variables.tf` for full type. |
| `enabled` | `bool` | `null` | Set to `false` to prevent the module from creating any resources. |
| `namespace` | `string` | `null` | Usually an abbreviation of your organization name (e.g. `eg`, `cp`). |
| `tenant` | `string` | `null` | A customer identifier, indicating who this instance is for. |
| `environment` | `string` | `null` | Usually region (e.g. `uw2`, `us-west-2`) or role (`prod`, `staging`). |
| `stage` | `string` | `null` | Usually role (e.g. `prod`, `staging`, `dev`, `release`). |
| `name` | `string` | `null` | Component or solution name (e.g. `app`, `jenkins`). |
| `delimiter` | `string` | `null` | Delimiter between ID elements. Defaults to `-`. Set to `""` for none. |
| `attributes` | `list(string)` | `[]` | Additional attributes appended to the ID. |
| `tags` | `map(string)` | `{}` | Additional tags merged into the output. |
| `labels_as_tags` | `set(string)` | `null` | Which labels to include as tags. Default (`null`) includes all. |
| `label_order` | `list(string)` | `null` | Order of labels in the ID. Default: `["namespace", "environment", "stage", "name", "attributes"]`. |
| `regex_replace_chars` | `string` | `null` | Regex of characters to remove. Default: `/[^a-zA-Z0-9-]/`. |
| `id_length_limit` | `number` | `null` | Max length for `id` (minimum 6). `0` = unlimited. |
| `label_key_case` | `string` | `null` | Case for tag keys: `lower`, `title`, `upper`. Default: `title`. |
| `label_value_case` | `string` | `null` | Case for label values: `lower`, `title`, `upper`, `none`. Default: `lower`. |
| `descriptor_formats` | `map(object({format, labels}))` | `{}` | Custom format strings for `descriptors` output. |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Disambiguated ID restricted to `id_length_limit` characters. |
| `id_full` | Full ID string without length restriction. |
| `enabled` | Whether the module is enabled. |
| `namespace` | Normalized namespace. |
| `tenant` | Normalized tenant. |
| `environment` | Normalized environment. |
| `name` | Normalized name. |
| `stage` | Normalized stage. |
| `delimiter` | Delimiter used between ID elements. |
| `attributes` | List of normalized attributes. |
| `tags` | Normalized tag map. |
| `label_order` | The label order used to create the ID. |
| `regex_replace_chars` | The regex used to sanitize ID elements. |
| `id_length_limit` | The length limit used (`0` = unlimited). |
| `descriptors` | Map of descriptors from `descriptor_formats`. |
| `normalized_context` | Normalized context of this module. |
| `context` | Merged context suitable for passing to child modules. |

## Using `exports/context.tf`

Copy `exports/context.tf` into downstream modules to automatically expose the `context` variable with the correct type definition. This ensures consistent context passing throughout your module hierarchy.

## Development

```bash
make dev-setup   # Install pre-commit hooks
make fmt         # Format code
make validate    # Run terraform validate
make lint        # Run TFLint
make test        # Run unit tests (19 scenarios)
make security    # Trivy IaC scan
make all         # Full CI pipeline locally
```

## Tests

19 unit test scenarios covering:

- Basic ID generation and full label composition
- Tag generation and selective `labels_as_tags`
- Custom delimiters and label ordering
- Case transformations (upper, pascal, none)
- ID length truncation with hash suffix
- Disabled module (empty outputs)
- Regex character replacement
- Context chaining between modules
- Tag key case control
- Tenant in label order
- Descriptor formats

Run tests:

```bash
terraform init -backend=false
terraform test
```

---

## Migration from cloudposse/terraform-null-label

### What Changed

| Area | Old (terraform-null-label) | New (tf-label) |
|------|---------------------------|----------------|
| Terraform version | >= 0.13.0 | >= 1.5.0 |
| Context variable type | `type = any` (no type safety) | `object()` with `optional()` — full type checking |
| Sentinel values | `["unset"]` / `["default"]` workarounds | Native `null` — Terraform 1.0 fixed the underlying bug |
| `tags_as_list_of_maps` | Present (for old ASG tag format) | **Removed** — AWS provider 4.0+ uses standard `tags = {}` |
| `additional_tag_map` | Present (for ASG propagation) | **Removed** — no longer needed |
| Hash algorithm | `md5()` | `sha256()` — stronger collision resistance |
| `descriptor_formats` type | `type = any` | Properly typed `map(object({format, labels}))` |
| `label_order` validation | None | Validates entries are valid label names |
| `labels_as_tags` default | Sentinel `["default"]` with magic detection | `null` = include all labels (idiomatic) |
| Null handling | Complex `lookup()` + `try()` + `contains()` | Direct field access on typed object |
| Code complexity | ~170 LOC with workaround comments | ~140 LOC clean logic |

### Breaking Changes

1. **`tags_as_list_of_maps` output removed** — If you used this for AWS autoscaling group tags, switch to the standard `tags = {}` syntax (supported since AWS provider 4.0).

2. **`additional_tag_map` input removed** — Merge any additional tags directly into the `tags` input.

3. **`labels_as_tags` default** — Use `null` (include all) instead of `["default"]`.

4. **Hash suffix differs** — If you use `id_length_limit` and the ID exceeds the limit, the 5-character hash suffix uses sha256 instead of md5. This means truncated IDs will differ from the old module. If you don't use `id_length_limit`, there is no difference.

### Test Comparison

Both modules produce identical output for all 19 test scenarios (same inputs, same expected outputs) except for the hash suffix when `id_length_limit` triggers truncation:

```
Old (md5):    acme-production-re-b96f7
New (sha256): acme-production-re-2bbf9
```

## License

Apache 2.0 — see [LICENSE](LICENSE)
