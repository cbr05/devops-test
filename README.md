# DevOps Technical Test

## 📋 Descrição

Teste técnico para vaga DevOps Senior contendo duas aplicações com camada de cache e observabilidade.

## 🏗️ Arquitetura

```
                    ┌──────────┐
                    |  Usuario  |
                    └────┬─────┘
                         |
                    ┌────▼─────┐
                    |  NGINX   |  :8080
                    | (Proxy)  |
                    └────┬─────┘
                   ┌─────┴──────┐
              ┌────▼────┐  ┌───▼────┐
              |  APP 1  |  | APP 2  |
              | Python  |  |  Go    |
              |  :8001  |  | :8002  |
              | cache:  |  | cache: |
              | 10s     |  | 60s    |
              └────┬────┘  └───┬────┘
                   └─────┬─────┘
                    ┌────▼────┐
                    | REDIS   |  :6379
                    | (Cache) |
                    └────┬────┘
                         |
              ┌──────────┴──────────┐
         ┌────▼────┐          ┌────▼────┐
         |PROMETHEUS|         | GRAFANA |
         |  :9090  |         |  :3001  |
         └─────────┘          └─────────┘
```

## 🚀 Quick Start

### Pre-requisitos
- Docker & Docker Compose

### 1. Clone e suba tudo

```bash
git clone https://github.com/cbr05/devops-test.git
cd devops-test

# Subir toda a infraestrutura
docker-compose up -d --build

# Verificar status
docker-compose ps

# Ver logs
docker-compose logs -f
```

### 2. Acesse os servicos

| Servico    | URL                      | Credenciais    |
|------------|--------------------------|----------------|
| App 1      | http://localhost:8001    | -              |
| App 2      | http://localhost:8002    | -              |
| Nginx      | http://localhost:8080    | -              |
| Prometheus | http://localhost:9090    | -              |
| Grafana    | http://localhost:3001    | admin/admin123 |

### 3. Testar as rotas

```bash
# App 1 - Texto fixo (cache 10s)
curl http://localhost:8001/text

# App 1 - Horario atual (cache 10s)
curl http://localhost:8001/time

# App 2 - Texto fixo (cache 60s)
curl http://localhost:8002/text

# App 2 - Horario atual (cache 60s)
curl http://localhost:8002/time

# Via Nginx
curl http://localhost:8080/app1/text
curl http://localhost:8080/app2/text
```

## 📁 Estrutura do Projeto

```
.
├── app1/                  # Python FastAPI
│   ├── .dockerignore
│   ├── app.py            # Codigo principal
│   ├── requirements.txt  # Dependencias Python
│   ├── test_app.py       # Testes unitarios
│   └── Dockerfile
├── app2/                  # Go
│   ├── .dockerignore
│   ├── main.go           # Codigo principal
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── redis/
│   └── redis.conf        # Configuracao Redis
├── nginx/
│   └── nginx.conf        # Configuracao Nginx
├── monitoring/
│   ├── prometheus.yml
│   └── grafana/
│       └── provisioning/
│           ├── datasources/
│           └── dashboards/
├── docs/
│   ├── architecture.drawio  # Diagrama editavel
│   └── diagram.svg       # Diagrama ASCII (legado)
├── scripts/
│   ├── Dockerfile        # Load generator
│   └── loadgen.sh
├── docker-compose.yml
├── Makefile
├── README.md
├── .editorconfig
└── .gitignore
```

## 🔧 Comandos Uteis

```bash
# Make (Unix/Linux)
make up              # Subir tudo
make down            # Derrubar tudo
make logs            # Ver logs
make test            # Testar rotas
make clean           # Limpar containers e volumes

# Docker direto (qualquer SO)
docker-compose up -d --build
docker-compose down -v
docker-compose logs -f app1
```

## 📊 Observabilidade

### Metricas Prometheus

| Metrica                         | Descricao                |
|---------------------------------|--------------------------|
| `http_requests_total`           | Total de requisicoes HTTP |
| `http_request_duration_seconds` | Latencia das requisicoes |
| `cache_hits_total`              | Total de cache hits      |
| `cache_misses_total`            | Total de cache misses    |

### Health Checks

```bash
curl http://localhost:8001/health
curl http://localhost:8002/health
```

## 💡 Pontos de Melhoria

**Orquestração**
- Migrar para Kubernetes com Deployments, Services e HPA(Horizontal Pod Autoscaler) para escalonamento automático por CPU/memória
- Usar Helm charts para facilitar deploys em múltiplos ambientes (dev/staging/prod)

**Alta Disponibilidade**
- Redis Sentinel ou Redis Cluster para eliminar o single point of failure na camada de cache
- Múltiplas réplicas das aplicações com balanceamento de carga

**Segurança**
- Gerenciamento de secrets com HashiCorp Vault ou Kubernetes Secrets (sem senha hardcoded)
- TLS/HTTPS com cert-manager e Let's Encrypt

**CI/CD**
- Pipeline com GitHub Actions: build, testes, lint e push de imagem para registry
- Deploy automático ao merge na branch principal

**Observabilidade**
- Alertas no AlertManager integrado ao Prometheus
- Centralização de logs com Loki ou ELK Stack

## 👤 Autor

Cleber - DevOps Test
