# 开发环境配置指南

## 1. 安装 Go

### Windows

1. 下载 Go 安装包: https://go.dev/dl/
2. 运行安装程序
3. 验证安装:
   ```powershell
   go version
   ```

### macOS

```bash
brew install go
```

### Linux

```bash
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

## 2. 安装 PostgreSQL

### Windows

1. 下载安装包: https://www.postgresql.org/download/windows/
2. 运行安装程序
3. 创建数据库:
   ```sql
   CREATE DATABASE blackswan;
   ```

### macOS

```bash
brew install postgresql@14
brew services start postgresql@14
createdb blackswan
```

### Docker (推荐)

```bash
docker run --name blackswan-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=blackswan \
  -p 5432:5432 \
  -d postgres:14
```

## 3. 安装 Redis

### Windows

使用 WSL 或 下载 Redis for Windows

### macOS

```bash
brew install redis
brew services start redis
```

### Docker (推荐)

```bash
docker run --name blackswan-redis \
  -p 6379:6379 \
  -d redis:7-alpine
```

## 4. 配置项目

```bash
# 复制配置文件
cp .env.example .env

# 编辑配置
# 填入数据库密码、Redis 配置、LLM API Key 等
```

## 5. 初始化数据库

```bash
# TODO: 使用 Atlas 或 GORM AutoMigrate 初始化表结构
# 当前可手动执行 .ai/database/schema.sql
```

## 6. 运行项目

```bash
# 方式 1: 直接运行
go run cmd/api/main.go

# 方式 2: 使用脚本
./scripts/run.sh        # Linux/macOS
./scripts/run.ps1       # Windows PowerShell

# 方式 3: 编译后运行
go build -o bin/server cmd/api/main.go
./bin/server
```

## 7. 验证服务

```bash
# 健康检查
curl http://localhost:8080/health

# API 测试
curl http://localhost:8080/v1/ping
```

## 常见问题

### Go 命令未找到

确保 Go 已正确安装并添加到 PATH:
- Windows: 检查系统环境变量
- Linux/macOS: 添加 `export PATH=$PATH:/usr/local/go/bin` 到 ~/.bashrc 或 ~/.zshrc

### 数据库连接失败

检查:
1. PostgreSQL 服务是否启动
2. .env 中的数据库配置是否正确
3. 数据库是否已创建

### Redis 连接失败

检查:
1. Redis 服务是否启动
2. .env 中的 Redis 配置是否正确
