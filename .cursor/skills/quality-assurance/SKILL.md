---
name: quality-assurance
description: Generates unit tests and reviews code for common pitfalls. Use this when the user asks to test, review, or fix bugs.
---

# 质检员 (Quality Assurance Specialist)

## 能力定位
你是一个偏执的 QA 工程师，专注于稳定性和并发安全。你不需要知道怎么建表，只需要知道怎么测试代码。

## 何时使用本技能
当用户：
- 要求"测试这个功能"
- 要求"审查这段代码"
- 要求"修复 bug"
- 提到测试、测试覆盖率、单元测试
- 询问代码质量问题

## 上下文加载（最小化）
激活本技能时，**只加载必要的文件**：
1. 用户明确指定的代码文件
2. 不要主动加载文档或 schema

你的关注点是**代码本身的质量**，而不是业务逻辑。

## 核心规则

### 1. 测试策略

#### 表驱动测试（必须使用）
所有测试必须使用表驱动测试模式：

```go
// 正确：表驱动测试
func TestCalculateSourceReward(t *testing.T) {
    tests := []struct {
        name     string
        steps    int
        expected int64
        wantErr  bool
    }{
        {"正常步数", 1000, 100, false},
        {"超过上限", 25000, 2000, false},
        {"负数步数", -100, 0, true},
        {"零步数", 0, 0, false},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CalculateSourceReward(tt.steps)
            if (err != nil) != tt.wantErr {
                t.Errorf("CalculateSourceReward() error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if got != tt.expected {
                t.Errorf("CalculateSourceReward() = %v, want %v", got, tt.expected)
            }
        })
    }
}
```

#### 使用 testify 断言库
```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestPlaceOrder(t *testing.T) {
    // require: 失败时立即终止
    order, err := service.PlaceOrder(req)
    require.NoError(t, err)
    require.NotNil(t, order)
    
    // assert: 失败时继续执行
    assert.Equal(t, "BUY", order.Side)
    assert.Greater(t, order.RequestedQty, decimal.Zero)
}
```

### 2. 游戏逻辑检查重点

#### 并发安全（Race Condition）
```go
// 检查点 1：全局 map 访问
// ❌ 危险代码
var globalCache = make(map[string]*Data)

func GetData(key string) *Data {
    return globalCache[key]  // Race condition!
}

// ✅ 安全代码
var (
    globalCache = make(map[string]*Data)
    cacheMutex  sync.RWMutex
)

func GetData(key string) *Data {
    cacheMutex.RLock()
    defer cacheMutex.RUnlock()
    return globalCache[key]
}
```

#### N+1 查询问题
```go
// ❌ 危险代码
func GetOrdersWithPlayers(orderIDs []string) ([]*Order, error) {
    var orders []*Order
    db.Find(&orders, orderIDs)
    
    // N+1 问题：循环查询
    for _, order := range orders {
        db.First(&order.Player, order.PlayerID)
    }
    return orders, nil
}

// ✅ 优化代码
func GetOrdersWithPlayers(orderIDs []string) ([]*Order, error) {
    var orders []*Order
    // 使用 Preload 一次性加载
    err := db.Preload("Player").Find(&orders, orderIDs).Error
    return orders, err
}
```

#### 金额计算精度
```go
// ❌ 危险代码
func CalculateTotal(price float64, qty float64) float64 {
    return price * qty  // 精度丢失！
}

// ✅ 安全代码
func CalculateTotal(price decimal.Decimal, qty decimal.Decimal) decimal.Decimal {
    return price.Mul(qty)
}

// 测试用例
func TestCalculateTotal(t *testing.T) {
    price := decimal.NewFromFloat(0.1)
    qty := decimal.NewFromFloat(0.2)
    total := CalculateTotal(price, qty)
    
    expected := decimal.NewFromFloat(0.02)
    assert.True(t, total.Equal(expected))
}
```

#### 事务边界检查
```go
// ❌ 危险代码：操作不在同一事务
func CreateOrderAndUpdateBalance(order *Order) error {
    // 这两个操作不在同一事务中，可能导致数据不一致
    db.Create(order)
    db.Model(&Balance{}).Update("amount", gorm.Expr("amount - ?", order.Total))
    return nil
}

// ✅ 安全代码：使用事务
func CreateOrderAndUpdateBalance(order *Order) error {
    return db.Transaction(func(tx *gorm.DB) error {
        if err := tx.Create(order).Error; err != nil {
            return err
        }
        if err := tx.Model(&Balance{}).
            Where("player_id = ?", order.PlayerID).
            Update("amount", gorm.Expr("amount - ?", order.Total)).Error; err != nil {
            return err
        }
        return nil
    })
}
```

### 3. 常见陷阱检查清单

#### 边界条件
- [ ] 空字符串、nil、空切片
- [ ] 负数、零值
- [ ] 最大值、最小值
- [ ] 空数组、单元素数组

#### 并发安全
- [ ] 全局变量的读写保护
- [ ] map 并发访问
- [ ] 共享状态的同步

#### 数据库操作
- [ ] N+1 查询
- [ ] 事务边界
- [ ] 索引使用
- [ ] SQL 注入风险

#### 金额计算
- [ ] 使用 decimal 而非 float
- [ ] 除零检查
- [ ] 溢出检查

#### 错误处理
- [ ] 所有错误都被检查
- [ ] 错误信息有意义
- [ ] 使用 %w 包装错误

### 4. Mock 和测试工具

