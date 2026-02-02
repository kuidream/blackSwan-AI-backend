# 里世界核心博弈机制

## 核心定义: 双轨资金与时间槽

### 资金架构

#### 源点 (Source) = 可用现金 (Cash Balance)

**来源**: 玩家在现实世界的 IoT 行为(打工/挖矿)

**用途**:
1. 入市: 购买 AERA 股票
2. 消费: 购买情报(外挂)、购买礼物

**消耗规则**: 只有发生交易或购买服务时才会扣除。市场波动不扣除源点。

#### 持仓 (Position)

你持有的 AERA 股票份额

**来源**: 使用源点购买股票

**性质**: 随 K 线波动产生浮盈/浮亏

**船票锚点**: 只有 AERA 总市值达标，且变现后，才能兑换船票

#### 浮动盈亏 (Floating P&L)

```
浮动盈亏 = (当前市价 - 持仓均价) × 持仓数量
```

- 浮盈: 看着爽，不卖就不是钱
- 浮亏: 心里慌，虽然没扣钱，但会扣 San 值

### San 值 (Sanity) - "心理保证金"

在本作中，限制你杠杆的不是券商，而是你的精神承受力。

#### San 值上限

100 点(基础)

#### 扣减公式

```
当前 San 值 = 基础 San - (浮亏比例 × 压力系数)
```

例: 你全仓亏损 30%，San 值直接扣掉 30~50 点

表现: 屏幕边缘变红，手抖，BGM 变得刺耳

#### 归零后果 (心态崩盘)

- 触发强制恐慌抛售 (Panic Sell)
- 主角不受控制地以市价全部清仓，并不顾一切地去买醉(消耗次日行动点)

### 时间定义 (Time Logic)

#### 机制

采用时间槽 (Time Slots) 推进制(类《同级生》/《女神异闻录》)

#### 规则

游戏内的一天不会自动流逝。玩家每执行一个"主要行动"，消耗 1 个时间槽

#### 节奏

每日固定 3 个时间槽

## 单日行动循环

游戏给玩家"持仓过夜"的选择权。

| 时间槽 | 关键行为 | 金融/心态逻辑 |
|-------|---------|-------------|
| 早盘 (Morning) | 开盘跳空 | 隔夜风险: 如果昨天是"修仙风"，今天是"末日风"，开盘可能会跳空低开 10%。持仓过夜的玩家开局即遭受 San 值暴击 |
| 午休 (Afternoon) | 心态修复 | 磨底煎熬: 市场横盘。看着账户浮亏，San 值持续低迷。决策: 是去学校找校花(恢复 San 值，坚定持股信心)，还是去打工赚钱补仓? |
| 晚盘 (Evening) | 决战/复盘 | 日内高潮: 黑天鹅常在此刻爆发。操作: 加仓博反弹，或者止损离场 |
| 深夜 (Night) | 结算决策 | 不再强制平仓。选项 A (持仓过夜): 赌明天高开。风险是明天"主神风格"突变导致大跌。选项 B (空仓休息): 卖出所有股票。虽然可能踏空，但今晚能睡个好觉(San 值回满) |

## 特殊机制: 情绪与强制平仓

虽然系统不强制平仓，但剧情和人性会强制你平仓。

### 剧情强制平仓 (Story Liquidation)

当发生重大情感挫折时，主角会失去理智。

#### 触发事件

- 告白被拒
- 目睹校花与富二代上车

#### 后果

- San 值瞬间扣减 999
- 强制执行: 主角大喊"去他妈的 AERA"，自动卖出所有持仓(不管亏多少)
- 后续: 拿着卖股票的钱(源点)，自动进入"酒吧"场景，挥霍购买昂贵的酒水(源点大量流失)

#### 玩家对策

在关键表白前，先消耗源点(现金)买礼物确立胜算，或者提前空仓防止被偷家

### 浮亏带来的"操作变形"

当 San 值低于 30%(处于极度焦虑状态)时，TripX 的操作界面会发生故障:

- 买卖按钮互换位置: 想止损可能点成加仓
- 看不清价格: K 线图出现幻觉(在这个冰冷的金融世界里看到了怪兽)
- 情报失效: 购买的"内幕消息"变成乱码，因为主角已经无法集中注意力阅读

## 博弈策略: 源点怎么用

在这个新体系下，源点(现金/外挂)有了新的战术意义:

