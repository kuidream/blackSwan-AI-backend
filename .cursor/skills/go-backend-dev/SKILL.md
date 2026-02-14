---
name: go-backend-dev
description: Expert in Go, Gin, and GORM. Use this skill when implementing business logic, creating API endpoints, or writing service layer code.
---

# Go 后端开发专家 (Go Backend Developer)

## 能力定位
你是 Go、Gin 和 GORM 专家，负责实现 blackSwan 的高性能游戏后端业务逻辑。

## 何时使用本技能
当用户：
- 要求实现业务逻辑或创建 API 端点
- 讨论 Handler、Usecase、Repository 层代码
- 需要编写服务层代码或数据访问层
- 提到 Gin 路由、中间件、请求处理
- 要求实现游戏功能（IoT 同步、交易、NPC 互动等）

## 上下文加载（渐进式披露）
激活本技能时，严格按需加载：
1. **必读**：`@.ai/api/api-reference.md`（API 契约）
2. **必读**：`project_structure.tree`（项目布局）
3. **按需**：`.ai/docs/01-architecture.md`（架构理解）
4. **按需**：对应模块的文档（如 `.ai/docs/modules/iot-system.md`）

不要一次性加载所有文档，根据任务逐步加载。

## 核心规则（不可妥协）

### 1. 分层架构铁律

**依赖方向（单向）：**
```
transport (handler) → usecase → repository → domain
                   ↘         ↘            ↗
                        domain (可被所有层直接引用)
```

**目录结构：**
```
cmd/                    # 应用入口，只负责启动
internal/
  ├── transport/
  │   └── http/
  │       ├── handler/  # Gin handlers（仅做鉴权/参数校验/DTO 映射）
  │       ├── middleware/
  │       └── dto/      # HTTP 请求/响应 DTO
  ├── usecase/          # 业务逻辑（编排，不落地细节）
  ├── repository/       # 数据访问（实现 domain 定义的接口）
  ├── domain/           # 领域模型（不依赖任何外部包）
  └── config/           # 配置
```

**职责划分：**

| 层级 | 职责 | 禁止操作 |
|-----|------|---------|
| **Handler** | 解析请求、验证参数、调用 Usecase、返回响应 | 不能直接操作数据库、不能包含业务逻辑 |
| **Usecase** | 编排业务流程、控制事务边界、调用 Repository | 不能引用 Gin Context、不能直接操作 DB |
| **Repository** | 数据访问、GORM 操作 | 不能包含业务逻辑、不能互相调用 |
| **Domain** | 领域模型、业务规则、接口定义 | 不能依赖外部包（除标准库）|

### 2. API 契约铁律

**强制要求：**
- 生成的 Handler 代码必须严格遵守 `api-reference.md` 中的 Request/Response 结构
- 统一响应格式必须包含 `request_id`, `server_time`, `data/error`
- 所有写操作必须支持 `Idempotency-Key`
- 时间使用 Unix 秒或 RFC3339 (UTC)
- 金额/数量使用字符串（避免 float）
- Base URL 必须以 `/v1` 开头

**正确示例：**
```go
// 请求结构（严格遵守 API 文档）
type PlaceOrderRequest struct {
    Symbol         string `json:"symbol" binding:"required"`
    Side           string `json:"side" binding:"required,oneof=BUY SELL"`
    Type           string `json:"type" binding:"required,oneof=MARKET LIMIT"`
    Qty            string `json:"qty" binding:"required"`
    ClientOrderID  string `json:"client_order_id"`
}

// 统一成功响应
type SuccessResponse struct {
    RequestID  string      `json:"request_id"`
    ServerTime int64       `json:"server_time"`
    Data       interface{} `json:"data"`
}

// 统一错误响应
type ErrorResponse struct {
    RequestID  string       `json:"request_id"`
    ServerTime int64        `json:"server_time"`
    Error      ErrorDetail  `json:"error"`
}

type ErrorDetail struct {
    Code    string      `json:"code"`
    Message string      `json:"message"`
    Details interface{} `json:"details,omitempty"`
}
```

**错误示例：**
```go
// 错误：不要自创响应格式
type Response struct {
    Code    int         `json:"code"`     // 错误：API 文档中没有 code 字段
    Message string      `json:"message"`  // 错误：应该在 error 对象中
    Data    interface{} `json:"data"`
}
```

### 3. 编码规范

#### 命名规范
```go
// 包命名：小写单词
package marketengine

// 接口命名：I + 名词
type IMarketService interface {}

// 结构体：大驼峰
type MarketTick struct {}

// 函数：大驼峰（公开）/ 小驼峰（私有）
func CalculatePrice() {}
func calculateDelta() {}

// 变量：小驼峰
var playerBalance int64

// 常量：大驼峰或全大写
const MaxDailySteps = 20000
```

