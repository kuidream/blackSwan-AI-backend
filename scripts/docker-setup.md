# Docker PostgreSQL 安装指南

## 前提条件

确保已安装 Docker Desktop for Windows

- 下载: https://www.docker.com/products/docker-desktop/
- 安装后需要重启计算机

## 快速启动 PostgreSQL

### 1. 启动 PostgreSQL 容器

```powershell
# 创建并启动 PostgreSQL 容器
docker run --name blackswan-postgres `
  -e POSTGRES_PASSWORD=blackswan2024 `
  -e POSTGRES_DB=blackswan `
  -p 5432:5432 `
  -v blackswan-pgdata:/var/lib/postgresql/data `
  -d postgres:15
```

参数说明:
- `--name blackswan-postgres`: 容器名称
- `-e POSTGRES_PASSWORD`: 设置 postgres 用户密码
- `-e POSTGRES_DB`: 自动创建数据库
- `-p 5432:5432`: 端口映射
- `-v blackswan-pgdata`: 数据持久化卷
- `-d postgres:15`: 使用 PostgreSQL 15 镜像

### 2. 验证容器运行

```powershell
# 查看运行中的容器
docker ps

# 查看容器日志
docker logs blackswan-postgres

# 检查容器状态
docker inspect blackswan-postgres
```

### 3. 连接数据库

```powershell
# 使用 docker exec 连接
docker exec -it blackswan-postgres psql -U postgres -d blackswan

# 在 psql 中可以执行 SQL
\dt          # 查看所有表
\l           # 查看所有数据库
\q           # 退出
```

## 配置项目

### 1. 创建 .env 文件

```powershell
Copy-Item .env.example .env
```

### 2. 编辑 .env

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=blackswan2024
DB_NAME=blackswan
DB_SSL_MODE=disable
```

### 3. 编辑 atlas.hcl

```hcl
env "local" {
  src = "file://.ai/database/schema.sql"
  url = "postgres://postgres:blackswan2024@localhost:5432/blackswan?sslmode=disable"
}
```

## 使用 Atlas 初始化数据库

```powershell
# 预览 Schema 变更
.\atlas.exe schema apply --env local --dry-run

# 应用 Schema
.\atlas.exe schema apply --env local
```

## Docker 容器管理

### 启动/停止/重启

```powershell
# 停止容器
docker stop blackswan-postgres

# 启动容器
docker start blackswan-postgres

# 重启容器
docker restart blackswan-postgres
```

### 查看日志

```powershell
# 查看所有日志
docker logs blackswan-postgres

# 实时查看日志
docker logs -f blackswan-postgres

# 查看最后 100 行
docker logs --tail 100 blackswan-postgres
```

### 删除容器（保留数据）

```powershell
# 停止并删除容器
docker stop blackswan-postgres
docker rm blackswan-postgres

# 重新创建（使用相同的数据卷）
docker run --name blackswan-postgres `
  -e POSTGRES_PASSWORD=blackswan2024 `
  -e POSTGRES_DB=blackswan `
  -p 5432:5432 `
  -v blackswan-pgdata:/var/lib/postgresql/data `
  -d postgres:15
```

### 完全删除（包括数据）

```powershell
# 删除容器
docker stop blackswan-postgres
docker rm blackswan-postgres

# 删除数据卷
docker volume rm blackswan-pgdata
```

## 使用 Docker Compose（推荐）

### 创建 docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: blackswan-postgres
    environment:
      POSTGRES_DB: blackswan
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: blackswan2024
    ports:
      - "5432:5432"
    volumes:
      - blackswan-pgdata:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: blackswan-redis
    ports:
      - "6379:6379"
    volumes:
      - blackswan-redis:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  blackswan-pgdata:
  blackswan-redis:
```

### 使用 Docker Compose

```powershell
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止所有服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v
```

## 数据备份与恢复

### 备份数据库

```powershell
# 备份到文件
docker exec blackswan-postgres pg_dump -U postgres blackswan > backup.sql

# 或使用 pg_dumpall 备份所有数据库
docker exec blackswan-postgres pg_dumpall -U postgres > backup_all.sql
```

### 恢复数据库

```powershell
# 从备份文件恢复
docker exec -i blackswan-postgres psql -U postgres blackswan < backup.sql
```

## 常见问题

### Q1: 端口冲突

如果端口 5432 已被占用:

```powershell
# 使用不同端口
docker run --name blackswan-postgres `
  -e POSTGRES_PASSWORD=blackswan2024 `
  -e POSTGRES_DB=blackswan `
  -p 5433:5432 `
  -v blackswan-pgdata:/var/lib/postgresql/data `
  -d postgres:15

# 更新 atlas.hcl 中的端口为 5433
```

### Q2: 容器无法启动

```powershell
# 查看详细错误信息
docker logs blackswan-postgres

# 检查容器状态
docker inspect blackswan-postgres
```

### Q3: 数据丢失

使用命名卷 (`-v blackswan-pgdata`) 可以确保数据持久化，即使删除容器也不会丢失数据。

### Q4: 性能优化

```powershell
# 增加共享内存（对大型数据库有帮助）
docker run --name blackswan-postgres `
  -e POSTGRES_PASSWORD=blackswan2024 `
  -e POSTGRES_DB=blackswan `
  -p 5432:5432 `
  -v blackswan-pgdata:/var/lib/postgresql/data `
  --shm-size=256mb `
  -d postgres:15
```

## 优势对比

| 特性 | 本地安装 | Docker |
|------|---------|--------|
| 安装速度 | 慢 | 快 |
| 占用空间 | 大 | 小 |
| 版本切换 | 困难 | 容易 |
| 多版本共存 | 困难 | 容易 |
| 数据隔离 | 差 | 好 |
| 学习曲线 | 低 | 中 |

## 推荐

- **开发环境**: 使用 Docker（灵活、易管理）
- **生产环境**: 使用专业数据库服务（AWS RDS、阿里云 RDS 等）
