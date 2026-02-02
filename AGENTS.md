# AGENTS.md - AI 开发助手指南

## 项目身份

你正在协助开发 **blackSwan AI Backend**，这是一个基于现实映射的自动演进式 RPG 游戏后端系统。

技术栈: Golang + Gin + PostgreSQL + Redis + WebSocket

## 核心铁律 (必须严格遵守)

### 🔴 铁律 1: 数据库真理 (Database SSOT)

**事实来源**: `.ai/database/schema.sql`

**绝对规则**:
- schema.sql 是数据库结构的唯一真理，任何与之冲突的信息都是错误的
- 生成 GORM 模型或 SQL 时，字段名、类型、约束必须 100% 匹配 schema.sql
- 严禁臆造任何字段、表名或修改数据类型
- 如果用户要求添加新字段，必须先提醒用户更新 schema.sql

**Schema 同步机制**:
- schema.sql 中的结构已通过 Atlas 工具同步至数据库
- 不要生成 "CREATE TABLE IF NOT EXISTS" 检查代码
- 不要询问"表是否已创建"，直接使用即可

**字段匹配检查清单**:
```
✓ 表名必须匹配（使用单数形式）
✓ 字段名必须完全一致（下划线命名）
✓ 数据类型必须匹配（UUID, TEXT, NUMERIC, TIMESTAMPTZ 等）
✓ 约束必须匹配（NOT NULL, UNIQUE, REFERENCES）
✓ 默认值必须匹配（gen_random_uuid(), now()）
```

**常见错误示例**:
```go
// ❌ 错误：字段名不匹配
type Player struct {
    Name string  // schema.sql 中是 nickname
}

// ❌ 错误：类型不匹配
type Order struct {
    AvgPrice float64  // schema.sql 中是 NUMERIC(30,10)
}

// ❌ 错误：臆造字段
type Player struct {
    Email string  // schema.sql 中没有此字段
}

// ✅ 正确：严格匹配
type Player struct {
    ID        uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
    Nickname  string    `gorm:"type:text;not null"`
    CreatedAt time.Time `gorm:"type:timestamptz;not null;default:now()"`
    UpdatedAt time.Time `gorm:"type:timestamptz;not null;default:now()"`
}
```

### 🔴 铁律 2: 接口契约 (API Contract)

**契约文档**: `.ai/api/api-reference.md`

**绝对规则**:
- api-reference.md 是对外承诺的 API 契约，不得随意更改
- Request/Response 结构必须 100% 匹配文档定义
- 统一响应格式是强制的，不得自创格式
- 所有写操作必须支持 Idempotency-Key

**响应格式规范**:
```go
// ✅ 正确：严格遵守统一格式
type SuccessResponse struct {
    RequestID  string      `json:"request_id"`
    ServerTime int64       `json:"server_time"`
    Data       interface{} `json:"data"`
}

type ErrorResponse struct {
    RequestID  string      `json:"request_id"`
    ServerTime int64       `json:"server_time"`
    Error      ErrorDetail `json:"error"`
}

type ErrorDetail struct {
    Code    string      `json:"code"`
    Message string      `json:"message"`
    Details interface{} `json:"details,omitempty"`
}

// ❌ 错误：自创响应格式
type Response struct {
    Code    int    `json:"code"`     // 不符合规范
    Message string `json:"message"`  // 不符合规范
}
```

**API 生成检查清单**:
```
✓ Base URL 以 /v1 开头
✓ 需要认证的接口包含 Authorization header
✓ 写操作支持 Idempotency-Key
✓ 响应格式包含 request_id, server_time, data/error
✓ 时间使用 Unix 秒或 RFC3339
✓ 金额/数量使用字符串（避免精度问题）
```

### 🔴 铁律 3: 工程结构 (Architecture)

**结构文档**: `project_structure.tree`

**绝对规则**:
- 代码必须放在正确的目录层级
- 严格遵守分层架构：Handler → Usecase → Repository → Domain
- 严禁循环引用

**分层依赖规则**:
```
✅ 正确的依赖方向:
handler    →  usecase  →  repository  →  domain
handler    →  domain
usecase    →  domain

❌ 禁止的依赖方向:
usecase    →  handler      (循环依赖)
repository →  usecase      (反向依赖)
domain     →  repository   (领域模型不应依赖基础设施)
domain     →  usecase      (领域模型不应依赖业务逻辑)
```

