// Atlas configuration for blackSwan backend

// Local development environment
env "local" {
  // Source: SQL schema file (single source of truth)
  src = "file://.ai/database/schema.sql"
  
  // Target: Local PostgreSQL database (Docker)
  url = "postgres://postgres:blackswan2024@localhost:5432/blackswan?sslmode=disable"
  
  // Dev database: Used by Atlas to calculate schema diffs
  dev = "postgres://postgres:blackswan2024@localhost:5432/blackswan_dev?sslmode=disable"
}

// Production environment (example)
env "prod" {
  src = "file://.ai/database/schema.sql"
  
  // Production database URL (should be set via environment variable)
  url = env("ATLAS_DB_URL")
  
  // Dev database for production migrations
  dev = "docker://postgres/15/dev?search_path=public"
  
  diff {
    skip {
      drop_table = true
      drop_column = true
    }
  }
}
