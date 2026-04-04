package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/redis/go-redis/v9"
)

var (
	// Config
	redisHost     = getEnv("REDIS_HOST", "redis")
	redisPort     = getEnv("REDIS_PORT", "6379")
	redisPassword = getEnv("REDIS_PASSWORD", "redis123")
	cacheTTL      = getEnvInt("CACHE_TTL", 60) // 60 segundos
	appVersion    = getEnv("APP_VERSION", "1.0.0")

	// Redis client
	ctx    = context.Background()
	redisClient = redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", redisHost, redisPort),
		Password: redisPassword,
		DB:       0,
	})

	// Metricas Prometheus
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)

	cacheHitsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "cache_hits_total",
			Help: "Total number of cache hits",
		},
		[]string{"endpoint"},
	)

	cacheMissesTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "cache_misses_total",
			Help: "Total number of cache misses",
		},
		[]string{"endpoint"},
	)
)

func init() {
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
	prometheus.MustRegister(cacheHitsTotal)
	prometheus.MustRegister(cacheMissesTotal)
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		var intValue int
		fmt.Sscanf(value, "%d", &intValue)
		return intValue
	}
	return defaultValue
}

// Response structure
type Response struct {
	Source  string `json:"source"`
	Text    string `json:"text,omitempty"`
	Time    string `json:"time,omitempty"`
	Cached  bool   `json:"cached"`
}

type HealthResponse struct {
	Status  string `json:"status"`
	App     string `json:"app"`
	Version string `json:"version"`
	Redis   string `json:"redis"`
}

// getCache retrieves value from Redis cache
func getCache(key string) (string, bool) {
	val, err := redisClient.Get(ctx, key).Result()
	if err == redis.Nil {
		cacheMissesTotal.WithLabelValues(key).Inc()
		log.Printf("Cache MISS for key: %s", key)
		return "", false
	} else if err != nil {
		log.Printf("Redis error: %v", err)
		cacheMissesTotal.WithLabelValues(key).Inc()
		return "", false
	}
	cacheHitsTotal.WithLabelValues(key).Inc()
	log.Printf("Cache HIT for key: %s", key)
	return val, true
}

// setCache stores value in Redis cache
func setCache(key, value string) {
	err := redisClient.Set(ctx, key, value, time.Duration(cacheTTL)*time.Second).Err()
	if err != nil {
		log.Printf("Redis error setting cache: %v", err)
	} else {
		log.Printf("Cache SET for key: %s, TTL: %d seconds", key, cacheTTL)
	}
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"app":       "App 2 - Go",
		"version":   appVersion,
		"cache_ttl": fmt.Sprintf("%d segundos", cacheTTL),
		"endpoints": map[string]string{
			"text":    "/text",
			"time":    "/time",
			"health":  "/health",
			"metrics": "/metrics",
		},
	})
	
	httpRequestsTotal.WithLabelValues(r.Method, "/", "200").Inc()
	httpRequestDuration.WithLabelValues(r.Method, "/").Observe(time.Since(start).Seconds())
}

func textHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	
	w.Header().Set("Content-Type", "application/json")
	
	// Tenta buscar no cache
	if cached, ok := getCache("app2:text"); ok {
		json.NewEncoder(w).Encode(Response{
			Source: "cache",
			Text:   cached,
			Cached: true,
		})
		httpRequestsTotal.WithLabelValues(r.Method, "/text", "200").Inc()
		httpRequestDuration.WithLabelValues(r.Method, "/text").Observe(time.Since(start).Seconds())
		return
	}
	
	// Texto fixo
	text := "Ola! Eu sou a App 2 em Go. Meu cache expira em 60 segundos."
	
	// Armazena no cache
	setCache("app2:text", text)
	
	json.NewEncoder(w).Encode(Response{
		Source: "computed",
		Text:   text,
		Cached: false,
	})
	
	httpRequestsTotal.WithLabelValues(r.Method, "/text", "200").Inc()
	httpRequestDuration.WithLabelValues(r.Method, "/text").Observe(time.Since(start).Seconds())
}

func timeHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	
	w.Header().Set("Content-Type", "application/json")
	
	// Tenta buscar no cache
	if cached, ok := getCache("app2:time"); ok {
		json.NewEncoder(w).Encode(Response{
			Source: "cache",
			Time:   cached,
			Cached: true,
		})
		httpRequestsTotal.WithLabelValues(r.Method, "/time", "200").Inc()
		httpRequestDuration.WithLabelValues(r.Method, "/time").Observe(time.Since(start).Seconds())
		return
	}
	
	// Horario atual
	now := time.Now().Format(time.RFC3339)
	
	// Armazena no cache
	setCache("app2:time", now)
	
	json.NewEncoder(w).Encode(Response{
		Source: "computed",
		Time:   now,
		Cached: false,
	})
	
	httpRequestsTotal.WithLabelValues(r.Method, "/time", "200").Inc()
	httpRequestDuration.WithLabelValues(r.Method, "/time").Observe(time.Since(start).Seconds())
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	redisStatus := "healthy"
	if _, err := redisClient.Ping(ctx).Result(); err != nil {
		redisStatus = "unhealthy"
	}
	
	json.NewEncoder(w).Encode(HealthResponse{
		Status:  "healthy",
		App:     "app2",
		Version: appVersion,
		Redis:   redisStatus,
	})
}

func metricsHandler(w http.ResponseWriter, r *http.Request) {
	promhttp.Handler().ServeHTTP(w, r)
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s", r.Method, r.URL.Path)
		next.ServeHTTP(w, r)
	})
}

func main() {
	// Test Redis connection
	_, err := redisClient.Ping(ctx).Result()
	if err != nil {
		log.Printf("Warning: Redis connection failed: %v", err)
	} else {
		log.Println("Connected to Redis successfully")
	}

	// Setup routes
	mux := http.NewServeMux()
	mux.HandleFunc("/", rootHandler)
	mux.HandleFunc("/text", textHandler)
	mux.HandleFunc("/time", timeHandler)
	mux.HandleFunc("/health", healthHandler)
	mux.Handle("/metrics", promhttp.Handler())

	// Apply logging middleware
	handler := loggingMiddleware(mux)

	log.Printf("Starting App 2 on port 8002 (cache TTL: %d seconds)", cacheTTL)
	log.Fatal(http.ListenAndServe(":8002", handler))
}
