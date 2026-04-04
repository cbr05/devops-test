# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Dependências Go
COPY go.mod go.sum ./
RUN go mod download

# Código
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -o app main.go

# Runtime stage
FROM alpine:3.19

WORKDIR /app

# Instala curl para healthcheck
RUN apk add --no-cache ca-certificates curl

# Copia binário do builder
COPY --from=builder /app/app .

# Usuário não-root
RUN adduser -D -u 1000 appuser
USER appuser

EXPOSE 8002

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8002/health || exit 1

CMD ["./app"]
