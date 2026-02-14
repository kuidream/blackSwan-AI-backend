# Docker 快速启动指南

本项目使用 Docker Compose 管理开发环境，确保所有开发者的环境完全一致。

## 快速开始

### 1. 安装 Docker Desktop

下载并安装: https://www.docker.com/products/docker-desktop/

### 2. 启动开发环境

```powershell
# 克隆项目
git clone <repository-url>
cd blackSwan-AI-backend

# 配置环境变量
Copy-Item .env.docker .env

# 启动所有服务
docker-compose up -d

# 初始化数据库
.\atlas.exe schema apply --env local

# 启动后端
go run cmd/api/main.go
```

## 服务列表

启动后，以下服务将可用：

| 服务 | 端口 | 用途 |
|------|------|------|
| PostgreSQL | 5432 | 主数据库 |
| Redis | 6379 | 缓存和会话 |
| API Server | 8080 | 后端服务 |

### 可选管理工具

```powershell
# 启动管理界面
docker-compose --profile tools up -d
```

| 工具 | 地址 | 凭据 |
|------|------|------|
| pgAdmin | http://localhost:5050 | admin@blackswan.local / admin |
| Redis Commander | http://localhost:8081 | 无需登录 |

## 使用 Makefile

项目提供了 Makefile 简化常用操作：

```powershell
make help       # 查看所有命令
make up         # 启动服务
make logs       # 查看日志
make db-init    # 初始化数据库
make db-reset   # 重置数据库
make tools      # 启动管理工具
```

## 数据持久化

数据存储在 Docker 命名卷中，即使删除容器也不会丢失：

- `blackswan_postgres_data`: PostgreSQL 数据
- `blackswan_redis_data`: Redis 数据
- `blackswan_pgadmin_data`: pgAdmin 配置

### 完全重置（包括数据）

```powershell
docker-compose down -v
docker-compose up -d
.\atlas.exe schema apply --env local
```

## 故障排查

### 容器无法启动

```powershell
# 查看日志
docker-compose logs postgres

# 重建容器
docker-compose up -d --force-recreate
```

### 端口冲突

如果 5432 或 6379 端口被占用，修改 `docker-compose.yml`:

```yaml
ports:
  - "5433:5432"  # 使用其他端口
```

然后更新 `.env` 和 `atlas.hcl` 中的端口配置。

### 数据库连接失败

检查容器状态：
```powershell
docker-compose ps
```

所有服务应显示 "Up (healthy)"。

## 详细文档

- 完整开发指南: `scripts/dev-setup.md`
- Docker 详细说明: `scripts/docker-setup.md`
- Atlas 使用指南: `scripts/atlas-guide.md`
- 项目开发规范: `DEVELOPMENT.md`

## 环境变量

主要配置在 `.env` 文件中：

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=blackswan2024
DB_NAME=blackswan

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
```

## 团队协作

确保所有团队成员使用相同的：
- Docker Compose 版本
- 环境变量配置（除了敏感信息）
- 数据库 Schema 版本

提交到 Git:
- ✅ docker-compose.yml
- ✅ .env.docker (模板)
- ✅ Makefile
- ❌ .env (包含密钥)
- ❌ 数据库备份

## 生产部署

Docker Compose 仅用于开发环境。生产环境建议使用：
- 托管数据库服务（AWS RDS、阿里云 RDS 等）
- Kubernetes 或其他容器编排平台
- 专业的缓存服务（Redis Cloud 等）

更多信息请查看 `DEPLOYMENT.md`（待创建）。