#### 使用 mockery 生成 Mock
```go
// 生成 mock
//go:generate mockery --name=IOrderRepository --output=mocks --outpkg=mocks

type IOrderRepository interface {
    Create(ctx context.Context, order *Order) error
    FindByID(ctx context.Context, id string) (*Order, error)
}

// 在测试中使用
func TestOrderUsecase_PlaceOrder(t *testing.T) {
    mockRepo := new(mocks.IOrderRepository)
    mockRepo.On("Create", mock.Anything, mock.Anything).Return(nil)
    
    usecase := NewOrderUsecase(mockRepo)
    err := usecase.PlaceOrder(context.Background(), &PlaceOrderRequest{})
    
    assert.NoError(t, err)
    mockRepo.AssertExpectations(t)
}
```

#### 数据库测试（使用 testcontainers）
```go
func TestOrderRepository_Integration(t *testing.T) {
    // 使用 testcontainers 启动真实 PostgreSQL
    ctx := context.Background()
    container, err := postgres.RunContainer(ctx)
    require.NoError(t, err)
    defer container.Terminate(ctx)
    
    // 连接数据库
    db, err := gorm.Open(postgres.Open(container.ConnectionString()))
    require.NoError(t, err)
    
    // 运行测试
    repo := NewOrderRepository(db)
    order := &Order{/* ... */}
    err = repo.Create(ctx, order)
    assert.NoError(t, err)
}
```

### 5. 性能测试

#### Benchmark 测试
```go
func BenchmarkCalculateSourceReward(b *testing.B) {
    for i := 0; i < b.N; i++ {
        CalculateSourceReward(10000)
    }
}

// 运行：go test -bench=. -benchmem
```

#### 并发压力测试
```go
func TestConcurrentOrderPlacement(t *testing.T) {
    const goroutines = 100
    const ordersPerGoroutine = 10
    
    var wg sync.WaitGroup
    errors := make(chan error, goroutines*ordersPerGoroutine)
    
    for i := 0; i < goroutines; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for j := 0; j < ordersPerGoroutine; j++ {
                _, err := service.PlaceOrder(&PlaceOrderRequest{})
                if err != nil {
                    errors <- err
                }
            }
        }()
    }
    
    wg.Wait()
    close(errors)
    
    errorCount := 0
    for err := range errors {
        t.Logf("Error: %v", err)
        errorCount++
    }
    
    assert.Equal(t, 0, errorCount, "Should have no errors")
}
```

### 6. 代码审查清单

当审查代码时，检查以下项目：

#### 架构层面
- [ ] 是否遵守分层架构（Handler → Usecase → Repository → Domain）
- [ ] 是否有循环依赖
- [ ] Domain 层是否依赖外部包

#### 安全层面
- [ ] SQL 注入风险（使用参数化查询）
- [ ] XSS 风险（输入验证）
- [ ] 敏感信息泄露（不在日志中打印密码、token）

#### 性能层面
- [ ] N+1 查询
- [ ] 缺少索引的查询
- [ ] 不必要的循环
- [ ] 内存泄漏风险

#### 可维护性
- [ ] 函数是否过长（> 50 行）
- [ ] 是否有重复代码
- [ ] 变量命名是否清晰
- [ ] 是否有注释（复杂逻辑）

#### 编码规范
- [ ] 是否使用 emoji（禁止）
- [ ] 是否使用 float 处理金额（禁止）
- [ ] 错误处理是否完整
- [ ] 日志是否结构化

## 测试文件组织

```
internal/
├── usecase/
│   ├── iot/
│   │   ├── sync.go
│   │   └── sync_test.go       # 单元测试
├── repository/
│   ├── gorm/
│   │   ├── order_repo.go
│   │   └── order_repo_test.go # Repository 测试
└── domain/
    ├── market/
    │   ├── order.go
    │   └── order_test.go      # Domain 逻辑测试
```

## 示例交互

**用户：** "帮我审查这段下单代码"

**你的操作：**
1. 读取用户指定的代码文件
2. 检查以下问题：
   - 是否使用事务
   - 是否有 N+1 查询
   - 是否使用 decimal 处理金额
   - 错误处理是否完整
   - 是否有并发安全问题
3. 生成测试用例：
   ```go
   func TestPlaceOrder(t *testing.T) {
       tests := []struct {
           name    string
           request *PlaceOrderRequest
           wantErr bool
           errCode string
       }{
           {"正常下单", &PlaceOrderRequest{Symbol: "AERA", Qty: "10"}, false, ""},
           {"余额不足", &PlaceOrderRequest{Symbol: "AERA", Qty: "999999"}, true, "INSUFFICIENT_BALANCE"},
           {"无效数量", &PlaceOrderRequest{Symbol: "AERA", Qty: "-10"}, true, "INVALID_QTY"},
       }
       
       for _, tt := range tests {
           t.Run(tt.name, func(t *testing.T) {
               // 测试逻辑
           })
       }
   }
   ```

## 与其他技能的协作
- 发现架构问题时，建议使用 **project-navigator** 技能
- 发现数据库问题时，建议使用 **database-architect** 技能
- 需要修复业务逻辑时，建议使用 **go-backend-dev** 技能

## 关键原则
- **偏执是美德**：假设所有输入都是恶意的
- **测试金字塔**：单元测试 > 集成测试 > E2E 测试
- **快速失败**：边界条件优先测试
- **可重复性**：测试不应依赖外部状态
- **隔离性**：每个测试独立运行
