package config

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	LLM      LLMConfig
}

type ServerConfig struct {
	Port         int
	Mode         string
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
	IdleTimeout  time.Duration
}

type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
	SSLMode  string
	MaxConns int
	MaxIdle  int
}

type RedisConfig struct {
	Host     string
	Port     int
	Password string
	DB       int
}

type LLMConfig struct {
	Provider string
	APIKey   string
	Model    string
	BaseURL  string
}

// Load reads configuration from environment variables
func Load() (*Config, error) {
	// Try to load .env file (ignore error if file doesn't exist)
	_ = godotenv.Load()

	cfg := &Config{
		Server: ServerConfig{
			Port:         getEnvAsInt("SERVER_PORT", 8080),
			Mode:         getEnv("SERVER_MODE", "debug"),
			ReadTimeout:  time.Duration(getEnvAsInt("SERVER_READ_TIMEOUT", 10)) * time.Second,
			WriteTimeout: time.Duration(getEnvAsInt("SERVER_WRITE_TIMEOUT", 10)) * time.Second,
			IdleTimeout:  time.Duration(getEnvAsInt("SERVER_IDLE_TIMEOUT", 120)) * time.Second,
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnvAsInt("DB_PORT", 5432),
			User:     getEnv("DB_USER", "postgres"),
			Password: getEnv("DB_PASSWORD", ""),
			DBName:   getEnv("DB_NAME", "blackswan"),
			SSLMode:  getEnv("DB_SSL_MODE", "disable"),
			MaxConns: getEnvAsInt("DB_MAX_CONNS", 25),
			MaxIdle:  getEnvAsInt("DB_MAX_IDLE", 10),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnvAsInt("REDIS_PORT", 6379),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
		},
		LLM: LLMConfig{
			Provider: getEnv("LLM_PROVIDER", "openai"),
			APIKey:   getEnv("LLM_API_KEY", ""),
			Model:    getEnv("LLM_MODEL", "gpt-4o-mini"),
			BaseURL:  getEnv("LLM_BASE_URL", ""),
		},
	}

	return cfg, nil
}

// getEnv retrieves environment variable with fallback
func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

// getEnvAsInt retrieves environment variable as integer with fallback
func getEnvAsInt(key string, fallback int) int {
	if value, exists := os.LookupEnv(key); exists {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return fallback
}

// DSN returns PostgreSQL connection string
func (d *DatabaseConfig) DSN() string {
	return fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		d.Host, d.Port, d.User, d.Password, d.DBName, d.SSLMode,
	)
}

// RedisAddr returns Redis connection address
func (r *RedisConfig) Addr() string {
	return fmt.Sprintf("%s:%d", r.Host, r.Port)
}
