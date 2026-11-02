.DEFAULT_GOAL := help
.PHONY: help doctor models up down

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-10s %s\n", $$1, $$2}'

doctor: ## Check required tools, Docker daemon, GPUs and Ollama
	@./scripts/doctor.sh

models: ## Pull the Ollama models listed in models.txt
	@./scripts/pull-models.sh

up: ## Bring the whole system up (filled in during phase 1)
	@echo "make up: not implemented yet" >&2; exit 1

down: ## Tear the whole system down (filled in during phase 1)
	@echo "make down: not implemented yet" >&2; exit 1
