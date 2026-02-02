.PHONY: run build test clean help

help:
	@echo "Available commands:"
	@echo "  make run      - Run the server"
	@echo "  make build    - Build the binary"
	@echo "  make test     - Run tests"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make deps     - Download dependencies"

run:
	go run cmd/api/main.go

build:
	go build -o bin/server cmd/api/main.go

test:
	go test -v ./...

clean:
	rm -rf bin/
	go clean

deps:
	go mod download
	go mod tidy
