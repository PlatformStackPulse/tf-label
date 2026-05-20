# tf-label

[![Terraform Format](https://img.shields.io/badge/terraform-fmt-blue?logo=terraform)](https://github.com/PlatformStackPulse/tf-label/actions)
[![Terraform Validate](https://img.shields.io/badge/terraform-validate-blue?logo=terraform)](https://github.com/PlatformStackPulse/tf-label/actions)
[![TFLint](https://img.shields.io/badge/tflint-passing-brightgreen?logo=terraform)](https://github.com/PlatformStackPulse/tf-label/actions)
[![Terraform Test](https://img.shields.io/badge/tests-19%20passed-brightgreen?logo=terraform)](https://github.com/PlatformStackPulse/tf-label/actions)
[![Security Scan](https://img.shields.io/badge/trivy-passing-brightgreen?logo=aqua)](https://github.com/PlatformStackPulse/tf-label/actions)
[![Conventional Commits](https://img.shields.io/badge/commits-conventional-blue?logo=conventionalcommits)](https://conventionalcommits.org)
[![Documentation](https://img.shields.io/badge/docs-terraform--docs-blue?logo=readthedocs)](https://github.com/PlatformStackPulse/tf-label/actions)
[![License](https://img.shields.io/badge/license-MIT-blue?logo=opensourceinitiative)](LICENSE)

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

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |

### Providers

No providers.

### Modules

No modules.

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes and tags, which are merged. | <pre>object({<br/>    enabled             = optional(bool, true)<br/>    namespace           = optional(string, null)<br/>    tenant              = optional(string, null)<br/>    environment         = optional(string, null)<br/>    stage               = optional(string, null)<br/>    name                = optional(string, null)<br/>    delimiter           = optional(string, null)<br/>    attributes          = optional(list(string), [])<br/>    tags                = optional(map(string), {})<br/>    label_order         = optional(list(string), null)<br/>    regex_replace_chars = optional(string, null)<br/>    id_length_limit     = optional(number, null)<br/>    label_key_case      = optional(string, null)<br/>    label_value_case    = optional(string, null)<br/>    labels_as_tags      = optional(set(string), null)<br/>    descriptor_formats = optional(map(object({<br/>      format = string<br/>      labels = list(string)<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>   format = string<br/>   labels = list(string)<br/>}`<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | <pre>map(object({<br/>    format = string<br/>    labels = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT'. | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` to keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>Note: The value of the `name` tag, if included, will be the `id`, not the `name`. | `set(string)` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique. | `string` | `null` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release'. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element. A customer identifier, indicating who this instance of a resource is for. | `string` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_attributes"></a> [attributes](#output\_attributes) | List of normalized attributes. |
| <a name="output_context"></a> [context](#output\_context) | Merged but otherwise unmodified input to this module, to be used as context input to other modules.<br/>Note: this version will have null values as defaults, not the values actually used as defaults. |
| <a name="output_delimiter"></a> [delimiter](#output\_delimiter) | Delimiter between ID elements. |
| <a name="output_descriptors"></a> [descriptors](#output\_descriptors) | Map of descriptors as configured by `descriptor_formats`. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | True if module is enabled, false otherwise. |
| <a name="output_environment"></a> [environment](#output\_environment) | Normalized environment. |
| <a name="output_id"></a> [id](#output\_id) | Disambiguated ID string restricted to `id_length_limit` characters in total. |
| <a name="output_id_full"></a> [id\_full](#output\_id\_full) | ID string not restricted in length. |
| <a name="output_id_length_limit"></a> [id\_length\_limit](#output\_id\_length\_limit) | The id\_length\_limit actually used to create the ID, with `0` meaning unlimited. |
| <a name="output_label_order"></a> [label\_order](#output\_label\_order) | The naming order actually used to create the ID. |
| <a name="output_name"></a> [name](#output\_name) | Normalized name. |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Normalized namespace. |
| <a name="output_normalized_context"></a> [normalized\_context](#output\_normalized\_context) | Normalized context of this module. |
| <a name="output_regex_replace_chars"></a> [regex\_replace\_chars](#output\_regex\_replace\_chars) | The regex\_replace\_chars actually used to create the ID. |
| <a name="output_stage"></a> [stage](#output\_stage) | Normalized stage. |
| <a name="output_tags"></a> [tags](#output\_tags) | Normalized Tag map. |
| <a name="output_tenant"></a> [tenant](#output\_tenant) | Normalized tenant. |
<!-- END_TF_DOCS -->

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

MIT — see [LICENSE](LICENSE)
