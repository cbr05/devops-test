.PHONY: help up down build logs test clean restart redis-cli bash-app1 bash-app2 \
        tf-init tf-plan tf-apply tf-destroy tf-validate tf-fmt tf-output \
        scan scan-tf scan-tf-plan scan-compose scan-docker scan-images scan-code scan-secrets

# Cores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;34m
NC     := \033[0m

help: ## Mostra esta ajuda
	@echo "$(BLUE)DevOps Test - Comandos Uteis$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

# ============================================
# DOCKER COMPOSE COMMANDS
# ============================================

up: ## Sobe todos os serviços
	@echo "$(YELLOW)Subindo infraestrutura...$(NC)"
	docker-compose up -d --build
	@echo ""
	@echo "$(GREEN)✓ Serviços iniciados!$(NC)"
	@echo ""
	@docker-compose ps

down: ## Para todos os serviços
	@echo "$(YELLOW)Parando serviços...$(NC)"
	docker-compose down

build: ## Reconstrói todas as imagens
	@echo "$(YELLOW)Reconstruindo imagens...$(NC)"
	docker-compose build --no-cache

restart: ## Reinicia todos os serviços
	@echo "$(YELLOW)Reiniciando serviços...$(NC)"
	docker-compose restart

logs: ## Mostra logs de todos os serviços
	docker-compose logs -f

logs-app1: ## Logs do App 1
	docker-compose logs -f app1

logs-app2: ## Logs do App 2
	docker-compose logs -f app2

logs-redis: ## Logs do Redis
	docker-compose logs -f redis

logs-nginx: ## Logs do Nginx
	docker-compose logs -f nginx

clean: ## Limpa containers, volumes e imagens
	@echo "$(YELLOW)Cuidado! Isso vai remover todos os dados!$(NC)"
	@read -p "Continuar? (y/N) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v --rmi local; \
		docker system prune -f; \
		echo "$(GREEN)Limpeza concluída!$(NC)"; \
	fi

# ============================================
# TESTES
# ============================================

test: ## Testa todas as rotas
	@echo "$(BLUE)=== Testando rotas ===$(NC)"
	@echo ""
	@echo "$(YELLOW)App 1 - Texto fixo (cache 10s):$(NC)"
	@curl -s http://localhost:8001/text | python3 -m json.tool
	@echo ""
	@echo "$(YELLOW)App 1 - Horário atual (cache 10s):$(NC)"
	@curl -s http://localhost:8001/time | python3 -m json.tool
	@echo ""
	@echo "$(YELLOW)App 2 - Texto fixo (cache 60s):$(NC)"
	@curl -s http://localhost:8002/text | python3 -m json.tool
	@echo ""
	@echo "$(YELLOW)App 2 - Horário atual (cache 60s):$(NC)"
	@curl -s http://localhost:8002/time | python3 -m json.tool
	@echo ""
	@echo "$(YELLOW)App 1 - Health check:$(NC)"
	@curl -s http://localhost:8001/health | python3 -m json.tool
	@echo ""
	@echo "$(YELLOW)App 2 - Health check:$(NC)"
	@curl -s http://localhost:8002/health | python3 -m json.tool
	@echo ""
	@echo "$(GREEN)✓ Testes concluídos!$(NC)"

test-nginx: ## Testa via Nginx
	@echo "$(BLUE)=== Testando via Nginx ===$(NC)"
	@echo ""
	@curl -s http://localhost/app1/text
	@echo ""
	@curl -s http://localhost/app2/text
	@echo ""

# ============================================
# ACESSO AOS CONTAINERS
# ============================================

bash-app1: ## Abre bash no container App 1
	docker exec -it devops-test-app1 sh

bash-app2: ## Abre bash no container App 2
	docker exec -it devops-test-app2 sh

redis-cli: ## Abre Redis CLI
	docker exec -it devops-test-redis redis-cli -a redis123

redis-keys: ## Lista keys do Redis
	docker exec -it devops-test-redis redis-cli -a redis123 KEYS "*"

redis-ttl: ## Mostra TTL das keys
	docker exec -it devops-test-redis redis-cli -a redis123 --scan | head -10 | xargs -I {} sh -c 'echo -n "{}: "; docker exec -it devops-test-redis redis-cli -a redis123 TTL {}'

# ============================================
# MONITORAMENTO
# ============================================

metrics: ## Mostra métricas Prometheus
	@echo "$(BLUE)=== Prometheus Metrics ===$(NC)"
	@echo ""
	@echo "$(YELLOW)App 1:$(NC)"
	@curl -s http://localhost:8001/metrics | head -20
	@echo ""
	@echo "$(YELLOW)App 2:$(NC)"
	@curl -s http://localhost:8002/metrics | head -20

# ============================================
# STATUS
# ============================================

status: ## Mostra status dos serviços
	@echo "$(BLUE)=== Status dos Serviços ===$(NC)"
	@echo ""
	@docker-compose ps
	@echo ""
	@echo "$(BLUE)=== Health Checks ===$(NC)"
	@curl -s http://localhost:8001/health && echo " App1: OK" || echo " App1: FAIL"
	@curl -s http://localhost:8002/health && echo " App2: OK" || echo " App2: FAIL"
	@curl -s http://localhost/health && echo " Nginx: OK" || echo " Nginx: FAIL"
	@curl -s http://localhost:9090/-/healthy && echo " Prometheus: OK" || echo " Prometheus: FAIL"

# ============================================
# DESENVOLVIMENTO
# ============================================

dev-app1: ## Sobe apenas App 1 e Redis
	docker-compose up -d redis app1

dev-app2: ## Sobe apenas App 2 e Redis
	docker-compose up -d redis app2

# ============================================
# TERRAFORM
# ============================================

TF_DIR := terraform

tf-init: ## Inicializa o Terraform (baixa o provider Docker)
	@echo "$(YELLOW)Inicializando Terraform...$(NC)"
	cd $(TF_DIR) && terraform init
	@echo "$(GREEN)✓ Terraform inicializado!$(NC)"

tf-validate: ## Valida a sintaxe dos arquivos Terraform
	@echo "$(YELLOW)Validando configuração...$(NC)"
	cd $(TF_DIR) && terraform validate
	@echo "$(GREEN)✓ Configuração válida!$(NC)"

tf-fmt: ## Formata os arquivos Terraform
	cd $(TF_DIR) && terraform fmt -recursive

tf-plan: ## Mostra o plano de execução sem aplicar
	@echo "$(YELLOW)Gerando plano Terraform...$(NC)"
	cd $(TF_DIR) && terraform plan

tf-apply: ## Sobe a infraestrutura via Terraform
	@echo "$(YELLOW)Aplicando infraestrutura Terraform...$(NC)"
	cd $(TF_DIR) && terraform apply -auto-approve
	@echo ""
	@echo "$(GREEN)✓ Infraestrutura provisionada!$(NC)"
	@echo ""
	cd $(TF_DIR) && terraform output

tf-destroy: ## Destrói toda a infraestrutura Terraform
	@echo "$(YELLOW)Destruindo infraestrutura...$(NC)"
	cd $(TF_DIR) && terraform destroy -auto-approve
	@echo "$(GREEN)✓ Infraestrutura destruída!$(NC)"

tf-output: ## Mostra os outputs (URLs dos serviços)
	cd $(TF_DIR) && terraform output

# ============================================
# SEGURANÇA / SCANNING
# Todas as ferramentas rodam via Docker — sem instalação local necessária.
# ============================================

scan: scan-secrets scan-docker scan-tf scan-compose scan-code ## Executa todos os scans estáticos
	@echo "$(GREEN)✓ Scans concluídos!$(NC)"

scan-secrets: ## Gitleaks — detecta senhas e tokens no repositório git
	@echo "$(BLUE)=== Gitleaks: segredos no git ===$(NC)"
	docker run --rm \
		-v "$(CURDIR):/repo" \
		zricethezav/gitleaks detect --source /repo

scan-docker: ## Hadolint — lint dos Dockerfiles
	@echo "$(BLUE)=== Hadolint: Dockerfiles ===$(NC)"
	docker run --rm \
		-v "$(CURDIR):/project:ro" \
		-v "$(CURDIR)/.hadolint.yaml:/hadolint.yaml:ro" \
		--entrypoint /bin/hadolint \
		hadolint/hadolint \
		--config /hadolint.yaml \
		/project/app1/Dockerfile \
		/project/app2/Dockerfile \
		/project/scripts/Dockerfile

scan-tf: ## Checkov — misconfigurations nos arquivos .tf
	@echo "$(BLUE)=== Checkov: Terraform ===$(NC)"
	docker run --rm \
		-v "$(CURDIR)/terraform:/tf:ro" \
		-v "$(CURDIR)/.checkov.yaml:/.checkov.yaml:ro" \
		bridgecrew/checkov -d /tf --framework terraform --compact \
		--config-file /.checkov.yaml

scan-tf-plan: ## Checkov — escaneia o plan real do Terraform (mais preciso que scan-tf)
	@echo "$(YELLOW)Gerando plan file...$(NC)"
	cd $(TF_DIR) && terraform plan -out=tfplan.binary
	cd $(TF_DIR) && terraform show -json tfplan.binary > tfplan.json
	@echo "$(BLUE)=== Checkov: Terraform Plan ===$(NC)"
	docker run --rm \
		-v "$(CURDIR)/terraform:/tf:ro" \
		bridgecrew/checkov -f /tf/tfplan.json --framework terraform_plan --compact
	@rm -f $(TF_DIR)/tfplan.binary $(TF_DIR)/tfplan.json

scan-compose: ## Checkov — misconfigurations no docker-compose.yml
	@echo "$(BLUE)=== Checkov: Docker Compose ===$(NC)"
	docker run --rm \
		-v "$(CURDIR):/project:ro" \
		bridgecrew/checkov -f /project/docker-compose.yml --compact

scan-code: ## Bandit (Python/app1) + Gosec (Go/app2)
	@echo "$(BLUE)=== Bandit: app1 (Python) ===$(NC)"
	docker run --rm \
		-v "$(CURDIR)/app1:/app:ro" \
		ghcr.io/pycqa/bandit/bandit:latest \
		-r /app -ll -ii
	@echo ""
	@echo "$(BLUE)=== Gosec: app2 (Go) ===$(NC)"
	docker run --rm \
		-v "$(CURDIR)/app2:/app:ro" \
		-w /app \
		securego/gosec:latest -severity medium ./...

scan-images: ## Trivy — CVEs nas imagens buildadas (requer make build antes)
	@echo "$(BLUE)=== Trivy: imagens Docker ===$(NC)"
	@echo "$(YELLOW)→ devops-test/app1:latest$(NC)"
	docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image --severity HIGH,CRITICAL devops-test/app1:latest
	@echo "$(YELLOW)→ devops-test/app2:latest$(NC)"
	docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image --severity HIGH,CRITICAL devops-test/app2:latest

# ============================================
# GIT
# ============================================

git-add: ## Adiciona changes ao git
	git add -A
	@echo "$(GREEN)Changes adicionados ao staging. Execute 'make git-commit' para comitar.$(NC)"

git-commit: ## Comita changes
	@read -p "Mensagem do commit: " msg; \
	git commit -m "$$msg"
	@echo "$(GREEN)Commit feito!$(NC)"

git-push: ## Push para remote
	@echo "$(YELLOW)Push para origin/main...$(NC)"
	git push origin main
	@echo "$(GREEN)Push concluído!$(NC)"

git-status: ## Mostra status do git
	git status
	git log --oneline -5
