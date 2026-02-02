# 金融交易与行情演算系统详细设计

## 模块概述

本模块负责里世界 (TripX) 的核心玩法: 在被操控的行情中博弈。

### 服务端 (Go)

运行 Ticker Engine，根据算法实时广播 Pt (价格)

### 客户端 (Unity)

绘制动态 K 线，处理 T+0 交易请求，计算浮动盈亏

### 数据流

WebSocket 全双工通信

## 交易规则定义

为了模拟"高频末日金融"，规则与现实股市有差异。

### 基础机制

- **交易标的**: AERA (游戏内唯一的超级公司股票) 或其衍生 ETF
- **交易时间**: 游戏内时间 09:30 - 15:00 (中间无休)
- **交易机制**: T+0 (即买即卖)
- **涨跌幅**: 无限制 (方便制造 50% 的暴跌)
- **手续费**:
  - 买入: 0%
  - 卖出: 0.1% (以源点结算，若源点不足则从成交额中扣除)

### 订单类型

为了简化操作，只提供两种订单:

**1. 市价单 (Market Order)**:
- 定义: 立即以当前最优价成交
- 滑点 (Slippage): 正常行情 0.1%，暴跌行情(黑天鹅)下扩大至 5%~10% (模拟流动性枯竭)

**2. 技能单 (Skill Order)**:
- 定义: 消耗源点发动的特殊操作(如"熔断")

## 行情演算引擎详细设计

这是后端 Go 服务的核心逻辑。

### 价格广播协议 (WebSocket)

服务端每 200ms 推送一次 Tick 数据包。

```json
{
  "symbol": "AERA",
  "timestamp": 1738029283,
  "price": 124.56,
  "volume": 5000,
  "trend_flag": -1,
  "delta_debug": {
    "burst_weight": 0.02,
    "anti_luck_factor": -0.05
  }
}
```

**字段说明**:
- trend_flag: -1:暴跌中(触发UI红光), 0:正常, 1:暴涨
- delta_debug: 仅开发期可见，用于调试算法

### 扰动因子算法实现

对应价格演算公式中的 δₜ。

#### A. 爆仓吸引 (δ_burst)

**触发逻辑**:
1. 遍历在线玩家持仓
2. 计算加权平均爆仓价 (Weighted Liquidation Price)
3. 若 (当前价 - 平均爆仓价) / 当前价 < 0.05 (距离 5%)
4. 生效: 施加一个指向爆仓价的引力向量

**数值配置**: 引力系数不宜过大，要让价格呈现"磨蹭、试探"的感觉，最大程度消耗玩家 San 值

#### B. 连胜惩罚 (δ_antiLuck)

**判定**: 玩家最近 5 笔交易 胜率 > 80% 且 盈利 > 总资产 20%

**生效**:
- 玩家买入瞬间 → 施加 -0.5% 的瞬时滑点
- 持仓期间 → 波动率噪音 (ηₜ) 放大 1.5 倍(更容易被震仓出局)

#### C. 黑天鹅事件 (δ_blackSwan)

**触发**: 根据 Cfg_Market_Event 表

**表现**: 连续 10 个 Tick 都是单边下跌，且拒绝成交(模拟拔网线)

**解除**: 持续时间结束，或全服玩家投入的"熔断技能"总量达标

## 实现示例

### Ticker Engine 核心代码

