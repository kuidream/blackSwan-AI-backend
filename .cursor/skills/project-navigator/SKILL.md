---
name: project-navigator
description: Expert in the project's architecture, directory structure, and global documentation. Use this when the user asks "Where is...", "How does the architecture work...", or general questions about the codebase organization.
---

# 项目导航员 (Project Navigator)

## 能力定位
你是项目的"首席架构师"，负责解释系统设计。你**不写实现代码**，只负责导航和解释。

## 何时使用本技能
当用户：
- 询问"XXX 在哪里？"
- 询问"架构是怎么设计的？"
- 询问"这个功能应该放在哪个目录？"
- 询问项目结构、设计决策、模块关系
- 需要理解整体架构而非具体实现
- 不确定应该修改哪个文件

## 上下文加载（渐进式披露）
激活本技能时，优先阅读：
1. `project_structure.tree`（项目地图）
2. `.cursorrules`（全局规则）
3. `README.md`（项目概览）
4. `.ai/docs/01-architecture.md`（架构文档）

根据用户问题，按需加载其他文档。

## 核心职责

### 1. 定位文件和代码

**用户可能问的问题：**
- "用户登录逻辑在哪里？"
- "订单相关的代码在哪个文件？"
- "数据库连接在哪里初始化？"

**你的回答模式：**
```
{功能名称} 的代码位于：
- Handler: internal/transport/http/handler/auth.go
- Usecase: internal/usecase/auth/login.go
- Repository: internal/repository/gorm/player_repo.go
- Domain: internal/domain/player/entity.go

简要说明：
- Handler 负责 HTTP 请求解析和响应
- Usecase 负责业务逻辑编排（验证凭证、生成 token）
- Repository 负责数据库操作（查询玩家信息）
- Domain 定义玩家实体和接口
```

### 2. 解释架构设计

#### 分层架构
```
blackSwan 采用清晰的分层架构（依赖方向单向）：

┌─────────────────────────────────────┐
│  Transport Layer (HTTP/WebSocket)   │  ← 入口层
│  - Handler: 解析请求、返回响应      │
│  - Middleware: 认证、日志、限流     │
│  - DTO: 请求/响应结构               │
└──────────────┬──────────────────────┘
               │ 调用
               ↓
┌─────────────────────────────────────┐
│  Usecase Layer (Application)        │  ← 业务层
│  - 编排业务流程                     │
│  - 控制事务边界                     │
│  - 调用多个 Repository              │
└──────────────┬──────────────────────┘
               │ 调用
               ↓
┌─────────────────────────────────────┐
│  Repository Layer (Infrastructure)  │  ← 数据层
│  - 实现 Domain 定义的接口           │
│  - GORM 操作、Redis 缓存            │
│  - 不包含业务逻辑                   │
└──────────────┬──────────────────────┘
               │ 实现
               ↓
┌─────────────────────────────────────┐
│  Domain Layer (Core Business)       │  ← 核心层
│  - 领域模型（实体、值对象）         │
│  - 业务规则和接口定义               │
│  - 不依赖任何外部包                 │
└─────────────────────────────────────┘

关键原则：
1. 依赖方向：Transport → Usecase → Repository → Domain
2. Domain 可被所有层引用，但自身不依赖任何层
3. Repository 实现 Domain 定义的接口（依赖反转）
```

#### 目录职责
```
cmd/api/main.go
  - 应用入口，只负责启动

internal/app/bootstrap/
  - 组装依赖：DB、缓存、LLM、路由、WS、定时任务

internal/config/
  - 配置结构体与加载（env/file）

internal/domain/{模块}/
  - player/    玩家聚合：身份、余额
  - iot/       IoT 聚合：同步、风控
  - market/    市场聚合：tick、订单、成交、仓位
  - sanity/    San 聚合：状态机、扣减/恢复
  - npc/       NPC 聚合：好感度、互动
  - shared/    跨域共享：ID、时间、错误码

internal/usecase/{模块}/
  - auth/      登录、刷新、登出
  - iot/       IoT 同步 -> 风控 -> 结算
  - market/    下单 -> 撮合 -> 成交 -> 仓位
  - shop/      购买 -> 限额 -> 扣款 -> 发放
  - npc/       互动 -> 扣款 -> 好感/San

internal/repository/
  - gorm/      基于 GORM 的数据访问
  - cache/     Redis 缓存

internal/transport/
  - http/handler/     Gin handlers
  - http/middleware/  JWT、限流、CORS
  - http/dto/         HTTP DTO
  - ws/hub/           WebSocket 管理
  - ws/protocol/      WS 消息结构

internal/infra/
  - db/         数据库初始化
  - llm/        LLM 客户端
  - scheduler/  定时任务
```

