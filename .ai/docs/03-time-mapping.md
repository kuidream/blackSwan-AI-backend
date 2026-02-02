# 自动化演进与时空映射机制

## 时空相对论: 双重时间轴

为了解决"快节奏游戏"与"慢节奏现实"的冲突，我们定义两条平行的时间轴。

### 现实轴 (Real-Time Axis) - "天时"

#### 定义

物理地球的时间 (UTC+8)

#### 控制对象

主神空间风格 (The Style)

#### 更新频率

每日 00:00 全局刷新

#### 逻辑

无论你在游戏里玩到了第几天，只要现实是 2026年1月27日，主神空间(以及 TripX 的外部环境)就一直是【修仙风格】。

这就像"天气"。不管你在屋里(游戏里)做了多少事，窗外(现实映射)今天一整天都在下雨。

#### 后端压力

极低。全服共享同一套每日 Config，LLM 每天只跑一次。

### 游戏轴 (Game-Time Axis) - "历练"

#### 定义

TripX 模拟仓内的虚拟时间 (P0-P7)

#### 控制对象

剧情推进、K线波动、资产结算

#### 更新频率

随玩家操作推进(点击"下一天/下一回合")

#### 逻辑

玩家在现实的一小时内，可以在 TripX 里度过"30个交易日"。在这 30 个交易日里，所有的黑天鹅事件、新闻描述，都会受到当日现实风格(修仙)的持续渲染。

## 演进机制: 全局天气

### 每日演进流程 (Server Side)

由后端 Main_God_Engine 在每日凌晨统一执行，生成当日的【世界补丁】。

#### 执行步骤

1. **抽取文本**: 从语料库读取《凡人修仙传.txt》片段
2. **生成规则**:
   - 风格标签: XIANXIA
   - IoT 映射表: 跑步 → 御剑; 睡觉 → 闭关
   - 叙事滤镜: "做空"重命名为"镇压"，"利好"重命名为"机缘"
3. **下发全服**: 所有登录玩家，今日看到的 UI 和文案都是修仙风

### 源点获取逻辑

#### 概念

玩家在物理地球的 IoT 行为，等同于在主神空间进行"资源采集"

#### 产出物

源点 (Source)

#### 在 TripX 中的定义

入金 (Deposit)。即玩家的初始本金和后续补充资金，全部来源于现实行为。

### 玩家体验: 跨维度的资金流

玩家在现实中的 IoT 行为，是为里世界账户"注入资金(入金)"。

#### 蓄能池 (Source Earning)

- 玩家在现实中跑步 5km(修仙日任务: 万里奔袭)
- 获得 500 源点
- 状态: 这 500 源点进入你的可用余额 (Cash Balance)

#### 博弈消耗 (Strategic Spending)

**场景 A (正常交易)**:
- 花费 300 源点买入 AERA 股票
- 结果: 现金剩 200，持仓市值 300
- 市场暴跌: 持仓市值跌到 100(浮亏)
- 状态: 现金余额依然是 200，不会减少

**场景 B (购买服务/外挂)**:
- 看着暴跌的盘面，玩家决定作弊
- 操作: 花费 100 源点(现金)购买"内幕消息"
- 结果: 现金剩 100。内幕显示"下午会反弹"
- 决策: 玩家决定死拿不卖，坐等反弹

**场景 C (资金枯竭)**:
- 如果玩家现实中不跑步(不打工)，账户里没现金
- 遇到暴跌想买内幕? 余额不足。只能眼睁睁看着或者盲猜

## 任务与 IoT 映射

任务系统绑定"现实日期"。为了适配智能手表，仅保留最核心的三类数据。

### 每日悬赏 (Daily Bounties)

这是一组只在现实当天有效的 IoT 目标。

| 现实日期 | 风格 | 悬赏任务 (Real World) | 奖励 (Source) | 游戏内 Buff (TripX) |
|---------|-----|---------------------|--------------|-------------------|
| 1月27日 | 修仙 | 【吐纳】保持心率平稳 30 分钟 | +300 | 今日进入游戏，San 值上限 +20% (文案: 道心稳固) |
| 1月28日 | 赛博 | 【充能】睡眠时长 > 7 小时 | +500 | 今日进入游戏，获得一次免费的"内幕消息" (文案: 系统维护完成) |

## 叙事渲染的并发处理

### 预生成与模板化 (Pre-generation)

为了减轻压力，我们不实时调用 LLM 生成每一条新闻。

#### 后端准备

每日生成风格时，同时生成一个【叙事词典 (Narrative Dictionary)】。

```json
{
  "style": "Xianxia",
  "replacements": {
    "stock_crash": ["宗门崩塌", "灵脉枯竭", "天劫降临"],
    "stock_rise": ["飞升", "顿悟", "紫气东来"],
    "heroine_happy": ["面露桃花", "道心通明"],
    "heroine_sad": ["心魔滋生", "元神受损"]
  }
}
```

#### 客户端渲染

- 原始文本: AERA 股价暴跌，校花感到恐慌
- 客户端替换后: AERA 遭遇【天劫降临】，校花【心魔滋生】
- 优势: 零延迟，零额外成本，风格统一

### 关键剧情的实时演算

只有在极少数关键节点(如: P7 结局、重要好感度突破)，才实时调用 LLM，结合当天的风格生成一段独一无二的剧情文本，存入玩家的"传记"。