**目录职责**:
- `cmd/`: 应用入口，main.go
- `internal/handler/`: HTTP/WebSocket 处理器，依赖 usecase
- `internal/usecase/`: 业务逻辑，依赖 repository 和 domain
- `internal/repository/`: 数据访问，依赖 domain
- `internal/domain/`: 领域模型，不依赖其他层
- `internal/config/`: 配置管理
- `pkg/`: 可复用的公共库

## 编码规范

### 禁止使用的符号

**绝对禁止** (会被立即拒绝):
- Emoji: 🚀✅❌💡⚡⭐🌟🎨🔥🎉
- 图形符号: → ← ↑ ↓ ★ ☆ ◆ ◇ ● ○
- 装饰符号: === --- *** ~~~

**正确做法**:
```go
// ✅ 正确
log.Info("order placed successfully")
// Comment: 处理用户输入

// ❌ 错误
log.Info("✅ 订单成功")
// ====== 重要函数 ======
```

### 金额处理规范

**强制使用 decimal**:
```go
// ✅ 正确：使用 decimal 包
import "github.com/shopspring/decimal"

type Order struct {
    RequestedQty decimal.Decimal `gorm:"type:numeric(30,10)"`
    AvgPrice     decimal.Decimal `gorm:"type:numeric(30,10)"`
}

// 计算
totalCost := order.RequestedQty.Mul(order.AvgPrice)

// ❌ 错误：使用 float（会导致精度问题）
type Order struct {
    RequestedQty float64
    AvgPrice     float64
}
```

### 幂等性处理

**所有写操作必须支持幂等性**:
```go
// ✅ 正确实现
func (s *OrderService) PlaceOrder(req *PlaceOrderRequest) (*Order, error) {
    // 1. 幂等性检查
    existing, err := s.repo.GetByIdempotency(req.PlayerID, req.IdempotencyKey)
    if err == nil && existing != nil {
        return existing, nil  // 返回已存在的订单
    }
    
    // 2. 创建新订单
    order := &Order{
        ID:             uuid.New(),
        PlayerID:       req.PlayerID,
        IdempotencyKey: req.IdempotencyKey,
        // ...
    }
    
    return s.repo.Create(order)
}
```

### 事务处理

**涉及多表操作必须使用事务**:
```go
// ✅ 正确：使用事务
func (r *OrderRepository) CreateOrderWithBalance(order *Order) error {
    return r.db.Transaction(func(tx *gorm.DB) error {
        // 1. 创建订单
        if err := tx.Create(order).Error; err != nil {
            return err
        }
        
        // 2. 扣除余额
        if err := tx.Model(&PlayerBalance{}).
            Where("player_id = ?", order.PlayerID).
            Update("available_amount", gorm.Expr("available_amount - ?", order.TotalCost)).
            Error; err != nil {
            return err
        }
        
        // 3. 记录流水
        if err := tx.Create(&LedgerEntry{
            PlayerID: order.PlayerID,
            DeltaAmount: order.TotalCost.Neg(),
            ReasonCode: "ORDER_TRADE",
        }).Error; err != nil {
            return err
        }
        
        return nil
    })
}
```

## 业务逻辑理解

### 核心概念

**双轨资金系统**:
- 源点 (Source): 现金本金，来自现实世界 IoT 行为
- AERA: 股票资产，可交易，随市场波动

**时间系统**:
- 现实轴: 物理世界时间，控制每日风格
- 游戏轴: TripX 虚拟时间，控制剧情推进
- 时间槽: 每日 3 个，用于行动选择

**San 值系统**:
- 心理保证金，限制玩家杠杆率
- 浮亏越大，San 值下降越快（指数级）
- San 值归零触发强制平仓

### 关键业务流程

**IoT 数据同步流程**:
```
1. 客户端从 HealthKit/GoogleFit 读取增量数据
2. 发送到服务端（带签名和 Idempotency-Key）
3. 服务端验证：防作弊检查
4. 计算奖励：基础奖励 + 风格加成
5. 更新余额：增加源点
6. 记录流水：ledger_entry 表
7. 返回结果
```

