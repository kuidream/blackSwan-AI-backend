# 开发指南

## 基础骨架已完成

### 目录结构

已按照 `project_structure.tree` 创建完整的目录结构:

```
blackSwan-AI-backend/
├── cmd/api/                    # 应用入口
│   └── main.go                # 服务启动（含优雅关机）
├── internal/
│   ├── app/
│   │   ├── bootstrap/         # 依赖组装（待实现）
│   │   └── wire/              # 依赖注入（待实现）
│   ├── config/
│   │   └── config.go          # 配置管理（已完成）
│   ├── domain/                # 领域模型（待实现业务逻辑）
│   │   ├── player/
│   │   ├── iot/
│   │   ├── market/
│   │   ├── sanity/
│   │   ├── npc/
│   │   └── shared/            # 共享类型和错误
│   ├── usecase/               # 应用服务（待实现）
│   │   ├── auth/
│   │   ├── iot/
│   │   ├── market/
│   │   ├── tripx/
│   │   ├── shop/
│   │   └── npc/
│   ├── repository/            # 数据访问（待实现）
│   │   ├── gorm/
│   │   └── cache/
│   ├── transport/
│   │   ├── http/
│   │   │   ├── router.go      # Gin 路由（已完成基础）
│   │   │   ├── handler/       # HTTP 处理器（待实现）
│   │   │   ├── middleware/    # 中间件（待实现）
│   │   │   └── dto/           # DTO 定义
│   │   └── ws/                # WebSocket（待实现）
│   ├── infra/                 # 基础设施（待实现）
│   │   ├── db/
│   │   ├── llm/
│   │   ├── scheduler/
│   │   └── observability/
│   └── worker/                # 定时任务（待实现）
├── migrations/                # 数据库迁移
├── api/                       # OpenAPI 文档
├── scripts/                   # 开发脚本
└── .ai/                       # AI 工具文档
```

### 已创建的核心文件