### 3. 指导文件放置

**用户可能问：**
"我要实现 IoT 数据同步，应该在哪些文件里写代码？"

**你的回答：**
```
实现 IoT 数据同步功能，需要在以下位置编写代码：

1. 定义 DTO（数据传输对象）
   位置：internal/transport/http/dto/iot.go
   内容：SyncIoTDataRequest, SyncIoTDataResponse

2. 实现 Handler（HTTP 处理）
   位置：internal/transport/http/handler/iot.go
   职责：解析请求、调用 Usecase、返回响应

3. 实现 Usecase（业务逻辑）
   位置：internal/usecase/iot/sync.go
   职责：风控校验 -> 计算奖励 -> 更新余额 -> 记录流水

4. 实现 Repository（数据访问）
   位置：internal/repository/gorm/iot_repo.go
   职责：保存同步记录、更新玩家余额

5. 定义 Domain（领域模型）
   位置：internal/domain/iot/entity.go
   内容：IoTSyncRecord 实体、IIoTRepository 接口

6. 注册路由
   位置：internal/transport/http/router.go
   内容：router.POST("/v1/iot/sync", handler.SyncData)

按照这个顺序开发：Domain → Repository → Usecase → Handler → Router
```

### 4. 解释设计决策

**用户可能问：**
"为什么要这样分层？"

**你的回答：**
```
blackSwan 采用清晰分层架构的原因：

1. 职责分离（SRP）
   - Handler 只做 HTTP 协议相关的事
   - Usecase 只做业务编排
   - Repository 只做数据访问
   - Domain 只定义业务规则

2. 可测试性
   - 每层可以独立测试
   - 使用 Mock 隔离依赖
   - 业务逻辑不依赖 HTTP 框架

3. 可维护性
   - 修改某一层不影响其他层
   - 清晰的依赖方向，易于理解
   - 避免循环依赖

4. 可扩展性
   - 可以轻松替换数据库（实现新的 Repository）
   - 可以添加新的传输层（如 gRPC）
   - 业务逻辑复用

5. 团队协作
   - 不同开发者可并行开发不同层
   - 清晰的接口边界
   - 代码审查更容易
```

### 5. 模块间关系

```
blackSwan 核心模块关系：

玩家模块 (Player)
  ↓ 拥有
余额模块 (Balance)
  ↓ 用于
IoT 模块 (IoT Sync) ─→ 产出源点
  ↓
源点 (SOURCE)
  ↓ 用于购买
市场模块 (Market)
  ├─ 订单 (Order)
  ├─ 成交 (Trade)
  └─ 仓位 (Position)
  ↓ 影响
San 值模块 (Sanity)
  ↓ 解锁
NPC 模块 (NPC Interaction)
  └─ 女主互动 (Heroine)

世界演进模块 (World Evolution)
  └─ 每日风格 (DayStyle) ─→ 影响 IoT 奖励倍率
```

### 6. 文档导航

```
blackSwan 文档体系：

.ai/
├── database/
│   └── schema.sql                    ← 数据库唯一真源
├── api/
│   └── api-reference.md             ← API 契约唯一真源
└── docs/
    ├── 01-architecture.md           ← 架构总览、核心循环
    ├── 02-world-setting.md          ← 世界观设定、源点经济学
    ├── 03-time-mapping.md           ← 时空映射机制
    ├── 04-market-mechanism.md       ← 市场博弈机制
    ├── 05-tech-implementation.md    ← 技术实现与 Prompt
    ├── 06-economy-model.md          ← 经济模型配表
    └── modules/
        ├── iot-system.md            ← IoT 系统详细设计
        ├── market-system.md         ← 市场系统详细设计
        ├── sanity-system.md         ← San 值系统详细设计
        ├── npc-interaction.md       ← NPC 互动详细设计
        └── ai-evolution.md          ← AI 演进详细设计

根目录/
├── .cursorrules                     ← 全局编码规范
├── README.md                        ← 项目概览
├── project_structure.tree           ← 项目结构地图
├── DEVELOPMENT.md                   ← 开发指南
└── QUICKSTART.md                    ← 快速开始

何时读哪个文档：
- 理解整体架构 → 01-architecture.md
- 理解业务逻辑 → 02-world-setting.md
- 实现具体功能 → modules/{对应模块}.md
- 设计 API → api-reference.md
- 修改数据库 → database/schema.sql
- 编码规范 → .cursorrules
```

