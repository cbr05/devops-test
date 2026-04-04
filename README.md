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
│       ├── dashboards/
│       │   └── overview.json
│       └── provisioning/
│           ├── datasources/
│           └── dashboards/
├── k8s/                   # Kubernetes manifests
│   ├── namespace.yaml
│   ├── redis.yaml
│   ├── app1.yaml
│   ├── app2.yaml
│   ├── nginx.yaml
│   └── monitoring.yaml
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

1. **Alta Disponibilidade**: Redis Sentinel ou Cluster
2. **Escalabilidade**: HPA automatico por CPU/memoria
3. **Seguranca**: Kubernetes Secrets + Vault
4. **CI/CD**: GitHub Actions completo
5. **Alerting**: AlertManager + PagerDuty
6. **Logging**: ELK Stack ou Loki
7. **SSL/TLS**: Cert-manager + Let's Encrypt

## 👤 Autor

Cleber - DevOps Test