1. **go.mod**: Go 模块定义，包含核心依赖
2. **cmd/api/main.go**: 服务入口，实现了优雅关机
3. **internal/config/config.go**: 配置管理，从环境变量读取
4. **internal/transport/http/router.go**: Gin 路由初始化
5. **internal/domain/shared/**: 共享类型和错误定义
6. **internal/transport/http/dto/response.go**: 统一响应格式
7. **.env.example**: 环境变量模板
8. **.gitignore**: Git 忽略规则
9. **scripts/**: 启动脚本

### 当前状态

服务可以启动并响应基础请求:
- `GET /health` - 健康检查
- `GET /v1/ping` - 测试接口

## 下一步开发计划

### 阶段 1: 基础设施层 (Infra)

1. **数据库初始化** (`internal/infra/db/`)
   - 实现 PostgreSQL 连接池
   - 实现 GORM 初始化
   - 实现事务管理器

2. **缓存层** (`internal/infra/cache/`)
   - 实现 Redis 客户端封装
   - 实现缓存接口

3. **日志系统** (`internal/infra/observability/`)
   - 集成 zap 或其他日志库
   - 实现结构化日志

### 阶段 2: 领域层 (Domain)

按业务模块实现领域模型和仓储接口:

1. **Player Domain** (`internal/domain/player/`)
   - 定义 Player 实体
   - 定义 Balance 值对象
   - 定义 Repository 接口

2. **IoT Domain** (`internal/domain/iot/`)
   - 定义 SyncBatch 实体
   - 定义防作弊规则
   - 定义 Repository 接口

3. **Market Domain** (`internal/domain/market/`)
   - 定义 Order, Trade, Position 实体
   - 定义价格演算规则
   - 定义 Repository 接口

4. **Sanity Domain** (`internal/domain/sanity/`)
   - 定义 Sanity 值对象
   - 定义状态机逻辑
   - 定义 Repository 接口

5. **NPC Domain** (`internal/domain/npc/`)
   - 定义 Heroine 实体
   - 定义好感度规则
   - 定义 Repository 接口

### 阶段 3: 数据访问层 (Repository)

实现领域接口的具体实现:

1. **GORM Repository** (`internal/repository/gorm/`)
   - 实现 PlayerRepository
   - 实现 IoTRepository
   - 实现 MarketRepository
   - 实现 SanityRepository
   - 实现 NPCRepository

2. **Cache Repository** (`internal/repository/cache/`)
   - 实现风格配置缓存
   - 实现行情数据缓存
   - 实现玩家状态缓存

### 阶段 4: 应用服务层 (Usecase)

实现业务编排逻辑:

1. **Auth Usecase** (`internal/usecase/auth/`)
   - Login/Refresh/Logout

2. **IoT Usecase** (`internal/usecase/iot/`)
   - Sync: 同步 → 风控 → 结算 → 入账

3. **Market Usecase** (`internal/usecase/market/`)
   - PlaceOrder: 下单 → 校验 → 撮合 → 更新

4. **TripX Usecase** (`internal/usecase/tripx/`)
   - StartDay/EndDay
   - ConsumeTimeSlot

5. **Shop Usecase** (`internal/usecase/shop/`)
   - Purchase: 购买 → 扣款 → 发放

6. **NPC Usecase** (`internal/usecase/npc/`)
   - Interact: 互动 → 扣款 → 好感度 → 剧情

### 阶段 5: 传输层 (Transport)

实现 HTTP 和 WebSocket 接口:

1. **HTTP Handler** (`internal/transport/http/handler/`)
   - AuthHandler
   - IoTHandler
   - MarketHandler
   - ShopHandler
   - NPCHandler

2. **Middleware** (`internal/transport/http/middleware/`)
   - RequestID
   - Logger
   - Recovery
   - CORS
   - JWT Auth
   - Rate Limit

3. **WebSocket** (`internal/transport/ws/`)
   - Hub: 连接管理
   - Protocol: 消息协议
   - Ticker: 行情推送

### 阶段 6: Worker 和定时任务

1. **Evolution Worker** (`internal/worker/evolution/`)
   - 每日 00:00 风格生成

2. **Retention Worker** (`internal/worker/retention/`)
   - Tick 数据清理

3. **Scheduler** (`internal/infra/scheduler/`)
   - Cron 任务管理

### 阶段 7: 依赖注入和启动

1. **Bootstrap** (`internal/app/bootstrap/`)
   - 组装所有依赖
   - 初始化数据库
   - 初始化缓存
   - 初始化 LLM 客户端
   - 启动 HTTP 服务
   - 启动 WebSocket 服务
   - 启动定时任务

## 开发原则

### 依赖方向

```
transport → usecase → domain ← repository/infra
```

**严禁**:
- domain 依赖其他层
- repository 依赖 usecase
- usecase 依赖 transport

### 接口设计

- domain 定义接口（Repository Ports）
- repository 实现接口（Adapters）
- usecase 通过接口调用 repository（依赖反转）

### 事务管理

- 事务边界在 usecase 层
- 使用 GORM Transaction 或 UnitOfWork 模式
- repository 方法接受 *gorm.DB 参数

### 错误处理

- domain 返回领域错误
- usecase 包装错误并添加上下文
- handler 转换为 HTTP 错误码

## 开发工作流

### 实现新功能

1. 阅读相关文档（`.ai/docs/modules/`）
2. 在 domain 层定义实体和接口
3. 在 repository 层实现接口
4. 在 usecase 层编排业务逻辑
5. 在 handler 层实现 HTTP 接口
6. 编写测试
7. 更新文档

### 数据库变更

1. 修改 `.ai/database/schema.sql`
2. 使用 Atlas 工具同步到数据库
3. 更新 GORM 模型

### API 变更

1. 修改 `.ai/api/api-reference.md`
2. 更新对应的 Handler 和 DTO
3. 更新集成测试

## 参考资源

- 完整开发规范: `.ai/README.md`
- Cursor 规则: `.cursorrules`
- AI 助手指南: `AGENTS.md`
- 环境配置: `scripts/setup.md`
