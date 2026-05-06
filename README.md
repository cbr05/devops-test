# DevOps Technical Test

## Descrição

Teste técnico para vaga DevOps Senior contendo duas aplicações com camada de cache, observabilidade, infraestrutura como código (Terraform) e scanning de segurança.

## Arquitetura

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
         ┌────▼─────┐          ┌────▼────┐
         |PROMETHEUS|          | GRAFANA |
         |  :9090   |          |  :3001  |
         └──────────┘          └─────────┘
```

## Quick Start

### Pré-requisitos

- Docker & Docker Compose
- Terraform >= 1.5 (opcional — para deploy via IaC)

### Via Docker Compose

```bash
git clone https://github.com/cbr05/devops-test.git
cd devops-test

make up       # sobe toda a infraestrutura
make status   # verifica status e health checks
make test     # testa todas as rotas
```

### Via Terraform

```bash
make tf-init    # baixa o provider Docker (kreuzwerker/docker)
make tf-plan    # preview do que será criado
make tf-apply   # cria todos os containers
make tf-output  # lista URLs dos serviços
```

Para destruir:

```bash
make tf-destroy
```

## Serviços

| Serviço       | URL                       | Credenciais    |
|---------------|---------------------------|----------------|
| App 1         | http://localhost:8001     | -              |
| App 2         | http://localhost:8002     | -              |
| Nginx         | http://localhost:8080     | -              |
| Prometheus    | http://localhost:9090     | -              |
| Grafana       | http://localhost:3001     | admin/admin123 |
| Redis         | localhost:6379            | redis123       |

## Estrutura do Projeto

```
.
├── app1/                        # Python FastAPI (cache 10s)
│   ├── app.py
│   ├── test_app.py
│   ├── requirements.txt
│   └── Dockerfile
├── app2/                        # Go (cache 60s)
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── terraform/                   # Infraestrutura como Código
│   ├── main.tf                  # Provider, network, volumes, locals
│   ├── variables.tf             # Variáveis com validação
│   ├── apps.tf                  # module "apps" com for_each
│   ├── redis.tf
│   ├── nginx.tf
│   ├── monitoring.tf
│   ├── loadgen.tf
│   ├── outputs.tf
│   └── modules/
│       └── app/                 # Módulo reutilizável por app
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── monitoring/
│   ├── prometheus.yml
│   └── grafana/
│       └── provisioning/
│           ├── datasources/     # Prometheus provisionado com uid fixo
│           └── dashboards/
├── nginx/
│   └── nginx.conf
├── redis/
│   └── redis.conf
├── scripts/
│   └── Dockerfile               # Load generator
├── docker-compose.yml
├── Makefile
├── .checkov.yaml                # Config Checkov (skip checks de dev)
├── .hadolint.yaml               # Config Hadolint (failure-threshold)
├── .gitleaks.toml               # Allowlist Gitleaks (senhas de dev)
├── .editorconfig
├── .gitignore
└── README.md
```

## Comandos Make

### Infraestrutura (Docker Compose)

```bash
make up          # sobe todos os serviços
make down        # para todos os serviços
make build       # reconstrói imagens sem cache
make restart     # reinicia serviços
make status      # health checks de todos os serviços
make clean       # remove containers, volumes e imagens
```

### Terraform

```bash
make tf-init     # inicializa provider
make tf-validate # valida sintaxe
make tf-fmt      # formata arquivos .tf
make tf-plan     # preview sem aplicar
make tf-apply    # aplica infraestrutura
make tf-destroy  # destrói infraestrutura
make tf-output   # exibe URLs dos serviços
```

### Segurança

```bash
make scan           # executa todos os scans estáticos
make scan-secrets   # Gitleaks — segredos no histórico git
make scan-docker    # Hadolint — lint dos Dockerfiles
make scan-tf        # Checkov — misconfigs no Terraform
make scan-compose   # Checkov — misconfigs no docker-compose.yml
make scan-code      # Bandit (Python) + Gosec (Go)
make scan-tf-plan   # Checkov sobre o plan real do Terraform
make scan-images    # Trivy — CVEs nas imagens (requer make build antes)
```

> Todas as ferramentas rodam via Docker — sem instalação local necessária.
> Execute `make scan` antes de `make tf-apply` ou `make up`.

### Desenvolvimento

```bash
make dev-app1    # sobe apenas App 1 + Redis
make dev-app2    # sobe apenas App 2 + Redis
make logs        # logs de todos os serviços
make logs-app1   # logs do App 1
make test        # testa todas as rotas via curl
make metrics     # exibe métricas Prometheus dos apps
```

## Observabilidade

### Métricas Prometheus

| Métrica                          | Descrição                 |
|----------------------------------|---------------------------|
| `http_requests_total`            | Total de requisições HTTP |
| `http_request_duration_seconds`  | Latência das requisições  |
| `cache_hits_total`               | Total de cache hits       |
| `cache_misses_total`             | Total de cache misses     |

### Health Checks

```bash
curl http://localhost:8001/health
curl http://localhost:8002/health
```

## Segurança

O projeto inclui pipeline de scanning estático com as seguintes ferramentas:

| Ferramenta   | Escopo                         |
|--------------|--------------------------------|
| Gitleaks     | Segredos no histórico git      |
| Hadolint     | Boas práticas em Dockerfiles   |
| Checkov      | Misconfigs em Terraform e Compose |
| Bandit       | Vulnerabilidades no código Python |
| Gosec        | Vulnerabilidades no código Go  |
| Trivy        | CVEs nas imagens buildadas     |

Arquivos de configuração: `.checkov.yaml`, `.hadolint.yaml`, `.gitleaks.toml`.

## Pontos de Melhoria

**Alta Disponibilidade**
- Redis Sentinel ou Redis Cluster para eliminar o single point of failure na camada de cache
- Múltiplas réplicas das aplicações com balanceamento de carga

**Orquestração**
- Migrar para Kubernetes com Deployments, Services e HPA para escalonamento automático
- Helm charts para facilitar deploys em múltiplos ambientes (dev/staging/prod)

**Segurança**
- Gerenciamento de secrets com HashiCorp Vault (sem senha hardcoded em variáveis)
- TLS/HTTPS com cert-manager e Let's Encrypt

**CI/CD**
- Pipeline com GitHub Actions: build, scan, testes e push de imagem para registry
- Deploy automático ao merge na branch principal com gate de segurança (scan obrigatório)

**Observabilidade**
- Alertas no AlertManager integrado ao Prometheus
- Centralização de logs com Loki ou ELK Stack

## Autor

Cleber - DevOps Test
