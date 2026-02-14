# blackSwan Backend - 快速开始

一个基于现实映射的自动演进式 RPG 游戏后端系统

## 环境要求

- Docker Desktop
- Go 1.21+
- Git

## 一键启动 (推荐)

```powershell
# 1. 克隆项目
git clone <repository-url>
cd blackSwan-AI-backend

# 2. 启动环境
docker-compose up -d          # 启动数据库和缓存
.\scripts\init-db.ps1         # 初始化数据库

# 3. 启动后端
go run cmd/api/main.go

# 访问 http://localhost:8080/health
```

## 使用 Makefile (更简单)

```powershell
make up          # 启动 Docker 服务
make db-init     # 初始化数据库
make run         # 启动后端服务

# 其他命令
make help        # 查看所有命令
make logs        # 查看日志
make db-reset    # 重置数据库
make tools       # 启动管理工具
```

## 验证环境

```powershell
# 检查服务状态
docker-compose ps

# 测试 API
curl http://localhost:8080/health
curl http://localhost:8080/v1/ping
```

## 管理工具 (可选)

```powershell
make tools

# 访问
# pgAdmin:         http://localhost:5050
# Redis Commander: http://localhost:8081
```

## 项目结构

```
blackSwan-AI-backend/
├── cmd/api/              # 应用入口
├── internal/             # 核心代码
│   ├── domain/          # 领域模型
│   ├── usecase/         # 业务逻辑
│   ├── repository/      # 数据访问
│   ├── transport/       # HTTP/WebSocket
│   └── config/          # 配置
├── .ai/                 # AI 工具文档
│   ├── docs/           # 架构文档
│   ├── database/       # 数据库 Schema
│   └── api/            # API 文档
└── scripts/            # 开发脚本
```

## 开发指南

- 完整开发指南: `DEVELOPMENT.md`
- Docker 配置: `README.Docker.md`
- 环境配置: `scripts/dev-setup.md`
- 编码规范: `.cursorrules`

## 技术栈

- **语言**: Go 1.21+
- **框架**: Gin (HTTP), GORM (ORM)
- **数据库**: PostgreSQL 15
- **缓存**: Redis 7
- **AI**: OpenAI API

## 核心特性

- 基于 IoT 数据的现实映射
- AI 驱动的世界演进
- 动态市场博弈系统
- San 值精神状态管理
- NPC 互动系统

## 环境变量

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

# LLM
LLM_API_KEY=your_api_key_here
```

## 常见问题

### Docker 无法启动
确保 WSL 2 已安装: `wsl --update`

### 端口被占用
修改 `docker-compose.yml` 中的端口映射

### 数据库连接失败
检查容器状态: `docker-compose ps`

详细故障排查: `scripts/dev-setup.md`

## 团队协作

确保所有成员使用相同的:
- Docker 配置 (docker-compose.yml)
- 环境变量模板 (.env.docker)
- 数据库 Schema (.ai/database/schema.sql)

## 贡献指南

1. 阅读编码规范 (.cursorrules)
2. 遵守三大铁律 (AGENTS.md)
3. 编写测试
4. 更新文档

## License

[待定]

## 联系方式

[待定]

---

**快速开始**: 3 个命令，5 分钟启动！

```powershell
docker-compose up -d && .\scripts\init-db.ps1 && go run cmd/api/main.go
```
