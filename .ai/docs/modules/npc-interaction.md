# 角色互动与好感度系统详细设计

## 模块概述

本模块融合了《同级生》的时间管理与传统 Galgame 的好感度系统。

### 核心冲突

时间有限。玩家必须在"研究K线赚钱"和"陪校花防止她黑化"之间做零和博弈。

### 资源消耗

- **时间槽 (Time Slot)**: 每日 3 个
- **AERA (游戏币)**: 购买常规礼物
- **源点 (真金)**: 发动"心智覆写" (强制改命)

### 输出

好感度等级 (Lv 0-7)，直接决定结局分支和方舟船票的获取资格

## NPC 行为逻辑

校花不是站在原地等你的 NPC，她有自己的行动轨迹 (Schedule) 和精神状态 (Mental State)。

### 行动轨迹状态机 (Schedule FSM)

NPC 的位置随【时间段】和【今日风格】变化。

| 时间段 | 默认位置 | 修仙日 (Xianxia) | 赛博日 (Cyber) | 交互消耗 |
|-------|---------|----------------|--------------|---------|
| 早盘 | 教室 (不可交互，上课中) | 炼丹房 (需消耗源点潜入) | 义体诊所 (她在维护手臂) | N/A |
| 午休 | 天台 (吃便当，可偶遇) | 灵田 (种植药草) | 数据黑市 (她在倒卖信息) | 1 时间槽 |
| 晚盘 | 图书馆 (学习，可辅导) | 藏经阁 (研读功法) | 全息网吧 (兼职打工) | 1 时间槽 |
| 深夜 | 家 (不可交互，除非 Lv>5) | 洞府 | 胶囊公寓 | N/A |

### 精神状态 (Sanity Sync)

校花也有 San 值(虽然不可见)。

**逻辑**: 如果玩家连续 3 天没有交互(冷落)，或者 AERA 股价暴跌导致她家破产，她会进入【抑郁/黑化】状态

**后果**: 拒绝交流，好感度锁定，甚至触发 Bad End (柴刀结局)

## 互动玩法详解

### 常规互动 (Normal Interaction)

消耗 1 个时间槽 进行以下行为:

**1. 闲聊 (Chat)**:
- 内容: AI 根据今日风格生成对话
- 效果: 好感度微量上升 (+5)，玩家 San 值恢复 (+10)

**2. 送礼 (Gift)**:
- 消耗: AERA 资金
- 逻辑: 需根据她当前的需求送礼(如: 赛博日送"高级机油"，修仙日送"驻颜丹")
- 效果: 好感度大量上升 (+30)

**3. 约会 (Date)**:
- 条件: 好感度 Lv > 3
- 效果: 触发一段脚本化剧情 (Scripted Event)

### 高维干涉: 心智覆写 (Mind Overwrite)

这是玩家作为"高维观测者"的特权。当好感度卡住，或者她即将黑化时使用。

**消耗**: 500 ~ 1000 源点 (真金)

**表现**: 画面出现 glitch 故障效果，玩家直接修改她大脑中的"海马体数据"

**用途**:
- 强制解锁: 即使她现在讨厌你，也强行开启对话窗口
- 记忆植入: 直接将好感度从 Lv 2 拉升到 Lv 3(跳过中间的刷礼物环节)
- 危机解除: 当她要自杀/退学时，强行扭转她的念头

## 好感度阶段与 P-System

好感度等级直接对应主线剧情阶段 (P0-P7)。

| 等级 | 关系定义 | 解锁功能 (Gameplay Buff) | 升级条件 |
|-----|---------|----------------------|---------|
| Lv 0 | 陌生人 | 无 | 初始状态 |
| Lv 1 | 同学 | 可查看她的当前位置 (GPS) | 交互 3 次 |
| Lv 3 | 朋友 | 【内幕共享】: 每天午休她会发短信告诉你一条"小道消息" (准确率 60%) | 触发事件 Event_Library_Help |
| Lv 5 | 恋人 | 【资金援助】: 当你爆仓时，她会拿出私房钱帮你补保证金 (仅一次) | 触发事件 Event_Confession |
| Lv 6 | 共犯 | 【黑天鹅免疫】: 两人在一起时，San 值扣除减半 | 共同经历一次崩盘并存活 |
| Lv 7 | 觉醒者 | 【方舟船票】: 她意识到世界是假的，主动交出核心代码。通关必要条件 | 源点投入 > 5000 且 资产达标 |