```go
type TickerEngine struct {
    symbol         string
    currentPrice   decimal.Decimal
    baseVolatility float64
    growthRate     float64
    players        map[uuid.UUID]*PlayerPosition
    hub            *websocket.Hub
}

func (te *TickerEngine) Start() {
    ticker := time.NewTicker(200 * time.Millisecond)
    defer ticker.Stop()
    
    for range ticker.C {
        // 1. 计算基础波动
        mu := te.growthRate
        eta := te.calculateNoise()
        
        // 2. 计算条件扰动
        delta := te.calculateDelta()
        
        // 3. 合成新价格
        change := mu + eta + delta
        newPrice := te.currentPrice.Mul(decimal.NewFromFloat(1 + change))
        
        // 防止负数或过小
        if newPrice.LessThan(decimal.NewFromFloat(0.01)) {
            newPrice = decimal.NewFromFloat(0.01)
        }
        
        // 4. 构建 Tick 数据
        tick := MarketTick{
            Symbol:    te.symbol,
            Timestamp: time.Now().Unix(),
            Price:     newPrice,
            Volume:    te.calculateVolume(),
            TrendFlag: te.determineTrend(delta),
        }
        
        // 5. 广播
        te.hub.Broadcast(tick)
        
        // 6. 更新当前价格
        te.currentPrice = newPrice
    }
}

func (te *TickerEngine) calculateDelta() float64 {
    var delta float64
    
    // A. 爆仓吸引
    burstDelta := te.calculateBurstAttraction()
    delta += burstDelta
    
    // B. 连胜惩罚
    antiLuckDelta := te.calculateAntiLuck()
    delta += antiLuckDelta
    
    // C. 黑天鹅
    if te.isBlackSwanActive() {
        delta -= 0.4 // 暴跌 40%
    }
    
    return delta
}

func (te *TickerEngine) calculateBurstAttraction() float64 {
    // 计算所有玩家的加权平均爆仓价
    var totalWeight decimal.Decimal
    var weightedSum decimal.Decimal
    
    for _, pos := range te.players {
        if pos.Qty.IsZero() {
            continue
        }
        
        // 计算该玩家的爆仓价 (简化: 假设 San 值归零时爆仓)
        // 实际应根据玩家当前 San 值和浮亏计算
        weight := pos.Qty
        totalWeight = totalWeight.Add(weight)
        
        // 爆仓价 = 成本价 * (1 - 最大可承受浮亏)
        liquidationPrice := pos.AvgPrice.Mul(decimal.NewFromFloat(0.7))
        weightedSum = weightedSum.Add(liquidationPrice.Mul(weight))
    }
    
    if totalWeight.IsZero() {
        return 0
    }
    
    avgLiquidationPrice := weightedSum.Div(totalWeight)
    
    // 计算距离
    distance := te.currentPrice.Sub(avgLiquidationPrice).Div(te.currentPrice)
    
    // 如果距离小于 5%，施加引力
    if distance.LessThan(decimal.NewFromFloat(0.05)) {
        // 距离越近，引力越大
        attraction := 0.005 * (1 - distance.InexactFloat64()/0.05)
        return -attraction // 负值表示向下
    }
    
    return 0
}
```

### 订单处理逻辑

```go
type OrderService struct {
    repo          OrderRepository
    walletService WalletService
    sanityService SanityService
    tickerEngine  *TickerEngine
}

func (s *OrderService) PlaceOrder(ctx context.Context, req *PlaceOrderRequest) (*Order, error) {
    // 1. 幂等性检查
    existing, _ := s.repo.GetByIdempotency(req.PlayerID, req.IdempotencyKey)
    if existing != nil {
        return existing, nil
    }
    
    // 2. San 值检查
    sanity, err := s.sanityService.GetPlayerSanity(req.PlayerID)
    if err != nil {
        return nil, err
    }
    if sanity.Value < 10 {
        return nil, ErrSanityTooLow
    }
    
    // 3. 获取当前价格
    currentPrice := s.tickerEngine.GetCurrentPrice()
    
    // 4. 计算所需资金
    totalCost := currentPrice.Mul(req.Qty)
    
    // 5. 余额检查
    if req.Side == "BUY" {
        balance, _ := s.walletService.GetBalance(req.PlayerID, "SOURCE")
        if balance.Available.LessThan(totalCost) {
            return nil, ErrInsufficientBalance
        }
    } else {
        position, _ := s.repo.GetPosition(req.PlayerID, req.Symbol)
        if position.Qty.LessThan(req.Qty) {
            return nil, ErrInsufficientPosition
        }
    }
    
    // 6. 计算滑点
    slippage := s.calculateSlippage(req, currentPrice)
    executionPrice := currentPrice.Add(slippage)
    
    // 7. 创建订单
    order := &Order{
        ID:             uuid.New(),
        PlayerID:       req.PlayerID,
        Symbol:         req.Symbol,
        Side:           req.Side,
        Type:           "MARKET",
        RequestedQty:   req.Qty,
        FilledQty:      req.Qty,
        AvgPrice:       executionPrice,
        Status:         "FILLED",
        IdempotencyKey: req.IdempotencyKey,
        CreatedAt:      time.Now(),
    }
    
    // 8. 创建成交记录
    trade := &Trade{
        ID:        uuid.New(),
        OrderID:   order.ID,
        PlayerID:  req.PlayerID,
        Symbol:    req.Symbol,
        Qty:       req.Qty,
        Price:     executionPrice,
        FeeAmount: totalCost.Mul(decimal.NewFromFloat(0.001)), // 0.1% 手续费
        ExecutedAt: time.Now(),
    }
    
    // 9. 更新持仓和余额
    err = s.updatePositionAndBalance(order, trade)
    if err != nil {
        return nil, err
    }
    
    // 10. 保存订单
    err = s.repo.SaveOrder(order)
    if err != nil {
        return nil, err
    }
    
    return order, nil
}
```

