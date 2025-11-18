# Makefile for Demo CI/CD Application
# Usage: make <target>
# For Windows, use 'make' with WSL or Git Bash, or use PowerShell scripts directly

# Variables
DOCKER_USER ?= your-dockerhub-username
BUILD_NUMBER ?= latest
IMAGE_NAME = demo-cicd
CLUSTER_NAME = queueaicluster
RELEASE_NAME = demo-cicd
NAMESPACE = default

.PHONY: help
help: ## Show this help message
	@echo "Demo CI/CD - Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## Install Node.js dependencies
	npm install

.PHONY: test
test: ## Run tests
	npm test

.PHONY: lint
lint: ## Run linter
	npm run lint

.PHONY: build
build: ## Build Docker image
	docker build -t $(IMAGE_NAME):$(BUILD_NUMBER) .
	docker tag $(IMAGE_NAME):$(BUILD_NUMBER) $(IMAGE_NAME):latest

.PHONY: push
push: ## Push Docker image to Docker Hub
	docker tag $(IMAGE_NAME):$(BUILD_NUMBER) $(DOCKER_USER)/$(IMAGE_NAME):$(BUILD_NUMBER)
	docker tag $(IMAGE_NAME):$(BUILD_NUMBER) $(DOCKER_USER)/$(IMAGE_NAME):latest
	docker push $(DOCKER_USER)/$(IMAGE_NAME):$(BUILD_NUMBER)
	docker push $(DOCKER_USER)/$(IMAGE_NAME):latest

.PHONY: build-push
build-push: build push ## Build and push Docker image

.PHONY: load-kind
load-kind: ## Load Docker image into Kind cluster
	kind load docker-image $(IMAGE_NAME):$(BUILD_NUMBER) --name $(CLUSTER_NAME)
	kind load docker-image $(IMAGE_NAME):latest --name $(CLUSTER_NAME)

.PHONY: deploy
deploy: ## Deploy application with Helm
	kubectl config use-context kind-$(CLUSTER_NAME)
	helm upgrade --install $(RELEASE_NAME) ./helm \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set image.repository=$(DOCKER_USER)/$(IMAGE_NAME) \
		--set image.tag=$(BUILD_NUMBER) \
		--wait \
		--timeout 5m

.PHONY: full-deploy
full-deploy: build-push load-kind deploy ## Complete deployment (build, push, load, deploy)

.PHONY: status
status: ## Show deployment status
	@echo "=== Helm Releases ==="
	helm list -n $(NAMESPACE)
	@echo "\n=== Deployments ==="
	kubectl get deployment $(RELEASE_NAME) -n $(NAMESPACE)
	@echo "\n=== Pods ==="
	kubectl get pods -l app.kubernetes.io/name=demo-cicd -n $(NAMESPACE)
	@echo "\n=== Services ==="
	kubectl get svc $(RELEASE_NAME) -n $(NAMESPACE)

.PHONY: logs
logs: ## View application logs
	kubectl logs -l app.kubernetes.io/name=demo-cicd -n $(NAMESPACE) -f

.PHONY: describe
describe: ## Describe deployment
	kubectl describe deployment $(RELEASE_NAME) -n $(NAMESPACE)

.PHONY: pods
pods: ## List pods
	kubectl get pods -l app.kubernetes.io/name=demo-cicd -n $(NAMESPACE)

.PHONY: restart
restart: ## Restart deployment
	kubectl rollout restart deployment/$(RELEASE_NAME) -n $(NAMESPACE)

.PHONY: scale
scale: ## Scale deployment (use with REPLICAS=n)
	kubectl scale deployment/$(RELEASE_NAME) --replicas=$(REPLICAS) -n $(NAMESPACE)

.PHONY: uninstall
uninstall: ## Uninstall Helm release
	helm uninstall $(RELEASE_NAME) -n $(NAMESPACE)

.PHONY: clean
clean: ## Clean up local Docker images
	docker rmi $(IMAGE_NAME):$(BUILD_NUMBER) || true
	docker rmi $(IMAGE_NAME):latest || true
	docker rmi $(DOCKER_USER)/$(IMAGE_NAME):$(BUILD_NUMBER) || true
	docker rmi $(DOCKER_USER)/$(IMAGE_NAME):latest || true

.PHONY: helm-lint
helm-lint: ## Lint Helm chart
	helm lint ./helm

.PHONY: helm-template
helm-template: ## Show Helm template output
	helm template $(RELEASE_NAME) ./helm \
		--set image.repository=$(DOCKER_USER)/$(IMAGE_NAME) \
		--set image.tag=$(BUILD_NUMBER)

.PHONY: helm-dry-run
helm-dry-run: ## Perform Helm dry run
	helm upgrade --install $(RELEASE_NAME) ./helm \
		--namespace $(NAMESPACE) \
		--set image.repository=$(DOCKER_USER)/$(IMAGE_NAME) \
		--set image.tag=$(BUILD_NUMBER) \
		--dry-run --debug

.PHONY: check-cluster
check-cluster: ## Check Kind cluster
	@echo "Available Kind clusters:"
	@kind get clusters
	@echo "\nCurrent kubectl context:"
	@kubectl config current-context
	@echo "\nCluster info:"
	@kubectl cluster-info

.PHONY: port-forward
port-forward: ## Port forward to application (8080 -> 3000)
	kubectl port-forward svc/$(RELEASE_NAME) 8080:3000 -n $(NAMESPACE)

.PHONY: test-app
test-app: ## Test application endpoints
	@echo "Testing application..."
	@curl -s http://localhost:30080 | jq . || curl http://localhost:30080
	@echo "\nTesting health endpoint..."
	@curl -s http://localhost:30080/health | jq . || curl http://localhost:30080/health

.PHONY: events
events: ## Show Kubernetes events
	kubectl get events --sort-by=.metadata.creationTimestamp -n $(NAMESPACE)

# Examples:
# make build BUILD_NUMBER=1
# make push DOCKER_USER=myusername BUILD_NUMBER=1
# make deploy DOCKER_USER=myusername BUILD_NUMBER=1
# make full-deploy DOCKER_USER=myusername BUILD_NUMBER=1
# make scale REPLICAS=3