## 实现示例

### NPC 行程查询服务

```go
type NPCService struct {
    repo          NPCRepository
    worldService  WorldEvolutionService
}

func (s *NPCService) GetHeroineSchedule(playerID uuid.UUID, worldDate string) ([]*ScheduleSlot, error) {
    // 1. 获取今日风格
    style, err := s.worldService.GetStyleByDate(worldDate)
    if err != nil {
        return nil, err
    }
    
    // 2. 获取玩家与 NPC 的关系状态
    state, err := s.repo.GetPlayerNPCState(playerID, "HEROINE")
    if err != nil {
        return nil, err
    }
    
    // 3. 查询配置表
    configs, err := s.repo.GetScheduleConfigs("HEROINE", style.StyleTagCode)
    if err != nil {
        return nil, err
    }
    
    // 4. 过滤需要的好感度等级
    var slots []*ScheduleSlot
    for _, cfg := range configs {
        if state.AffectionLevel >= cfg.ReqAffectionLevel {
            slots = append(slots, &ScheduleSlot{
                TimeSlot:   cfg.TimeSlotCode,
                Location:   cfg.LocationCode,
                DialogPool: cfg.DialogPoolID,
            })
        }
    }
    
    return slots, nil
}
```

### 互动处理服务

```go
type InteractionService struct {
    npcRepo       NPCRepository
    walletService WalletService
    sanityService SanityService
    worldService  WorldEvolutionService
}

func (s *InteractionService) InteractWithHeroine(ctx context.Context, req *InteractionRequest) (*InteractionResult, error) {
    // 1. 幂等性检查
    existing, _ := s.npcRepo.GetInteractionByIdempotency(req.PlayerID, req.IdempotencyKey)
    if existing != nil {
        return BuildResultFromInteraction(existing), nil
    }
    
    // 2. 时间槽检查
    playerDay, err := s.tripxService.GetPlayerDay(req.PlayerID, req.WorldDate)
    if err != nil {
        return nil, err
    }
    if playerDay.TimeSlotUsed >= playerDay.TimeSlotTotal {
        return nil, ErrNoTimeSlot
    }
    
    // 3. 获取 NPC 状态
    npcState, err := s.npcRepo.GetPlayerNPCState(req.PlayerID, "HEROINE")
    if err != nil {
        return nil, err
    }
    
    // 4. 获取今日风格
    style, err := s.worldService.GetTodayStyle()
    if err != nil {
        return nil, err
    }
    
    var affectionDelta int
    var sanityDelta float64
    var costAmount decimal.Decimal
    
    switch req.Type {
    case "CHAT":
        // 闲聊: 少量好感度，恢复 San 值
        affectionDelta = 5
        sanityDelta = 10
        
    case "GIFT":
        // 送礼: 需要检查礼物和风格匹配
        gift, _ := s.repo.GetGiftItem(req.GiftID)
        reaction, _ := s.repo.GetGiftReaction("HEROINE", req.GiftID, style.StyleTagCode)
        
        affectionDelta = reaction.AffectionAdd
        sanityDelta = reaction.SanityRecover.InexactFloat64()
        costAmount = gift.CostAmount
        
        // 扣除礼物费用
        err = s.walletService.DeductBalance(req.PlayerID, gift.CostAssetID, costAmount, "NPC_GIFT")
        if err != nil {
            return nil, err
        }
        
    case "MIND_OVERWRITE":
        // 心智覆写: 消耗大量源点
        costAmount = decimal.NewFromInt(1000)
        err = s.walletService.DeductBalance(req.PlayerID, "SOURCE", costAmount, "MIND_OVERWRITE")
        if err != nil {
            return nil, err
        }
        
        // 强制提升好感度
        affectionDelta = 50
        sanityDelta = -20 // 使用高维力量会消耗玩家 San 值
    }
    
    // 5. 更新 NPC 状态
    npcState.AffectionPoints += affectionDelta
    npcState.LastInteractionAt = time.Now()
    
    // 检查是否升级
    if s.shouldLevelUp(npcState) {
        npcState.AffectionLevel++
    }
    
    err = s.npcRepo.UpdateNPCState(npcState)
    if err != nil {
        return nil, err
    }
    
    // 6. 更新玩家 San 值
    if sanityDelta != 0 {
        s.sanityService.AddSanity(req.PlayerID, sanityDelta)
    }
    
    // 7. 消耗时间槽
    playerDay.TimeSlotUsed++
    s.tripxService.UpdatePlayerDay(playerDay)
    
    // 8. 记录互动流水
    interaction := &PlayerNPCInteraction{
        PlayerID:       req.PlayerID,
        NPCID:          "HEROINE",
        InteractionType: req.Type,
        TimeSlotCode:   req.TimeSlot,
        WorldDate:      req.WorldDate,
        StyleTagCode:   style.StyleTagCode,
        AffectionDelta: affectionDelta,
        SanityDelta:    decimal.NewFromFloat(sanityDelta),
        CostAmount:     costAmount,
    }
    s.npcRepo.SaveInteraction(interaction)
    
    // 9. 生成对话/剧情
    story := s.generateStory(npcState, req.Type, style)
    
    return &InteractionResult{
        HeroineState: npcState,
        AffectionDelta: affectionDelta,
        SanityDelta: sanityDelta,
        Story: story,
    }, nil
}
```

