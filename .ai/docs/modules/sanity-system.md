# San 值系统详细设计

## 模块概述

San 值 (Sanity) 是玩家在里世界 (TripX) 的"心理保证金"。

### 定义

它是限制玩家杠杆率和持仓时间的核心资源

### 核心循环

```
亏损/黑天鹅 → San 值下降 → 产生幻觉/操作变形 → 更加亏损 → 心态崩盘 (Game Over)
```

### 数值范围

0.0 ~ 100.0 (浮点数)

## San 值演算逻辑

San 值的变化是实时计算的，分为被动压力 (Passive) 和主动恢复 (Active)。

### 被动压力公式

当玩家持仓出现浮亏 (Floating Loss) 时，San 值会随时间流逝而扣除。亏得越多，掉得越快(指数级)。

```
San_drop = Δt × K_style × (Loss × 10)²
```

**参数说明**:
- Δt: 时间增量(秒)
- K_style: 今日风格压力系数(由 Daily_Config 决定)
  - 修仙日: 0.8 (心态平和，掉得慢)
  - 末日日: 1.5 (环境压抑，掉得快)
- 浮亏百分比: (现价 - 均价) / 均价
  - 例: 亏损 10% (0.1)，平方后为 0.01
  - 例: 亏损 30% (0.3)，平方后为 0.09。压力是亏 10% 时的 9 倍!

### 事件冲击 (Event Shock)

某些瞬间事件会直接扣除固定数值的 San 值。

| 事件类型 | San 值扣除 | 说明 |
|---------|-----------|------|
| 黑天鹅爆发 | -20 | 瞬间市场崩盘 |
| 女主拒绝/冷战 | -30 | 情感挫败 |
| 踏空 (卖飞了) | -10 | 懊悔值 |
| 爆仓 | -50 | 强制平仓触发 |

### 恢复途径 (Recovery)

San 值不会自动恢复(除非空仓)。必须通过行动恢复:

1. **现实睡眠 (IoT)**: 昨晚深睡 2 小时 → 今日进游戏 San 值上限 +20
2. **空仓休息 (Rest)**: 不持有任何股票时，每分钟恢复 5 点
3. **药物/消费 (Items)**: 消耗源点购买"镇静剂"或"去酒吧喝酒"

## 精神状态阶段

根据 San 值剩余量，客户端会进入不同状态，影响 UI 和操作。

### 状态定义表

| 状态 (State) | San 值区间 | UI 表现 | 操作惩罚 |
|-------------|-----------|---------|---------|
| 理智 (Lucid) | 80 ~ 100 | 清晰、锐利 | 无。操作响应速度 100% |
| 焦虑 (Anxious) | 40 ~ 79 | 边缘轻微暗角，BGM 混入低频噪音 | 情报模糊: 购买的"内幕消息"有 20% 几率出现乱码 |
| 恐慌 (Panic) | 10 ~ 39 | 屏幕剧烈呼吸动效，K 线出现重影 (Ghosting) | 操作变形: 1. 买/卖按钮位置每 5 秒随机互换 2. 下单时长按确认时间从 1s 延长至 3s (手抖) |
| 崩盘 (Breakdown) | 0 ~ 9 | 全屏血红，耳鸣声盖过一切 | AI 接管 (强制平仓): 触发 Force_Liquidation 流程 |

## 强制机制: 心态崩盘

当 San 值归零，玩家角色失去理智。

### 触发流程

1. **输入锁定**: 玩家无法进行任何操作，UI 按钮全部禁用
2. **自动演出**:
   - 屏幕中央弹出巨大的红色文字: "MENTAL BREAKDOWN"
   - 角色独白(自动播放): "受不了了... 让它停下来... 全都卖掉!"
3. **强制平仓**: 系统以市价 (Market Price) 卖出账户内所有 AERA 股票
   - 注: 市价卖出通常会吃到巨大的滑点，导致资产大幅缩水
4. **强制跳转**:
   - 当前时间槽直接结束
   - 场景强制切换至 【酒吧 (The Bar)】 或 【医院】
   - 扣除 500 源点(医药费/酒水费)
   - 如果源点不足，则背负债务(负债状态)

## 实现示例

### 服务端 San 值更新

