# 项目结构说明

## 目录组织原则

项目采用 DDD (领域驱动设计) + 清晰分层架构。

## 完整目录结构

```
blackSwan-AI-backend/
│
├── .ai/                              # AI 工具文档（供 Cursor 等 AI 读取）
│   ├── README.md                     # 开发规范总览
│   ├── docs/                         # 核心架构文档
│   │   ├── 01-architecture.md
│   │   ├── 02-world-setting.md
│   │   ├── 03-time-mapping.md
│   │   ├── 04-market-mechanism.md
│   │   ├── 05-tech-implementation.md
│   │   ├── 06-economy-model.md
│   │   └── modules/                  # 模块详细文档
│   │       ├── iot-system.md
│   │       ├── market-system.md
│   │       ├── sanity-system.md
│   │       ├── ai-evolution.md
│   │       └── npc-interaction.md
│   ├── database/
│   │   └── schema.sql                # 数据库 Schema（唯一真理）
│   └── api/
│       └── api-reference.md          # API 接口契约
│
├── cmd/                              # 应用入口
│   └── api/
│       └── main.go                   # 服务启动（含优雅关机）
│
├── internal/                         # 内部代码（不对外暴露）
│   ├── app/                          # 应用组装
│   │   ├── bootstrap/               # 启动时依赖组装
│   │   └── wire/                    # 依赖注入配置
│   │
│   ├── config/                       # 配置管理
│   │   └── config.go                # 环境变量读取
│   │
│   ├── domain/                       # 领域层（业务核心）
│   │   ├── player/                  # 玩家聚合根
│   │   ├── iot/                     # IoT 聚合根
│   │   ├── market/                  # 市场聚合根
│   │   ├── sanity/                  # San 值聚合根
│   │   ├── npc/                     # NPC 聚合根
│   │   └── shared/                  # 共享类型
│   │       ├── errors.go            # 领域错误
│   │       └── types.go             # 共享类型
│   │
│   ├── usecase/                      # 应用服务层（业务编排）
│   │   ├── auth/                    # 认证服务
│   │   ├── iot/                     # IoT 同步服务
│   │   ├── market/                  # 交易服务
│   │   ├── tripx/                   # 单日推进服务
│   │   ├── shop/                    # 商店服务
│   │   └── npc/                     # NPC 互动服务
│   │
│   ├── repository/                   # 仓储层（数据访问）
│   │   ├── gorm/                    # GORM 实现
│   │   └── cache/                   # Redis 缓存
│   │
│   ├── transport/                    # 传输层（接口适配）
│   │   ├── http/
│   │   │   ├── router.go           # Gin 路由
│   │   │   ├── handler/            # HTTP 处理器
│   │   │   ├── middleware/         # 中间件
│   │   │   │   └── middleware.go   # 中间件占位
│   │   │   └── dto/                # 数据传输对象
│   │   │       └── response.go     # 统一响应格式
│   │   └── ws/                      # WebSocket
│   │       ├── hub/                # 连接管理
│   │       └── protocol/           # 消息协议
│   │
│   ├── infra/                        # 基础设施层
│   │   ├── db/                      # 数据库连接
│   │   ├── llm/                     # LLM 客户端
│   │   ├── scheduler/               # 定时任务
│   │   └── observability/           # 日志/监控
│   │
│   └── worker/                       # 后台任务
│       ├── evolution/               # 每日风格生成
│       └── retention/               # 数据清理
│
├── migrations/                       # 数据库迁移脚本
├── api/                             # OpenAPI 文档
├── scripts/                         # 开发脚本
│   ├── run.sh                       # Linux/macOS 启动
│   ├── run.ps1                      # Windows 启动
│   └── setup.md                     # 环境配置指南
│
├── Docs/                            # 原始文档（保留）
├── .cursorrules                     # Cursor 规则
├── AGENTS.md                        # AI 助手指南
├── .env.example                     # 环境变量模板
├── .gitignore                       # Git 忽略
├── go.mod                           # Go 模块
├── Makefile                         # 构建命令
├── README.md                        # 项目说明
├── QUICKSTART.md                    # 快速启动
├── DEVELOPMENT.md                   # 开发指南
├── PROJECT_STATUS.md                # 项目状态
└── SETUP_COMPLETE.md                # 本文件
```

