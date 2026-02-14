# 开发环境统一配置指南

本指南帮助你在公司电脑和个人电脑上建立完全一致的开发环境。

## 前提条件

确保两台电脑都安装了以下工具：

### 必需工具
- [x] Docker Desktop: https://www.docker.com/products/docker-desktop/
- [x] Git: https://git-scm.com/download/win
- [x] Go 1.21+: https://go.dev/dl/

### 可选工具
- [ ] VS Code 或 Cursor IDE
- [ ] Postman 或 Insomnia (API 测试)

## 一键启动开发环境

### 步骤 1: 安装 Docker Desktop

**下载地址**: https://www.docker.com/products/docker-desktop/

**安装后**:
1. 启动 Docker Desktop
2. 等待 Docker 引擎启动（托盘图标变为绿色）
3. 验证安装:
   ```powershell
   docker --version
   docker-compose --version
   ```

### 步骤 2: 克隆项目（如果还没有）

```powershell
git clone <repository-url>
cd blackSwan-AI-backend
```

### 步骤 3: 配置环境变量

```powershell
# 使用 Docker 配置模板
Copy-Item .env.docker .env
```

或手动创建 `.env` 文件，内容参考 `.env.docker`。

### 步骤 4: 启动所有服务

```powershell
# 启动 PostgreSQL 和 Redis
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

预期输出:
```
NAME                   IMAGE              STATUS         PORTS
blackswan-postgres     postgres:15        Up (healthy)   0.0.0.0:5432->5432/tcp
blackswan-redis        redis:7-alpine     Up (healthy)   0.0.0.0:6379->6379/tcp
```

### 步骤 5: 初始化数据库

使用 PowerShell 脚本应用数据库 Schema:

```powershell
# 方式 1: 使用 Makefile
make db-init

# 方式 2: 直接运行脚本
.\scripts\init-db.ps1

# 方式 3: 手动执行
$OutputEncoding = [System.Text.Encoding]::UTF8
Get-Content -Encoding UTF8 .\.ai\database\schema.sql | docker exec -i blackswan-postgres psql -U postgres -d blackswan
```

### 步骤 6: 启动后端服务

```powershell
# 下载 Go 依赖
go mod download

# 启动服务
go run cmd/api/main.go
```

服务启动后访问:
- API 服务: http://localhost:8080
- 健康检查: http://localhost:8080/health

## 启用管理工具（可选）

如果需要图形化管理界面:

```powershell
# 启动管理工具
docker-compose --profile tools up -d

# 访问管理界面
# pgAdmin: http://localhost:5050
#   - Email: admin@blackswan.local
#   - Password: admin
#
# Redis Commander: http://localhost:8081
```

### 在 pgAdmin 中添加服务器连接

1. 访问 http://localhost:5050
2. 登录（见上面的凭据）
3. Add New Server:
   - Name: blackSwan Local
   - Host: postgres (Docker 内部网络名)
   - Port: 5432
   - Username: postgres
   - Password: blackswan2024

## 日常开发工作流

### 启动开发环境

```powershell
# 1. 启动 Docker 服务
docker-compose up -d

# 2. 启动后端
go run cmd/api/main.go
```

### 停止开发环境

```powershell
# 停止后端: Ctrl+C

# 停止 Docker 服务（保留数据）
docker-compose stop

# 或完全关闭（保留数据）
docker-compose down
```

### 重置开发环境

```powershell
# 停止并删除容器和数据
docker-compose down -v

# 重新启动
docker-compose up -d

# 重新初始化数据库
.\atlas.exe schema apply --env local
```

## 数据库操作

### 连接数据库

```powershell
# 方式 1: 使用 docker exec
docker exec -it blackswan-postgres psql -U postgres -d blackswan

# 方式 2: 如果安装了 psql 客户端
psql -h localhost -U postgres -d blackswan
```

### 查看数据库状态

```sql
-- 查看所有表
\dt

-- 查看表结构
\d player

-- 查看索引
\di

-- 退出
\q
```

### 备份数据库

```powershell
# 备份到文件
docker exec blackswan-postgres pg_dump -U postgres blackswan > backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql
```

### 恢复数据库

```powershell
# 从备份恢复
docker exec -i blackswan-postgres psql -U postgres blackswan < backup_20260214_143000.sql
```

## Redis 操作

### 连接 Redis

```powershell
# 使用 docker exec
docker exec -it blackswan-redis redis-cli

# 常用命令
PING           # 测试连接
KEYS *         # 查看所有键
GET key        # 获取值
FLUSHALL       # 清空所有数据（慎用）
```

## 故障排查

### 问题 1: Docker Desktop 无法启动

**检查**:
- WSL 2 是否安装: `wsl --list --verbose`
- 虚拟化是否启用: 任务管理器 -> 性能 -> CPU -> 虚拟化

**解决**:
```powershell
# 更新 WSL
wsl --update

# 设置 WSL 2 为默认
wsl --set-default-version 2
```

### 问题 2: 端口被占用

**检查端口占用**:
```powershell
# PostgreSQL 端口
netstat -ano | findstr :5432

# Redis 端口
netstat -ano | findstr :6379
```

**解决方案 1**: 关闭占用端口的程序

**解决方案 2**: 修改 docker-compose.yml 中的端口映射
```yaml
ports:
  - "5433:5432"  # 使用 5433 代替 5432
```

### 问题 3: 容器无法启动

```powershell
# 查看详细日志
docker-compose logs postgres
docker-compose logs redis

# 重建容器
docker-compose up -d --force-recreate
```

### 问题 4: 数据库连接失败

**检查清单**:
1. Docker 容器是否运行: `docker-compose ps`
2. 容器是否健康: `docker inspect blackswan-postgres | Select-String health`
3. 密码是否正确: 检查 `.env` 和 `atlas.hcl`
4. 防火墙是否阻止: 临时关闭防火墙测试

## 环境一致性检查清单

确保两台电脑配置完全一致:

- [ ] Docker Desktop 版本一致
- [ ] Go 版本一致
- [ ] docker-compose.yml 文件一致
- [ ] .env 配置一致（除了 API Key）
- [ ] atlas.hcl 配置一致
- [ ] 数据库 Schema 一致

## 团队协作建议

### Git 忽略文件

确保 `.gitignore` 包含:
```
.env
.env.local
*.sql  # 备份文件
atlas.exe
```

### 共享配置

提交到 Git:
- [x] docker-compose.yml
- [x] .env.docker (模板)
- [x] atlas.hcl
- [x] .ai/database/schema.sql

不提交到 Git:
- [ ] .env (包含密钥)
- [ ] 数据库备份文件
- [ ] 本地日志文件

## 快捷命令

创建一个 `Makefile` 或 PowerShell 脚本简化操作:

```makefile
# Makefile
.PHONY: up down restart logs db-init db-reset

up:
	docker-compose up -d
	@echo "Services started. Run 'make logs' to view logs."

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

db-init:
	.\atlas.exe schema apply --env local

db-reset:
	docker-compose down -v
	docker-compose up -d
	timeout /t 5
	.\atlas.exe schema apply --env local

tools:
	docker-compose --profile tools up -d
```

使用方式:
```powershell
make up        # 启动服务
make logs      # 查看日志
make db-init   # 初始化数据库
make db-reset  # 重置数据库
```

## 下一步

环境配置完成后，查看:
- 开发指南: `DEVELOPMENT.md`
- API 文档: `.ai/api/api-reference.md`
- 架构文档: `.ai/docs/01-architecture.md`