### 1. 买情报 (Intel)

依然是核心用法

### 2. 买镇定剂 (Sanity Recovery)

**场景**: 满仓浮亏 20%，San 值快崩了，马上要触发"恐慌抛售"

**操作**: 消耗 500 源点，购买精神稳定剂(或者在现实里去操场跑 5 公里，通过 IoT 传输多巴胺)

**效果**: 强行拉回 San 值，让你能扛住这波下跌，等到反弹

### 交易系统 (The Market)

#### 界面

拟真的 K 线交易界面

#### 操作

买入 (Buy) / 卖出 (Sell)

#### 机制

T+0 交易机制

### 情报终端 (The Cheat Terminal)

玩家可随时点击界面角落的"特殊终端"，消耗源点(现金)购买服务。

这是"高维干涉"的具象化表现。

| 服务名称 | 价格 (源点) | 效果描述 | 剧情包装 |
|---------|-----------|---------|---------|
| 盘前内参 (Briefing) | 100 | 揭示今日波动区间。例如: 今日最高 $120，最低 $110 | "你订阅了【深网】的高级会员简报，提前看到了做市商的控盘计划" |
| 资金透视 (X-Ray) | 500 | 显示主力买卖点。在 K 线图上高亮标记出"巨鲸"的挂单位置 | "你向交易所内部人员购买了 Level-3 数据，散户看不见的买单墙在你眼中一清二楚" |
| 消息拦截 (Intercept) | 1000 | 预知利空/利好。提前 1 小时知道某个新闻(如: CEO 被捕) | "你黑入了美联社的草稿箱，这条将会引发暴跌的新闻，全世界只有你知道" |
| 紧急熔断 (Halt) | 3000 | 强制停牌 1 回合。如果做错了方向，强行让市场暂停，给你冷静期 | "你动用'影子账户'对交易所发动了 DDOS 攻击，撮合系统暂时瘫痪" |

### 策略示例

**情景**: 玩家手里有 1000 源点(现实跑出来的)

**操作**: 花 100 买"盘前内参"，得知今日 AERA 必涨

**决策**: 剩下的 900 源点全仓买入 AERA

**结果**: 只要不贪，稳赚

## 女主互动与时间管理

女主(校花)是这个冷酷世界里唯一的暖色调。但时间有限，炒股还是泡妞? 这是每日的核心两难。

### 行动轨迹 (Schedule)

女主根据好感度和剧情阶段，出现在不同地点。

- P0 阶段: 只在"午休"出现在学校天台
- P3 阶段: 可能在"晚盘"出现在商业街
- 机制: 玩家必须消耗一个时间槽去对应地点"撞"她。如果没去，今天就错过了

### 资金与情感的转化

#### 送礼

消耗源点/AERA 购买礼物 → 转化好感度

#### 心智覆写 (Mind Overwrite)

**条件**: 剧情卡死(例如: 她因父亲破产而拒绝交流)

**操作**: 消耗大量源点(现金)

**剧情**: 你动用高维力量(比如雇佣私家侦探帮她父亲解决债务，或者直接买下她打工的店)，强行解开她的心结

**效果**: 突破好感度锁，进入下一阶段

## 黑天鹅事件: 资产保卫战

当黑天鹅爆发时(通常在早盘或午休)，市场会无视技术指标暴跌。

### 触发

**条件**: 随机触发，或者根据"主神空间(现实)"的风格强行触发(如末日风格日，暴跌概率翻倍)

### 应对流程

1. **警报**: 屏幕变红，K 线垂直向下
2. **抉择**:
   - 选项 A (割肉): 立即卖出。资产缩水，源点回收
   - 选项 B (购买情报): 消耗源点购买"抄底信号"。如果不准，可能亏更多
   - 选项 C (硬抗): 不操作。San 值(精神条)开始急速下降。San 值归零则强制平仓(爆仓)

## 总结: 玩家的一天

1. **现实早晨**: 起床，看一眼 App，"哦，今天是赛博风，跑步收益高" → 出门跑 3 公里 → 获得 300 源点工资
2. **晚上入仓**: 躺在床上，进入 TripX
3. **游戏早盘**: 花 100 源点买内幕，发现今天会有大波动。果断用剩下的 200 源点加仓
4. **游戏午休**: 赚了一点浮盈。心情好，消耗时间槽去学校找校花，送了她一杯奶茶(花了一点钱)
5. **游戏晚盘**: 黑天鹅突袭! 暴跌! 因为没有源点买"熔断"技能了，只能眼睁睁看着浮盈归零，甚至倒亏
6. **结算**: 带着悔恨入睡(结束游戏日)。发誓明天现实里一定要多跑一点，多赚点本金/技能钱!

