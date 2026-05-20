# =============================================================================
# tf-label — Makefile
# =============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Terraform settings (override via environment)
TF_VERSION     ?= 1.11.3
TFLINT_VERSION ?= v0.53.0
TRIVY_VERSION  ?= 0.58.0
TESTS_DIR      := tests

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
CYAN   := \033[0;36m
RESET  := \033[0m

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo ""
	@echo "$(CYAN)tf-label — Terraform Naming & Tagging Module$(RESET)"
	@echo ""
	@echo "$(GREEN)Targets:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# Core Targets
# =============================================================================

.PHONY: init
init: ## Initialize the module
	@echo "$(GREEN)Initializing module...$(RESET)"
	@terraform init -backend=false -input=false > /dev/null 2>&1
	@echo "$(GREEN)✓ Module initialized$(RESET)"

.PHONY: fmt
fmt: ## Format all Terraform files
	@echo "$(GREEN)Formatting...$(RESET)"
	@terraform fmt -recursive
	@echo "$(GREEN)✓ Formatted$(RESET)"

.PHONY: fmt-check
fmt-check: ## Check formatting (CI mode — fails on diff)
	@echo "$(GREEN)Checking format...$(RESET)"
	@terraform fmt -check -recursive -diff
	@echo "$(GREEN)✓ Format OK$(RESET)"

.PHONY: validate
validate: init ## Validate the module
	@echo "$(GREEN)Validating module...$(RESET)"
	@terraform validate
	@echo "$(GREEN)✓ Module valid$(RESET)"

.PHONY: lint
lint: ## Run TFLint
	@echo "$(GREEN)Linting...$(RESET)"
	@tflint --init > /dev/null 2>&1
	@tflint
	@echo "$(GREEN)✓ Lint OK$(RESET)"

.PHONY: test
test: test-unit ## Run all tests

.PHONY: test-unit
test-unit: init ## Run unit tests
	@echo "$(GREEN)Running unit tests...$(RESET)"
	@terraform test -verbose
	@echo "$(GREEN)✓ Unit tests passed$(RESET)"

.PHONY: security
security: ## Run Trivy IaC security scan
	@echo "$(GREEN)Running security scan...$(RESET)"
	@trivy config . --severity HIGH,CRITICAL --tf-exclude-downloaded-modules
	@echo "$(GREEN)✓ Security scan passed$(RESET)"

.PHONY: docs
docs: ## Generate terraform-docs
	@echo "$(GREEN)Generating documentation...$(RESET)"
	@terraform-docs markdown table --output-file README.md --output-mode inject .
	@echo "$(GREEN)✓ Documentation generated$(RESET)"

.PHONY: clean
clean: ## Remove .terraform dirs and plan files
	@echo "$(GREEN)Cleaning...$(RESET)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfplan" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleaned$(RESET)"

# =============================================================================
# Build Targets
# =============================================================================

.PHONY: all
all: fmt-check validate lint test security docs ## Run all checks (CI mode)
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════$(RESET)"
	@echo "$(GREEN)  ✓ All checks passed$(RESET)"
	@echo "$(GREEN)═══════════════════════════════════════$(RESET)"

.PHONY: ci
ci: all ## Alias for 'all' — CI optimized

.PHONY: dev-setup
dev-setup: ## Install development tools
	@echo "$(GREEN)Installing development tools...$(RESET)"
	@echo ""
	@echo "$(CYAN)Checking tflint...$(RESET)"
	@if ! command -v tflint &> /dev/null; then \
		echo "  Installing tflint..."; \
		curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash; \
	else \
		echo "  ✓ tflint installed"; \
	fi
	@echo ""
	@echo "$(CYAN)Checking trivy...$(RESET)"
	@if ! command -v trivy &> /dev/null; then \
		echo "  Installing trivy..."; \
		curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin; \
	else \
		echo "  ✓ trivy installed"; \
	fi
	@echo ""
	@echo "$(CYAN)Checking terraform-docs...$(RESET)"
	@if ! command -v terraform-docs &> /dev/null; then \
		echo "  Installing terraform-docs..."; \
		curl -sSLo /tmp/terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/latest/download/terraform-docs-v0.19.0-linux-amd64.tar.gz; \
		tar -xzf /tmp/terraform-docs.tar.gz -C /tmp; \
		sudo mv /tmp/terraform-docs /usr/local/bin/; \
	else \
		echo "  ✓ terraform-docs installed"; \
	fi
	@echo ""
	@echo "$(CYAN)Checking pre-commit...$(RESET)"
	@if ! command -v pre-commit &> /dev/null; then \
		echo "  Installing pre-commit..."; \
		pip3 install pre-commit; \
	else \
		echo "  ✓ pre-commit installed"; \
	fi
	@echo ""
	@echo "$(GREEN)Setting up pre-commit hooks...$(RESET)"
	@pre-commit install
	@pre-commit install --hook-type commit-msg
	@echo "$(GREEN)✓ Development tools ready$(RESET)"