## 配表需求

### Cfg_Stock_Market.xlsx

| Style_ID | Base_Volatility | Volume_Multiplier | Slippage_Rate | Desc |
|----------|----------------|------------------|---------------|------|
| Xianxia | 0.02 | 1.0 | 0.05% | 修仙日: 古波不惊，适合养生 |
| Cyber | 0.05 | 2.5 | 0.2% | 赛博日: 量化收割，上下插针 |
| Doom | 0.08 | 0.1 | 5.0% | 末日日: 流动性归零，买卖极难 |

### Cfg_Intel_Shop.xlsx

| ID | Name_Key | Cost_Source | Effect_Type | Effect_Params | CD_GameTime |
|----|----------|-------------|-------------|---------------|-------------|
| 1 | 盘前内参 | 100 | SHOW_RANGE | Range=0.8 | 1 Day |
| 2 | 资金透视 | 500 | SHOW_WHALE | Depth=3 | 60 Min |
| 3 | 紧急熔断 | 1000 | FREEZE_MARKET | Duration=30s | 1 Day |

### Cfg_Market_Event.xlsx

| ID | Style_Tag | Type | Probability | Impact_Delta | Duration | News_Template_Key |
|----|-----------|------|-------------|--------------|----------|-------------------|
| 901 | Cyber | CRASH | 0.05 | -0.3 | 60 | NEWS_CYBER_HACK |
| 902 | Xianxia | BOOM | 0.02 | +0.5 | 120 | NEWS_XIANXIA_ASCEND |

## UI/UX 详细设计

### K 线图表控件

**基础功能**: 支持 M1 (分时), M15, H1 切换

**特殊渲染**:
- San 值低时: K 线出现重影 (Ghosting) 和 色差故障 (Glitch)
- 黑天鹅时: 整个图表背景泛红，K 线变成类似"触手"或"闪电"的扭曲形状

### 下单面板

**极简设计**: 只有 BUY (绿/蓝) 和 SELL (红)

**长按机制**:
- 为了增加紧张感，大额交易需要 长按 1 秒 确认
- 长按期间，手机马达跟随心跳频率震动(调用 Taptic Engine)

### 情报终端

**入口**: K 线图右上角的"一只眼睛"图标

**交互**:
1. 点击图标 → 弹出雷达扫描动画
2. 扣除源点 → 动画定格，生成一份"机密文件"UI
3. 视觉化展示: 不只是文字，直接在 K 线图上画出一条虚线(预测轨迹)

### 浮亏反馈

当 Floating PnL < -10% 时:

1. **视觉**: 屏幕边缘出现暗角 (Vignette) 和血丝
2. **听觉**: 背景白噪音 (空调声/电流声) 变大，盖过 BGM
3. **触觉**: 每次价格下跌 Tick，手机轻微震动一下

## 监控与优化

### 关键指标

- WebSocket 连接数: 实时监控
- Tick 推送延迟: < 50ms
- 订单处理延迟: < 100ms
- 成交成功率: > 99.9%

### 性能优化

- Goroutine 池管理
- WebSocket 连接池
- 价格数据缓存
- 批量广播优化

## 下一步

查看相关文档:
- [市场博弈机制](../04-market-mechanism.md)
- [技术实现](../05-tech-implementation.md)
- [San 值系统](./sanity-system.md)