#### 注释规范
```go
// 正确：简洁实用
// CalculateSourceReward 计算源点奖励
// 基于 IoT 数据和当日风格配置计算玩家可获得的源点数量
func CalculateSourceReward(steps int, styleConfig *StyleConfig) (int64, error) {
    // 实现逻辑
}

// 错误：使用 emoji 或过度装饰（禁止）
// 🚀 CalculateSourceReward 计算源点奖励
// ================================
// ★★★ 重要函数 ★★★
// ================================
```

#### 错误处理
```go
// 正确：标准错误处理
if err != nil {
    return nil, fmt.Errorf("failed to calculate reward: %w", err)
}

// 定义业务错误
var (
    ErrInsufficientBalance = errors.New("insufficient balance")
    ErrInvalidPrice = errors.New("invalid price")
)
```

### 4. 数据库操作规范

#### 使用 GORM 事务
```go
// 正确：使用事务和错误处理
func (r *OrderRepository) CreateOrder(order *Order) error {
    return r.db.Transaction(func(tx *gorm.DB) error {
        // 1. 创建订单
        if err := tx.Create(order).Error; err != nil {
            return fmt.Errorf("failed to create order: %w", err)
        }
        
        // 2. 更新余额
        if err := tx.Model(&PlayerBalance{}).
            Where("player_id = ? AND asset = ?", order.PlayerID, "SOURCE").
            Update("available_amount", gorm.Expr("available_amount - ?", order.TotalCost)).
            Error; err != nil {
            return fmt.Errorf("failed to update balance: %w", err)
        }
        
        return nil
    })
}

// 错误：不使用事务，可能导致数据不一致
func (r *OrderRepository) CreateOrder(order *Order) error {
    r.db.Create(order)  // ❌ 没有错误处理
    r.db.Model(&PlayerBalance{}).Update(...)  // ❌ 不在同一事务中
    return nil
}
```

#### 金额字段处理
```go
// 正确：使用 decimal 包
import "github.com/shopspring/decimal"

type Order struct {
    RequestedQty decimal.Decimal `gorm:"type:numeric(30,10)"`
    AvgPrice     decimal.Decimal `gorm:"type:numeric(30,10)"`
}

// 计算
totalCost := order.RequestedQty.Mul(order.AvgPrice)

// 错误：使用 float（禁止）
type Order struct {
    RequestedQty float64  // ❌ 精度问题
    AvgPrice     float64  // ❌ 精度问题
}
```

#### 查询优化
```go
// 正确：使用索引字段查询
db.Where("player_id = ? AND created_at > ?", playerID, startTime).Find(&orders)

// 正确：预加载关联数据
db.Preload("Player").Preload("Position").Find(&orders)

// 错误：N+1 查询问题
for _, order := range orders {
    db.First(&player, order.PlayerID)  // ❌ 循环查询
}
```

### 5. API 开发规范

#### 幂等性支持
```go
// 正确：支持幂等性
func (h *OrderHandler) PlaceOrder(c *gin.Context) {
    idempotencyKey := c.GetHeader("Idempotency-Key")
    if idempotencyKey == "" {
        c.JSON(400, ErrorResponse{
            Error: ErrorDetail{
                Code: "MISSING_IDEMPOTENCY_KEY",
                Message: "Idempotency-Key is required",
            },
        })
        return
    }
    
    // 检查是否已存在
    existing, _ := h.orderService.GetByIdempotency(playerID, idempotencyKey)
    if existing != nil {
        c.JSON(200, SuccessResponse{Data: existing})
        return
    }
    
    // 创建新订单
    order, err := h.orderService.PlaceOrder(req)
    // ...
}
```

#### Handler 层标准模板
```go
func (h *OrderHandler) PlaceOrder(c *gin.Context) {
    // 1. 解析请求
    var req PlaceOrderRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, ErrorResponse{
            RequestID:  c.GetString("request_id"),
            ServerTime: time.Now().Unix(),
            Error: ErrorDetail{
                Code:    "INVALID_REQUEST",
                Message: err.Error(),
            },
        })
        return
    }
    
    // 2. 获取玩家 ID（从 JWT）
    playerID := c.GetString("player_id")
    
    // 3. 调用 Usecase
    order, err := h.orderUsecase.PlaceOrder(c.Request.Context(), playerID, &req)
    if err != nil {
        // 错误处理
        c.JSON(500, ErrorResponse{
            RequestID:  c.GetString("request_id"),
            ServerTime: time.Now().Unix(),
            Error: ErrorDetail{
                Code:    "PLACE_ORDER_FAILED",
                Message: err.Error(),
            },
        })
        return
    }
    
    // 4. 返回成功响应
    c.JSON(200, SuccessResponse{
        RequestID:  c.GetString("request_id"),
        ServerTime: time.Now().Unix(),
        Data:       order,
    })
}
```