```go
type SanityService struct {
    repo          SanityRepository
    positionRepo  PositionRepository
    marketService MarketService
}

func (s *SanityService) UpdateSanityByPosition(playerID uuid.UUID) error {
    // 1. 获取玩家当前 San 值
    sanity, err := s.repo.GetPlayerSanity(playerID)
    if err != nil {
        return err
    }
    
    // 2. 获取持仓
    positions, err := s.positionRepo.GetPlayerPositions(playerID)
    if err != nil {
        return err
    }
    
    // 如果空仓，San 值恢复
    if len(positions) == 0 {
        sanity.Value = math.Min(sanity.Value+5, sanity.MaxValue)
        return s.repo.UpdateSanity(sanity)
    }
    
    // 3. 计算总浮亏
    var totalFloatingPnL decimal.Decimal
    var totalCost decimal.Decimal
    
    for _, pos := range positions {
        if pos.Qty.IsZero() {
            continue
        }
        
        // 获取当前市价
        currentPrice := s.marketService.GetCurrentPrice(pos.Symbol)
        
        // 计算浮动盈亏
        cost := pos.AvgPrice.Mul(pos.Qty)
        market := currentPrice.Mul(pos.Qty)
        floatingPnL := market.Sub(cost)
        
        totalFloatingPnL = totalFloatingPnL.Add(floatingPnL)
        totalCost = totalCost.Add(cost)
    }
    
    // 4. 计算浮亏百分比
    if totalCost.IsZero() {
        return nil
    }
    
    pnlPercent := totalFloatingPnL.Div(totalCost).InexactFloat64()
    
    // 5. 只在亏损时扣 San 值
    if pnlPercent < 0 {
        // 获取今日风格压力系数
        style, _ := s.worldService.GetTodayStyle()
        kStyle := style.SanityPressureCoef // 默认 1.0
        
        // 计算 San 值降低量
        // San_drop = Δt × K_style × (Loss × 10)²
        deltaT := 1.0 // 假设每秒调用一次
        loss := math.Abs(pnlPercent)
        drop := deltaT * kStyle * math.Pow(loss*10, 2)
        
        sanity.Value = math.Max(0, sanity.Value-drop)
        
        // 更新状态
        sanity.StateCode = s.determineState(sanity.Value)
        sanity.LastCalcTS = time.Now().Unix()
        
        // 检查是否触发崩盘
        if sanity.Value <= 0 {
            return s.TriggerBreakdown(playerID)
        }
    }
    
    return s.repo.UpdateSanity(sanity)
}

func (s *SanityService) TriggerBreakdown(playerID uuid.UUID) error {
    // 1. 记录崩盘事件
    event := &SanityEvent{
        ID:         uuid.New(),
        PlayerID:   playerID,
        EventType:  "BREAKDOWN",
        DeltaValue: -999,
        CreatedAt:  time.Now(),
    }
    s.repo.SaveEvent(event)
    
    // 2. 强制平仓所有持仓
    positions, _ := s.positionRepo.GetPlayerPositions(playerID)
    for _, pos := range positions {
        if pos.Qty.IsZero() {
            continue
        }
        
        // 以市价强制卖出
        order := &Order{
            PlayerID: playerID,
            Symbol:   pos.Symbol,
            Side:     "SELL",
            Type:     "MARKET",
            Qty:      pos.Qty,
            Reason:   "FORCED_LIQUIDATION",
        }
        s.orderService.PlaceOrder(order)
    }
    
    // 3. 扣除惩罚费用
    s.walletService.DeductBalance(playerID, "SOURCE", 500, "BREAKDOWN_PENALTY")
    
    // 4. 重置 San 值到最小值
    sanity, _ := s.repo.GetPlayerSanity(playerID)
    sanity.Value = 10 // 留一点，不完全归零
    sanity.StateCode = "ANXIOUS"
    s.repo.UpdateSanity(sanity)
    
    return nil
}
```

### 客户端 San 值实时计算