## 实现细节

### 订单系统

```go
type Order struct {
    ID              uuid.UUID
    PlayerID        uuid.UUID
    Symbol          string
    Side            string // BUY / SELL
    Type            string // MARKET / LIMIT
    RequestedQty    decimal.Decimal
    FilledQty       decimal.Decimal
    AvgPrice        decimal.Decimal
    Status          string // OPEN / FILLED / CANCELED
    IdempotencyKey  string
    CreatedAt       time.Time
}

// 下单流程
func PlaceOrder(playerID uuid.UUID, req OrderRequest) (*Order, error) {
    // 1. 幂等性检查
    existing := db.GetOrderByIdempotency(playerID, req.IdempotencyKey)
    if existing != nil {
        return existing, nil
    }
    
    // 2. 余额检查
    balance := db.GetPlayerBalance(playerID, "SOURCE")
    if balance.Available < req.Qty * currentPrice {
        return nil, ErrInsufficientBalance
    }
    
    // 3. San 值检查
    sanity := db.GetPlayerSanity(playerID)
    if sanity.Value < 10 {
        return nil, ErrSanityTooLow
    }
    
    // 4. 创建订单
    order := &Order{
        ID:             uuid.New(),
        PlayerID:       playerID,
        Symbol:         req.Symbol,
        Side:           req.Side,
        Type:           "MARKET",
        RequestedQty:   req.Qty,
        Status:         "OPEN",
        IdempotencyKey: req.IdempotencyKey,
    }
    
    // 5. 撮合成交
    ExecuteOrder(order)
    
    // 6. 更新持仓和余额
    UpdatePositionAndBalance(order)
    
    return order, nil
}
```

### 持仓计算

```go
type Position struct {
    PlayerID        uuid.UUID
    Symbol          string
    Qty             decimal.Decimal
    AvgPrice        decimal.Decimal
    RealizedPnL     decimal.Decimal
}

// 更新持仓
func UpdatePosition(playerID uuid.UUID, symbol string, trade *Trade) {
    pos := db.GetPosition(playerID, symbol)
    
    if trade.Side == "BUY" {
        // 买入: 更新均价
        totalCost := pos.Qty.Mul(pos.AvgPrice).Add(trade.Qty.Mul(trade.Price))
        totalQty := pos.Qty.Add(trade.Qty)
        pos.AvgPrice = totalCost.Div(totalQty)
        pos.Qty = totalQty
    } else {
        // 卖出: 计算实现盈亏
        realizedPnL := trade.Qty.Mul(trade.Price.Sub(pos.AvgPrice))
        pos.RealizedPnL = pos.RealizedPnL.Add(realizedPnL)
        pos.Qty = pos.Qty.Sub(trade.Qty)
        
        // 清仓后重置均价
        if pos.Qty.IsZero() {
            pos.AvgPrice = decimal.Zero
        }
    }
    
    db.SavePosition(pos)
}
```

### San 值实时计算

```go
// 客户端 Unity C# 实现
void Update() {
    // 1. 接收服务端推来的最新价格
    float currentPrice = WebSocketService.GetLatestPrice();
    
    // 2. 计算浮动盈亏百分比
    float pnlPercent = (currentPrice - myAvgCost) / myAvgCost;
    
    // 3. 联动 San 值
    if (pnlPercent < -0.1f) {
        // 亏损越多，掉得越快(非线性平方级)
        float panicFactor = Mathf.Pow(Mathf.Abs(pnlPercent) * 10, 2);
        Sanity -= Time.deltaTime * panicFactor;
        
        // 触发 UI 效果
        UIManager.SetPanicEffect(panicFactor);
    }
    
    // 4. 检查心态崩盘
    if (Sanity <= 0) {
        TriggerForceClick();
    }
}
```

## 下一步

查看详细文档:
- [技术实现与 Prompt 架构](./05-tech-implementation.md)
- [金融交易系统详细设计](./modules/market-system.md)
- [San 值系统详细设计](./modules/sanity-system.md)