#### Usecase 层标准模板
```go
func (u *OrderUsecase) PlaceOrder(ctx context.Context, playerID string, req *PlaceOrderRequest) (*Order, error) {
    // 1. 参数验证
    if err := u.validateOrder(req); err != nil {
        return nil, fmt.Errorf("validate order: %w", err)
    }
    
    // 2. 业务规则检查
    balance, err := u.balanceRepo.GetBalance(ctx, playerID, "SOURCE")
    if err != nil {
        return nil, fmt.Errorf("get balance: %w", err)
    }
    
    // 3. 执行业务逻辑（在事务中）
    order, err := u.orderRepo.CreateOrderWithTransaction(ctx, func(tx *gorm.DB) error {
        // 创建订单
        // 扣减余额
        // 更新仓位
        return nil
    })
    
    if err != nil {
        return nil, fmt.Errorf("create order: %w", err)
    }
    
    return order, nil
}
```

### 6. 性能优化

#### Redis 缓存
```go
// 正确：使用缓存
func (s *WorldService) GetTodayStyle() (*StyleConfig, error) {
    date := time.Now().Format("2006-01-02")
    key := fmt.Sprintf("world:style:%s", date)
    
    // 尝试从缓存读取
    cached, err := s.cache.Get(ctx, key).Result()
    if err == nil {
        return ParseStyleConfig(cached), nil
    }
    
    // 缓存未命中，从数据库读取
    config, err := s.repo.GetStyleByDate(date)
    if err != nil {
        return nil, err
    }
    
    // 写入缓存
    s.cache.Set(ctx, key, config.ToJSON(), 24*time.Hour)
    return config, nil
}
```

#### 日志规范
```go
// 正确：结构化日志，无 emoji
log.Info("order placed successfully",
    "order_id", orderId,
    "player_id", playerId,
    "symbol", "AERA",
)

// 错误：使用 emoji（禁止）
log.Info("✅ 订单成功")  // ❌ 禁止
```

## 反面模式（禁止操作）

### 永远不要做的事：
1. 在 Handler 中直接操作数据库
2. 在 Usecase 中引用 `gin.Context`
3. 在 Domain 中依赖外部包
4. Repository 层互相调用
5. 使用 float 处理金额
6. 不支持幂等性的写操作
7. 自创 API 响应格式
8. 在日志/注释中使用 emoji
9. 不使用事务的多表操作
10. 循环中执行数据库查询（N+1 问题）

### 循环依赖检查
```go
// ❌ 错误：Usecase 引用 Handler
import "internal/transport/http/handler"  // 禁止

// ❌ 错误：Repository 引用 Usecase
import "internal/usecase"  // 禁止

// ❌ 错误：Domain 引用 Repository
import "internal/repository"  // 禁止

// ✅ 正确：单向依赖
// Handler → Usecase → Repository → Domain
```

## 开发工作流

### 实现新功能的标准流程

**步骤 1：阅读 API 文档**
```
读取 @.ai/api/api-reference.md 找到对应接口定义
```

**步骤 2：理解业务逻辑**
```
读取对应的模块文档（如 @.ai/docs/modules/iot-system.md）
```

**步骤 3：创建 Domain 模型**（如需要）
```
在 internal/domain/{模块}/ 创建实体和接口
```

**步骤 4：实现 Repository**
```
在 internal/repository/gorm/ 实现数据访问
```

**步骤 5：实现 Usecase**
```
在 internal/usecase/{模块}/ 实现业务逻辑
```

**步骤 6：实现 Handler**
```
在 internal/transport/http/handler/ 实现 API 端点
```

**步骤 7：添加路由**
```
在 internal/transport/http/router.go 注册路由
```

## 示例交互

**用户：** "实现 IoT 数据同步接口"

**你的操作：**
1. 读取 `@.ai/api/api-reference.md` 找到 `POST /v1/iot/sync` 定义
2. 读取 `@.ai/docs/modules/iot-system.md` 理解业务逻辑
3. 创建 DTO：
   ```go
   // internal/transport/http/dto/iot.go
   type SyncIoTDataRequest struct {
       Date     string `json:"date" binding:"required"`
       Steps    int    `json:"steps" binding:"required,min=0"`
       HeartRate int   `json:"heart_rate"`
   }
   ```
4. 实现 Usecase：
   ```go
   // internal/usecase/iot/sync.go
   func (u *IoTUsecase) SyncData(ctx context.Context, playerID string, data *SyncIoTDataRequest) (*SyncResult, error) {
       // 业务逻辑
   }
   ```
5. 实现 Handler：
   ```go
   // internal/transport/http/handler/iot.go
   func (h *IoTHandler) SyncData(c *gin.Context) {
       // HTTP 处理
   }
   ```

## 与其他技能的协作
- 需要修改数据库时，使用 **database-architect** 技能
- 完成后，使用 **quality-assurance** 技能编写测试
- 不确定架构时，使用 **project-navigator** 技能

## 关键参考文档
- API 契约：`.ai/api/api-reference.md`
- 项目结构：`project_structure.tree`
- 核心架构：`.ai/docs/01-architecture.md`
- 模块文档：`.ai/docs/modules/*.md`
- 编码规范：`.cursorrules`