```csharp
// Unity C# 实现
public class SanityManager : MonoBehaviour {
    public float CurrentSanity = 100f;
    public float MaxSanity = 100f;
    public SanityState CurrentState = SanityState.Lucid;
    
    private float myAvgCost;
    private float myPositionQty;
    
    void Update() {
        // 1. 接收服务端推送的最新价格
        float currentPrice = WebSocketService.GetLatestPrice();
        
        if (myPositionQty == 0) {
            // 空仓时恢复
            CurrentSanity = Mathf.Min(CurrentSanity + Time.deltaTime * 5f, MaxSanity);
            return;
        }
        
        // 2. 计算浮动盈亏百分比
        float pnlPercent = (currentPrice - myAvgCost) / myAvgCost;
        
        // 3. 只在亏损时扣 San 值
        if (pnlPercent < -0.01f) {
            // 获取压力系数
            float kStyle = WorldManager.Instance.GetTodayPressureCoef();
            
            // 计算扣除量
            float loss = Mathf.Abs(pnlPercent);
            float drop = Time.deltaTime * kStyle * Mathf.Pow(loss * 10, 2);
            
            CurrentSanity = Mathf.Max(0, CurrentSanity - drop);
            
            // 触发 UI 效果
            UpdateVisualEffects(pnlPercent);
        }
        
        // 4. 更新状态
        UpdateState();
        
        // 5. 检查崩盘
        if (CurrentSanity <= 0) {
            TriggerBreakdown();
        }
    }
    
    void UpdateVisualEffects(float pnlPercent) {
        float panicFactor = Mathf.Pow(Mathf.Abs(pnlPercent) * 10, 2);
        
        // 视觉效果
        PostProcessManager.SetVignette(panicFactor);
        PostProcessManager.SetChromaticAberration(panicFactor * 0.5f);
        
        // 听觉效果
        AudioManager.SetNoiseVolume(panicFactor * 0.3f);
        AudioManager.SetHeartbeatIntensity(panicFactor);
        
        // 触觉效果 (手机震动)
        if (panicFactor > 0.5f) {
            Handheld.Vibrate();
        }
    }
    
    void UpdateState() {
        if (CurrentSanity >= 80) {
            CurrentState = SanityState.Lucid;
        } else if (CurrentSanity >= 40) {
            CurrentState = SanityState.Anxious;
        } else if (CurrentSanity >= 10) {
            CurrentState = SanityState.Panic;
            
            // 恐慌状态: 按钮位置随机互换
            if (Time.frameCount % 300 == 0) { // 每 5 秒
                UIManager.SwapButtonPositions();
            }
        } else {
            CurrentState = SanityState.Breakdown;
        }
    }
    
    void TriggerBreakdown() {
        // 1. 锁定输入
        InputManager.LockInput();
        
        // 2. 播放崩盘动画
        UIManager.ShowBreakdownScreen();
        
        // 3. 请求服务端强制平仓
        ApiClient.Post("/v1/sanity/breakdown", new {});
        
        // 4. 延迟后跳转场景
        StartCoroutine(JumpToBarAfterDelay(3f));
    }
}
```

## 配表需求

### Cfg_Sanity_State.xlsx

| State_ID | Name | Min_Value | Max_Value | UI_Effect_Prefab | Input_Delay | Button_Swap_Prob |
|----------|------|-----------|-----------|------------------|-------------|------------------|
| 1 | Lucid | 80 | 100 | None | 0.0s | 0.0 |
| 2 | Anxious | 40 | 79 | VFX_Vignette_Light | 0.2s | 0.0 |
| 3 | Panic | 10 | 39 | VFX_Heartbeat_Heavy | 0.5s | 0.3 |
| 4 | Breakdown | 0 | 9 | VFX_Blood_Screen | 99s | 1.0 |

### Cfg_Sanity_Item.xlsx

| ID | Name | Cost_Source | Recover_Val | Side_Effect | Desc |
|----|------|-------------|-------------|-------------|------|
| 101 | 电子烟 | 50 | +10 | Health -1 | 稍微缓解焦虑 |
| 102 | 镇静剂 | 200 | +30 | Reaction -20% | 强行压制恐慌 |
| 103 | 威士忌 | 500 | +50 | Skip_TimeSlot | 喝醉睡个好觉 |

## UI/UX 详细设计

### San 值进度条

**位置**: 屏幕底部或侧边，不是血条，更像是一个心电图

**动态**:
- San 值高时: 心电图平稳，绿色
- San 值低时: 心电图剧烈波动，红色，频率随心率加快

### 幻觉系统 (Hallucinations)

这是本作的特色。当处于【恐慌】状态时，K 线图会出现欺骗性视觉元素。

**假信号**: 图表上会随机出现并不存在的"暴跌大阴线"，持续 0.5 秒后消失。吓唬玩家割肉

**怪物投影**: K 线的走势形状隐约组成一只克苏鲁怪物的轮廓(程序生成 Mesh)

### 听觉反馈 (Audio)

使用 FMOD 或 Wwise 实现动态混音。

- **Layer 1 (BGM)**: 正常的赛博/修仙背景乐
- **Layer 2 (Noise)**: 随着 San 值降低，音量逐渐推大。包含电流声、耳鸣声
- **Layer 3 (Heartbeat)**: 与玩家手表的真实心率同步(如果有)，或者模拟高心率

## 监控与优化

### 关键指标

- San 值计算准确率: 100%
- 崩盘触发成功率: 100%
- 强制平仓执行延迟: < 1s
- 玩家平均 San 值: 60-70

### 性能优化

- 客户端本地计算 San 值
- 服务端定期校验
- 避免每帧都网络通信
- 使用插值平滑 UI 表现

## 下一步

查看相关文档:
- [市场博弈机制](../04-market-mechanism.md)
- [市场系统](./market-system.md)
- [NPC 互动系统](./npc-interaction.md)
