.PHONY: help up down build logs test clean restart redis-cli bash-app1 bash-app2

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