## 配表需求

### Cfg_Heroine_Schedule.xlsx

| ID | Time_Slot | Style_Tag | Location_ID | Dialog_Pool_ID | Req_Level |
|----|-----------|-----------|-------------|----------------|-----------|
| 101 | Noon | Default | Loc_Rooftop | Pool_School_Daily | 0 |
| 102 | Noon | Cyber | Loc_BlackMarket | Pool_Cyber_Trade | 3 |

### Cfg_Gift_Reaction.xlsx

| Gift_ID | Style_Tag | Affection_Add | Sanity_Recover | Response_Text_Key |
|---------|-----------|---------------|----------------|-------------------|
| G01 (鲜花) | Default | +10 | +5 | "谢谢，很香呢。" |
| G01 (鲜花) | Cyber | -5 | 0 | "这是...真的植物? 在霓虹城这可是违禁品! 快扔掉!" |
| G02 (显卡) | Cyber | +50 | +20 | "RTX 9090! 你从哪搞到的? 这下我的算力够用了!" |

### Cfg_Heroine_Economy.xlsx

| 好感度等级 | 升级所需经验 | 推荐礼物价格 (AERA) | 说明 |
|----------|------------|-------------------|------|
| Lv 0 -> 1 | 100 | 0 | 只需要聊天即可 |
| Lv 1 -> 2 | 500 | 200 | 送点小零食、奶茶 |
| Lv 3 -> 4 | 2000 | 1000 | 送轻奢品(项链、限定手办) |
| Lv 6 -> 7 | 10000 | 5000 | 送车/帮还债。需要你在股市里赚大钱 |

## UI/UX 详细设计

### 手机终端界面 (The Phone UI)

玩家在游戏里通过一个虚拟手机与她联系。

**类似微信/Line 的界面**:
- 左侧: 联系人列表(校花、黑客、交易所客服)
- 右侧: 对话框。支持发送表情包、红包(转账 AERA)

**朋友圈 (Moments)**:
- 她会根据今日风格发朋友圈
- 修仙日: "今天炼丹炸炉了，心情不好。" → 玩家点赞/评论可加好感

### 约会结算界面

**视觉**: 采用 AVG 对话框 模式

**QTE**: 在对话关键点，出现"眼神接触"或"肢体接触"的 QTE 选项
- 选项 A: 摸头杀 (需 Lv > 3，否则被扇巴掌，San 值 -20)
- 选项 B: 倾听 (安全选项，好感 +5)
- 选项 C (源点): 心智覆写 (直接跳过对话，达成完美结果)

## 监控与优化

### 关键指标

- 平均好感度等级: Lv 3-4
- 互动频率: 每日 1-2 次
- 心智覆写使用率: < 20%
- 黑化触发率: < 10%

### 性能优化

- 缓存 NPC 状态
- 预加载对话资源
- 异步生成剧情
- 数据库索引优化

## 下一步

查看相关文档:
- [市场博弈机制](../04-market-mechanism.md)
- [San 值系统](./sanity-system.md)
- [AI 演进系统](./ai-evolution.md)