**交易下单流程**:
```
1. 接收订单请求（带 Idempotency-Key）
2. 幂等性检查
3. San 值检查（< 10 拒绝）
4. 余额/持仓检查
5. 计算滑点
6. 开启事务：
   - 创建订单
   - 更新持仓
   - 更新余额
   - 记录成交
   - 记录流水
7. 提交事务
8. 返回结果
```

## 代码生成指南

### 生成 GORM 模型时

1. **必须先阅读** `.ai/database/schema.sql` 找到对应表定义
2. 严格匹配表名、字段名、数据类型
3. 添加正确的 GORM tag
4. 使用 uuid.UUID 而不是 string
5. 使用 time.Time 而不是 int64
6. 使用 decimal.Decimal 处理金额

### 生成 Handler 时

1. **必须先阅读** `.ai/api/api-reference.md` 找到接口定义
2. 严格匹配 Request/Response 结构
3. 添加参数验证（binding tag）
4. 实现幂等性检查
5. 使用统一响应格式
6. 添加错误处理

### 生成 Service 时

1. **必须先阅读** 相关模块文档（`.ai/docs/modules/`）
2. 理解业务逻辑
3. 实现事务控制
4. 添加缓存逻辑（如果适用）
5. 返回明确的业务错误

## 常见问题处理

### Q: 用户要求添加新字段到数据库

**正确回答**:
```
我注意到 schema.sql 中没有这个字段。为了保持数据库结构的一致性，
请先在 schema.sql 中添加该字段定义，然后通过 Atlas 工具同步到数据库。
同步完成后，我再帮你生成相应的 GORM 模型代码。
```

### Q: 用户要求修改 API 响应格式

**正确回答**:
```
当前的响应格式是在 api-reference.md 中定义的统一格式。
如果需要修改，建议：
1. 先在 api-reference.md 中更新文档
2. 确保修改不会破坏现有客户端
3. 考虑版本兼容性（如创建 /v2 接口）
```

### Q: 代码应该放在哪个目录

**正确回答**:
```
根据分层架构：
- HTTP 处理器 → internal/handler/
- 业务逻辑 → internal/usecase/
- 数据访问 → internal/repository/
- 领域模型 → internal/domain/
- 公共工具 → pkg/
```

## 开发流程建议

### 接到新需求时

1. **理解需求**: 询问清楚业务场景
2. **查阅文档**: 阅读相关模块文档（`.ai/docs/modules/`）
3. **检查 Schema**: 确认涉及的表和字段
4. **检查 API**: 确认是否已有相关接口
5. **设计方案**: 确定修改哪些层
6. **编写代码**: 遵守所有铁律
7. **测试验证**: 确保逻辑正确

### 遇到不确定的情况

**不要猜测，要询问或查阅文档**:
- 字段类型不确定 → 查阅 schema.sql
- 接口格式不确定 → 查阅 api-reference.md
- 业务逻辑不确定 → 查阅模块文档或询问用户
- 目录结构不确定 → 查阅 project_structure.tree

## 参考文档快速索引

**核心文档**:
- 开发规范: `.ai/README.md`
- 架构总览: `.ai/docs/01-architecture.md`
- 世界观设定: `.ai/docs/02-world-setting.md`
- 技术实现: `.ai/docs/05-tech-implementation.md`

**模块文档**:
- IoT 系统: `.ai/docs/modules/iot-system.md`
- 市场系统: `.ai/docs/modules/market-system.md`
- San 值系统: `.ai/docs/modules/sanity-system.md`
- AI 演进: `.ai/docs/modules/ai-evolution.md`
- NPC 互动: `.ai/docs/modules/npc-interaction.md`

**技术规范**:
- 数据库 Schema: `.ai/database/schema.sql`
- API 参考: `.ai/api/api-reference.md`
- 项目结构: `project_structure.tree`

## 记住

1. 三大铁律不可违背：Schema 真理、API 契约、工程结构
2. 禁止使用 emoji 和图形符号
3. 金额必须使用 decimal
4. 写操作必须支持幂等性
5. 多表操作必须使用事务
6. 不确定时查阅文档或询问
7. Schema 同步由 Atlas 工具完成，代码中不需要检查表是否存在

遵守这些规则，你将成为这个项目最可靠的开发助手。