## 时间槽机制 (Time Slot System)

### 概念

采用《同级生》《女神异闻录》式的时间槽推进制。

### 规则

- 游戏内的一天不会自动流逝
- 玩家每执行一个"主要行动"，消耗 1 个时间槽
- 每日固定 3 个时间槽

### 时间槽定义

| 时间槽 | 时间段 | 可执行行动 |
|-------|-------|----------|
| Morning | 早盘 | 查看开盘行情、购买情报 |
| Noon | 午休 | 交易、找校花、休息 |
| Evening | 晚盘 | 交易、约会、购买道具 |

### 时间管理策略

玩家必须在以下目标间做选择:
- 盯盘交易赚钱
- 陪伴女主提升好感度
- 休息恢复 San 值
- 购买情报/技能

## 持仓过夜机制

### 设计目标

给玩家"持仓过夜"的选择权，增加策略深度。

### 风险设计

#### 开盘跳空

如果昨天是"修仙风"，今天是"末日风"，开盘可能会跳空低开 10%。持仓过夜的玩家开局即遭受 San 值暴击。

#### 心态修复

市场横盘。看着账户浮亏，San 值持续低迷。决策: 是去学校找校花(恢复 San 值，坚定持股信心)，还是去打工赚钱补仓?

#### 决战/复盘

日内高潮: 黑天鹅常在此刻爆发。操作: 加仓博反弹，或者止损离场。

### 结算决策

#### 选项 A (持仓过夜)

- 赌明天高开
- 风险: 明天"主神风格"突变导致大跌

#### 选项 B (空仓休息)

- 卖出所有股票
- 虽然可能踏空，但今晚能睡个好觉(San 值回满)

## 系统实现细节

### 风格配置缓存

```go
// Redis 键结构
Key: "world:style:2026-02-02"
Value: StyleConfigJSON
TTL: 86400 seconds (1 day)

// 读取流程
func GetTodayStyle() (*StyleConfig, error) {
    date := time.Now().Format("2006-01-02")
    key := fmt.Sprintf("world:style:%s", date)
    
    // 尝试从 Redis 读取
    cached, err := redis.Get(key)
    if err == nil {
        return ParseStyleConfig(cached), nil
    }
    
    // 缓存未命中，从数据库读取
    config, err := db.GetWorldDayStyle(date)
    if err != nil {
        return nil, err
    }
    
    // 写入缓存
    redis.Set(key, config.ToJSON(), 86400)
    return config, nil
}
```

### 时间槽状态管理

```go
type PlayerDay struct {
    ID           uuid.UUID
    PlayerID     uuid.UUID
    WorldDate    time.Time
    TimeSlotTotal int  // 总时间槽 (默认 3)
    TimeSlotUsed  int  // 已使用时间槽
    StartedAt    time.Time
    EndedAt      *time.Time
}

// 消耗时间槽
func (pd *PlayerDay) ConsumeTimeSlot() error {
    if pd.TimeSlotUsed >= pd.TimeSlotTotal {
        return errors.New("no time slot available")
    }
    pd.TimeSlotUsed++
    return nil
}
```

### 持仓过夜处理

```go
// 每日开盘前执行 (08:30)
func ProcessOvernightPositions() {
    // 获取昨日和今日风格
    yesterdayStyle := GetStyleByDate(yesterday)
    todayStyle := GetStyleByDate(today)
    
    // 如果风格突变，计算跳空
    if yesterdayStyle != todayStyle {
        gapPercent := CalculateGapByStyleChange(yesterdayStyle, todayStyle)
        
        // 更新所有持仓玩家的开盘价
        positions := db.GetAllActivePositions()
        for _, pos := range positions {
            // 应用跳空
            newOpenPrice := pos.LastPrice * (1 + gapPercent)
            
            // 计算 San 值冲击
            floatingPnL := (newOpenPrice - pos.AvgPrice) / pos.AvgPrice
            if floatingPnL < -0.1 {
                sanityDrop := CalculateSanityDrop(floatingPnL)
                UpdatePlayerSanity(pos.PlayerID, -sanityDrop)
            }
        }
    }
}
```

## 性能优化

### 风格生成优化

- 使用定时任务在凌晨 00:00 执行
- 失败时使用默认配置兜底
- 成功后缓存到 Redis
- 避免每次请求都调用 LLM

### 叙事渲染优化

- 预生成词典，客户端本地替换
- 仅关键剧情调用 LLM
- 相同输入缓存 10 分钟
- 每玩家每日限额 20 次

### 数据库优化

- world_day_style 表按日期分区
- 使用复合索引 (world_date, style_tag)
- 热数据保留 30 天
- 冷数据归档

## 监控指标

### 业务指标

- 每日风格生成成功率 > 99%
- LLM 调用平均延迟 < 2s
- 缓存命中率 > 95%
- 跨日玩家留存率

### 技术指标

- Redis 可用性 > 99.9%
- 定时任务执行成功率 > 99%
- API 响应时间 < 100ms
- 数据库查询时间 < 50ms

## 下一步

查看详细文档:
- [市场博弈机制](./04-market-mechanism.md)
- [AI 演进系统详细设计](./modules/ai-evolution.md)
- [IoT 系统详细设计](./modules/iot-system.md)