## 依赖关系图

```
                    cmd/api/main.go
                          ↓
              internal/transport/http/
                (handler + middleware)
                          ↓
              internal/usecase/
                (业务编排层)
                          ↓
              internal/domain/
                (领域模型层)
                    ↗     ↖
    internal/repository/   internal/infra/
        (数据访问)           (基础设施)
```

### 依赖规则

**正确的依赖方向**:
```
✅ transport → usecase → domain
✅ usecase → repository
✅ repository → domain
✅ usecase → infra
```

**禁止的依赖方向**:
```
❌ domain → usecase
❌ domain → repository
❌ usecase → transport
❌ repository → usecase
```

## 核心文件说明

### cmd/api/main.go
- 服务启动入口
- 实现优雅关机（Graceful Shutdown）
- 监听系统信号（SIGINT, SIGTERM）
- 30 秒超时等待

### internal/config/config.go
- 统一配置管理
- 从环境变量读取
- 支持 .env 文件
- 提供默认值

### internal/transport/http/router.go
- Gin 路由初始化
- 健康检查接口
- API v1 路由组
- 预留中间件位置

### internal/domain/shared/
- errors.go: 通用领域错误
- types.go: 共享类型（ID, Timestamp）

### internal/transport/http/dto/response.go
- 统一的成功响应格式
- 统一的错误响应格式
- 符合 API 契约规范

## 配置说明

### 环境变量

参考 `.env.example`:

**服务配置**:
- SERVER_PORT: 服务端口（默认 8080）
- SERVER_MODE: 运行模式（debug/release）

**数据库配置**:
- DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
- DB_SSL_MODE, DB_MAX_CONNS, DB_MAX_IDLE

**Redis 配置**:
- REDIS_HOST, REDIS_PORT, REDIS_PASSWORD, REDIS_DB

**LLM 配置**:
- LLM_PROVIDER, LLM_API_KEY, LLM_MODEL, LLM_BASE_URL

## 启动方式

### 开发模式

```bash
# 方式 1: 直接运行
go run cmd/api/main.go

# 方式 2: 使用 Makefile
make run

# 方式 3: 使用脚本
./scripts/run.sh       # Linux/macOS
./scripts/run.ps1      # Windows
```

### 生产模式

```bash
# 编译
make build

# 运行
./bin/server
```

## 当前功能

服务已可以启动并响应:
- `GET /health` - 健康检查
- `GET /v1/ping` - API 测试

## 下一步

骨架已完成，按照 `DEVELOPMENT.md` 中的计划开始实现业务逻辑:

1. 实现数据库连接（infra/db）
2. 实现认证系统（usecase/auth + handler）
3. 实现玩家系统（domain/player + repository）
4. 依次实现其他模块

## 注意事项

### 开发时必须遵守

1. 所有数据库字段必须与 `schema.sql` 完全一致
2. 所有 API 接口必须与 `api-reference.md` 完全一致
3. 代码必须放在正确的目录层级
4. 金额字段必须使用 `decimal.Decimal`
5. 所有写操作必须支持幂等性（Idempotency-Key）
6. 禁止使用 emoji 和图形符号

### 开发前必读

1. `.cursorrules` - Cursor IDE 规则
2. `AGENTS.md` - AI 助手完整指南
3. `.ai/README.md` - 开发规范详解
4. 相关模块文档 - 业务逻辑理解

## 项目已就绪

基础骨架搭建完成！现在可以开始实现具体的业务功能了。

祝开发顺利！