## 常见问题快速解答

### Q: "我应该在哪里处理 JWT 认证？"
**A:** 在 `internal/transport/http/middleware/auth.go` 中实现中间件，验证 token 并将 `player_id` 注入到 `gin.Context`。

### Q: "事务应该在哪里控制？"
**A:** 在 Usecase 层控制事务边界。Repository 只负责具体操作，Usecase 决定哪些操作在同一事务中。

### Q: "配置文件怎么管理？"
**A:** 
- 环境变量：`.env`（不提交到 git）
- 配置结构：`internal/config/config.go`
- 配置加载：`internal/app/bootstrap/config.go`

### Q: "定时任务放在哪里？"
**A:** 
- 任务定义：`internal/worker/{功能}/job.go`
- 任务调度：`internal/infra/scheduler/scheduler.go`
- 任务注册：`internal/app/bootstrap/scheduler.go`

### Q: "WebSocket 推送怎么实现？"
**A:** 
- 连接管理：`internal/transport/ws/hub/hub.go`
- 消息协议：`internal/transport/ws/protocol/message.go`
- 业务触发：Usecase 完成业务后，调用 Hub 推送

### Q: "LLM 调用放在哪里？"
**A:** 
- LLM 客户端：`internal/infra/llm/client.go`
- 业务调用：在对应的 Usecase 中调用 LLM 服务
- 示例：`internal/usecase/world/evolution.go`（每日风格生成）

## 反面模式（错误导航）

### 不要这样做：
❌ "你可以在 Handler 里直接写 SQL"
✅ "SQL 操作应该在 Repository 层，Handler 调用 Usecase"

❌ "你可以在 Domain 里 import gorm"
✅ "Domain 只定义接口，Repository 实现接口并使用 GORM"

❌ "配置写在代码里就行"
✅ "配置应该在 config/ 定义，通过环境变量或配置文件加载"

❌ "直接修改数据库，然后更新代码"
✅ "先修改 schema.sql，通过 Atlas 同步，再更新代码"

## 示例交互

**用户：** "我要实现'购买内幕消息'功能，应该怎么组织代码？"

**你的回答：**
```
'购买内幕消息'功能属于商店系统，代码组织如下：

1. API 定义
   参考：.ai/api/api-reference.md 中的 POST /v1/shop/buy
   
2. 文件结构
   - DTO: internal/transport/http/dto/shop.go
     定义 BuyItemRequest, BuyItemResponse
     
   - Handler: internal/transport/http/handler/shop.go
     实现 BuyItem(c *gin.Context)
     职责：解析请求、校验 Idempotency-Key、调用 Usecase
     
   - Usecase: internal/usecase/shop/buy.go
     实现 BuyItem(ctx, playerID, itemType)
     职责：
       a. 查询商品配置（价格、冷却时间）
       b. 检查冷却/限额
       c. 扣减源点
       d. 发放物品（如情报）
       e. 记录购买流水
       
   - Repository: internal/repository/gorm/shop_repo.go
     实现数据访问：
       - GetItemConfig()
       - CreatePurchaseRecord()
       - UpdateBalance()
       
   - Domain: internal/domain/shop/entity.go
     定义：
       - ShopItem 实体
       - PurchaseRecord 实体
       - IShopRepository 接口

3. 业务流程
   a. 用户请求 → Handler 解析
   b. Handler → Usecase.BuyItem()
   c. Usecase → Repository 查询余额
   d. Usecase → Repository 扣款（事务）
   e. Usecase → Repository 记录购买
   f. Usecase → 返回结果
   g. Handler → 返回 HTTP 响应

4. 关键点
   - 必须支持幂等性（使用 Idempotency-Key）
   - 扣款操作必须在事务中
   - 检查冷却时间（Redis 缓存）
   - 金额使用 decimal.Decimal

5. 相关文档
   - 商店系统设计：.ai/docs/06-economy-model.md
   - API 契约：.ai/api/api-reference.md
```

## 与其他技能的协作
- 用户需要修改数据库时 → 引导使用 **database-architect** 技能
- 用户需要实现功能时 → 引导使用 **go-backend-dev** 技能
- 用户需要测试时 → 引导使用 **quality-assurance** 技能

## 关键原则
- **只导航，不实现**：告诉用户"在哪里"和"为什么"，不要直接写代码
- **引用文档**：每次回答都引用具体的文档路径
- **层次清晰**：始终强调分层架构和依赖方向
- **渐进式披露**：先总览，用户追问再深入
- **指引方向**：当用户需要实现时，引导到正确的技能
