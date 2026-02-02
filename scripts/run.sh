#!/bin/bash

# blackSwan Backend Startup Script

echo "Starting blackSwan Backend..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Run server
go run cmd/api/main.go
