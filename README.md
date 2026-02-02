# blackSwan AI Backend

blackSwan 是一个基于现实映射的、无限流风格的自动演进式 RPG 游戏后端系统。项目采用 Golang + PostgreSQL 技术栈，结合 AI 大模型实现动态世界演进机制。

## 快速开始

### 1. 环境准备

确保已安装:
- Go 1.21+
- PostgreSQL 14+
- Redis 6+

### 2. 配置环境

```bash
# 复制环境配置
cp .env.example .env

# 编辑 .env 文件，填入数据库和 Redis 连接信息
```

### 3. 安装依赖

```bash
go mod download
```

### 4. 运行服务

```bash
go run cmd/api/main.go
```

服务启动在 http://localhost:8080

### 5. 测试接口

```bash
# 健康检查
curl http://localhost:8080/health

# API 测试
curl http://localhost:8080/v1/ping
```

## 项目概述

## 技术架构

### 核心技术栈

- **后端框架**: Golang + Gin
- **数据库**: PostgreSQL (GORM ORM) + Redis (缓存)
- **通信协议**: RESTful API + WebSocket (行情推送)
- **AI 服务**: OpenAI API / Claude API (文本生成)
- **客户端**: Unity 2022+ (C#)

### 架构特点

1. **三层架构**
   - Handler Layer: 处理 HTTP/WebSocket 请求
   - Usecase Layer: 业务逻辑层
   - Repository Layer: 数据访问层
   - Domain Layer: 领域模型

2. **实时行情引擎**
   - Ticker Engine: 200ms 推送频率
   - WebSocket 全双工通信
   - 价格演算基于数学模型

3. **AI 演进系统**
   - 每日风格生成 (00:00)
   - 实时情报渲染
   - Prompt 模板化管理

## 开发规范

### 代码规范

#### 1. 命名规范

```go
// 包命名: 小写单词
package marketengine

// 接口命名: I + 名词
type IMarketService interface {}

// 结构体命名: 大驼峰
type MarketTick struct {}

// 函数命名: 大驼峰 (公开) / 小驼峰 (私有)
func CalculatePrice() {}
func calculateDelta() {}

// 变量命名: 小驼峰
var playerBalance int64

// 常量命名: 大驼峰或全大写
const MaxDailySteps = 20000
const API_VERSION = "v1"
```

#### 2. 注释规范

```go
// CalculateSourceReward 计算源点奖励
// 基于 IoT 数据和当日风格配置计算玩家可获得的源点数量
// 参数:
//   - steps: 步数
//   - styleConfig: 当日风格配置
// 返回:
//   - reward: 源点奖励数量
//   - error: 错误信息
func CalculateSourceReward(steps int, styleConfig *StyleConfig) (int64, error) {
    // 实现逻辑
}
```

禁止使用:
- Emoji 表情
- 图形符号 (→ ← ↑ ↓ ★ ☆)
- 过度装饰 (=== --- ***)

#### 3. 错误处理

```go
// 使用标准错误处理
if err != nil {
    return nil, fmt.Errorf("failed to calculate reward: %w", err)
}

// 定义业务错误
var (
    ErrInsufficientBalance = errors.New("insufficient balance")
    ErrInvalidPrice = errors.New("invalid price")
)
```

#### 4. 日志规范

```go
// 使用结构化日志
log.Info("order placed successfully",
    "order_id", orderId,
    "player_id", playerId,
    "symbol", "AERA",
)

// 禁止使用 emoji
// 错误示例: log.Info("✅ 订单成功")
// 正确示例: log.Info("order placed successfully")
```

### 数据库规范

#### 1. 表命名规范

- 使用小写字母和下划线
- 表名使用单数形式
- 关联表使用下划线连接

```sql
-- 主表
CREATE TABLE player (...)
CREATE TABLE market_order (...)

-- 关联表
CREATE TABLE player_npc_interaction (...)
```

#### 2. 字段命名规范

```sql
-- 主键统一使用 id (UUID)
id UUID PRIMARY KEY DEFAULT gen_random_uuid()

-- 时间戳字段统一命名
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at TIMESTAMPTZ NOT NULL DEFAULT now()

-- 布尔字段使用 is_ 前缀
is_active BOOLEAN NOT NULL DEFAULT TRUE

-- 金额字段使用 NUMERIC 避免精度问题
amount NUMERIC(30, 10) NOT NULL
```

#### 3. 索引规范

```sql
-- 索引命名: idx_表名_字段名
CREATE INDEX idx_player_balance_player_id ON player_balance(player_id);

-- 唯一索引命名: uq_表名_字段名
CREATE UNIQUE INDEX uq_market_order_idempotency ON market_order(player_id, idempotency_key);
```

### API 规范

#### 1. RESTful API 设计

```
Base URL: /v1

认证: Authorization: Bearer <access_token>

幂等: Idempotency-Key (用于写操作)
```

#### 2. 统一响应格式

```json
// 成功响应
{
  "request_id": "uuid",
  "server_time": 1738029283,
  "data": {}
}

// 错误响应
{
  "request_id": "uuid",
  "server_time": 1738029283,
  "error": {
    "code": "INSUFFICIENT_BALANCE",
    "message": "余额不足",
    "details": {}
  }
}
```

#### 3. 错误码规范

```go
// 错误码定义
const (
    ErrCodeInvalidRequest     = "INVALID_REQUEST"
    ErrCodeUnauthorized       = "UNAUTHORIZED"
    ErrCodeInsufficientBalance = "INSUFFICIENT_BALANCE"
    ErrCodeSanityLow          = "SANITY_LOW"
    ErrCodeMarketClosed       = "MARKET_CLOSED"
)
```

### Git 提交规范

```bash
# 格式: <type>: <subject>

# Type 类型
feat: 新功能
fix: 修复 bug
docs: 文档更新
refactor: 重构代码
perf: 性能优化
test: 测试相关
chore: 构建/工具链相关

# 示例
feat: 添加 IoT 数据同步接口
fix: 修复行情推送延迟问题
docs: 更新 API 文档
refactor: 重构订单撮合逻辑
```

禁止使用 emoji:
- 错误: `✨ feat: 添加新功能`
- 正确: `feat: 添加用户认证功能`

## 项目结构

```
blackSwan-AI-backend/
├── .ai/                    # AI 工具文档目录
│   ├── README.md           # 本文件
│   ├── docs/              # 核心文档
│   │   ├── 01-architecture.md
│   │   ├── 02-world-setting.md
│   │   ├── 03-time-mapping.md
│   │   ├── 04-market-mechanism.md
│   │   ├── 05-tech-implementation.md
│   │   ├── 06-economy-model.md
│   │   └── modules/       # 模块详细文档
│   ├── database/          # 数据库文档
│   │   └── schema.sql
│   └── api/               # API 文档
│       └── api-reference.md
├── cmd/                   # 应用入口
├── internal/              # 内部代码
│   ├── handler/          # HTTP 处理器
│   ├── usecase/          # 业务逻辑
│   ├── repository/       # 数据访问
│   ├── domain/           # 领域模型
│   └── config/           # 配置
├── pkg/                   # 公共库
├── migrations/           # 数据库迁移
└── docs/                 # 原始文档 (保留)
```

## 核心业务流程

### 1. 玩家一天的游戏流程

```
1. 现实早晨 → 查看今日主神风格
2. 进行 IoT 活动 (跑步/睡眠) → 获得源点
3. 晚上进入 TripX 模拟仓
4. 使用源点进行交易/购买情报/互动女主
5. 应对黑天鹅事件
6. 结算 San 值和资产
```

### 2. 系统演进流程

```
1. 每日 00:00 执行定时任务
2. 从语料库抽取文本片段
3. 调用 LLM 生成当日风格配置
4. 缓存到 Redis
5. 客户端读取配置渲染 UI
```

### 3. 交易流程

```
1. 客户端通过 WebSocket 接收实时行情
2. 玩家下单 (附带 Idempotency-Key)
3. 服务端验证余额和 San 值
4. 执行订单撮合
5. 更新持仓和余额
6. 计算浮动盈亏
7. 实时更新 San 值
```

## 关键配置

### 行情引擎参数

```yaml
ticker:
  interval: 200ms           # Tick 推送频率
  volatility_base: 0.02     # 基础波动率
  growth_rate: 0.0012       # 长期增长率
```

### IoT 奖励参数

```yaml
iot_reward:
  steps_rate: 0.1           # 每 10 步 = 1 源点
  daily_cap: 2000           # 日上限 2000 源点
  sleep_rate: 100           # 每小时 100 源点
```

### LLM 调用参数

```yaml
llm:
  model_daily: gpt-4o        # 每日风格生成
  model_intel: gpt-4o-mini   # 实时情报
  max_tokens_daily: 500
  max_tokens_intel: 100
  temperature: 0.7
```

## 安全注意事项

### 1. 防作弊机制

- 速度物理墙: 步数变化率检查
- 时间旅行检测: 时间戳校验
- 重复哈希检测: 防止重放攻击
- 异常行为画像: 连胜惩罚机制

### 2. 幂等性保证

所有写操作支持 `Idempotency-Key`:
- IoT 数据同步
- 订单提交
- 商品购买
- NPC 互动

### 3. 敏感信息处理

- LLM 输入脱敏
- 输出内容过滤
- 敏感词黑名单
- 审计日志记录

## 性能优化

### 1. 数据库优化

- 行情 Tick 表分区存储
- 冷热数据分离
- 合理使用索引
- 连接池配置

### 2. 缓存策略

- Redis 缓存每日风格配置
- 行情数据缓存 (最近 N 条)
- 玩家状态缓存
- LLM 结果缓存 (相同输入)

### 3. 并发处理

- Goroutine 池管理
- WebSocket 连接池
- 数据库连接池
- 限流和熔断

## 测试规范

### 1. 单元测试

```go
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
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // 测试逻辑
        })
    }
}
```

### 2. 集成测试

- API 端到端测试
- WebSocket 通信测试
- 数据库操作测试

### 3. 压力测试

- 行情推送压力测试
- 并发下单测试
- LLM 调用压力测试

## 部署规范

### 1. 环境配置

- 开发环境 (dev)
- 测试环境 (staging)
- 生产环境 (prod)

### 2. 配置管理

```yaml
# config.yaml
server:
  port: 8080
  mode: release

database:
  host: localhost
  port: 5432
  name: blackswan
  
redis:
  host: localhost
  port: 6379
```

### 3. 监控告警

- API 响应时间监控
- 数据库连接数监控
- LLM 调用成本监控
- 错误率监控

## 文档维护

### 1. 文档更新流程

1. 修改 `.ai/docs/` 中的相关文档
2. 同步更新 API 文档
3. 更新数据库迁移脚本
4. 提交 PR 并 Review

### 2. 文档版本控制

- 重大变更需要版本标记
- 保留历史文档 (归档)
- 变更日志 (CHANGELOG.md)

## 相关资源

### 内部文档

- [架构总览](./docs/01-architecture.md)
- [世界观设定](./docs/02-world-setting.md)
- [时空映射](./docs/03-time-mapping.md)
- [市场机制](./docs/04-market-mechanism.md)
- [技术实现](./docs/05-tech-implementation.md)
- [经济模型](./docs/06-economy-model.md)
- [API 参考](./api/api-reference.md)
- [数据库 Schema](./database/schema.sql)

### 模块文档

- [IoT 与资源映射系统](./docs/modules/iot-system.md)
- [金融交易与行情系统](./docs/modules/market-system.md)
- [San 值系统](./docs/modules/sanity-system.md)
- [AI 演进系统](./docs/modules/ai-evolution.md)
- [角色互动系统](./docs/modules/npc-interaction.md)

## 联系方式

如有问题或建议，请提交 Issue 或联系开发团队。

## License

本项目为内部开发项目，所有权归项目团队所有。
