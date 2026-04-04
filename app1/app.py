"""
App 1 - Python FastAPI com Redis Cache (10 segundos)
"""
import os
import time
import logging
from datetime import datetime
from typing import Optional

import redis
from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuracao
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "redis123")
CACHE_TTL = int(os.getenv("CACHE_TTL", "10"))  # 10 segundos
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

# Conexao Redis
redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    password=REDIS_PASSWORD,
    decode_responses=True,
    socket_connect_timeout=5,
    socket_timeout=5
)

# Metricas Prometheus
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

cache_hits_total = Counter('cache_hits_total', 'Total cache hits', ['endpoint'])
cache_misses_total = Counter('cache_misses_total', 'Total cache misses', ['endpoint'])

# FastAPI app
app = FastAPI(
    title="App 1 - Python FastAPI",
    description="API com cache Redis de 10 segundos",
    version=APP_VERSION
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_cache(key: str) -> Optional[str]:
    """Busca valor no cache Redis."""
    try:
        value = redis_client.get(key)
        if value:
            cache_hits_total.labels(endpoint=key).inc()
            logger.info(f"Cache HIT for key: {key}")
            return value
        cache_misses_total.labels(endpoint=key).inc()
        logger.info(f"Cache MISS for key: {key}")
        return None
    except redis.RedisError as e:
        logger.error(f"Redis error: {e}")
        cache_misses_total.labels(endpoint=key).inc()
        return None


def set_cache(key: str, value: str, ttl: int = CACHE_TTL):
    """Armazena valor no cache Redis."""
    try:
        redis_client.setex(key, ttl, value)
        logger.info(f"Cache SET for key: {key}, TTL: {ttl}s")
    except redis.RedisError as e:
        logger.error(f"Redis error setting cache: {e}")


@app.get("/")
def root():
    """Rota raiz com info da aplicacao."""
    return {
        "app": "App 1 - Python FastAPI",
        "version": APP_VERSION,
        "cache_ttl": f"{CACHE_TTL} segundos",
        "endpoints": {
            "text": "/text",
            "time": "/time",
            "health": "/health",
            "metrics": "/metrics"
        }
    }


@app.get("/text")
def get_text():
    """Retorna texto fixo (cache 10s)."""
    start_time = time.time()
    
    # Tenta buscar no cache
    cached = get_cache("app1:text")
    if cached:
        duration = time.time() - start_time
        http_request_duration_seconds.labels("GET", "/text").observe(duration)
        http_requests_total.labels("GET", "/text", "200").inc()
        return {"source": "cache", "text": cached, "cached": True}
    
    # Texto fixo
    text = "Ola! Eu sou a App 1 em Python com FastAPI. Meu cache expira em 10 segundos."
    
    # Armazena no cache
    set_cache("app1:text", text)
    
    duration = time.time() - start_time
    http_request_duration_seconds.labels("GET", "/text").observe(duration)
    http_requests_total.labels("GET", "/text", "200").inc()
    
    return {"source": "computed", "text": text, "cached": False}


@app.get("/time")
def get_time():
    """Retorna horario atual do servidor (cache 10s)."""
    start_time = time.time()
    
    # Tenta buscar no cache
    cached = get_cache("app1:time")
    if cached:
        duration = time.time() - start_time
        http_request_duration_seconds.labels("GET", "/time").observe(duration)
        http_requests_total.labels("GET", "/time", "200").inc()
        return {"source": "cache", "time": cached, "cached": True}
    
    # Horario atual
    now = datetime.now().isoformat()
    
    # Armazena no cache
    set_cache("app1:time", now)
    
    duration = time.time() - start_time
    http_request_duration_seconds.labels("GET", "/time").observe(duration)
    http_requests_total.labels("GET", "/time", "200").inc()
    
    return {"source": "computed", "time": now, "cached": False}


@app.get("/health")
def health_check():
    """Health check endpoint."""
    redis_status = "healthy"
    try:
        redis_client.ping()
    except redis.RedisError:
        redis_status = "unhealthy"
    
    return {
        "status": "healthy",
        "app": "app1",
        "version": APP_VERSION,
        "redis": redis_status
    }


@app.get("/cache/clear")
def clear_cache():
    """Remove as chaves de cache desta aplicação."""
    try:
        deleted = redis_client.delete("app1:text", "app1:time")
        return {"status": "success", "message": f"{deleted} chave(s) removida(s)"}
    except redis.RedisError as e:
        return {"status": "error", "message": str(e)}


@app.get("/metrics")
def metrics():
    """Endpoint de metricas para Prometheus."""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
