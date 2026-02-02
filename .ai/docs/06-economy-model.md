# 数值体系与经济模型配表

## 经济循环总览

我们采用双轨制经济:

1. **源点 (Source)**: 刚性货币(本金)。产出受限(体力)，消耗无限(欲望)
2. **AERA (Credits)**: 股票资产。随市场波动，用于购买重要剧情道具(如船票)

### 经济流向图

```
Input Layer (Reality)
    步数 → 转化率 → 源点(本金)
    睡眠 → 转化率 → 源点

    ↓

Trading Layer (TripX)
    源点 → 买入 → AERA 持仓
    AERA 持仓 → 卖出 → 源点
    AERA 持仓 → 波动 → 浮盈/浮亏

    ↓

Sink Layer (Consumption)
    源点 → 购买 → 内幕消息(技能)
    源点 → 购买 → 精神药剂
    AERA → 变现购买 → 女主礼物
```

## 基础资源产出配表

**核心原则**: 即使是重度运动玩家，每天产出的源点也只能支持 2~3 次高级技能的使用。逼迫玩家在"梭哈"和"买保险"之间做决策。

### Cfg_IoT_Reward (IoT 奖励配置)

| 参数名 | 推荐数值 | 说明 |
|-------|---------|------|
| Steps_Rate | 0.1 | 每 10 步 = 1 源点。跑 5000 步 = 500 源点 |
| Steps_Daily_Cap | 2000 | 每日步数奖励上限(约 20,000 步)。防止摇步器刷爆服务器 |
| Sleep_Rate | 100 | 每小时有效睡眠 = 100 源点 |
| Sleep_Bonus_Deep | 1.5x | 深睡时段奖励系数 |
| Initial_Deposit | 1000 | 新手创号赠送本金(让玩家直接能玩，不用先去跑一圈) |

## 金融市场参数

这是 Go 后端算法的参数配置。

### Cfg_Market_Math (市场数学配置)

#### 基础波动率 (σ)

| 风格 (Style) | Base_Volatility (σ) | 解释 |
|------------|-------------------|------|
| 修仙 (Xianxia) | 0.02 (2%) | 市场平稳，适合新手和养生玩家 |
| 赛博 (Cyber) | 0.05 (5%) | 波动适中，有操作空间 |
| 末日 (Doom) | 0.15 (15%) | 极度危险。几分钟内可能翻倍或腰斩 |

#### 操盘手参数 (δ 因子)

| 参数名 | 数值 | 说明 |
|-------|------|------|
| Growth_Rate (μ) | 0.0012 | 每日自然增长 0.12%。保证长期持有者(HODL)能赚点钱 |
| Burst_Attraction | 0.005 | 爆仓引力系数。数值越大，K 线越喜欢往你的爆仓线上撞 |
| Anti_Luck_Threshold | 3 | 连胜 3 次后，触发针对性打压 |
| BlackSwan_Drop | -0.4 | 黑天鹅事件触发时，目标跌幅为 40% |

## 消费定价配表

**定价策略**:
- 低级技能 (100源点): 随便用，类似"买份报纸"
- 中级技能 (500源点): 需要跑 5 公里才能换一个，使用时会肉疼
- 终极技能 (3000源点): 需要攒好几天，只有在"生死存亡"时才舍得用

### Cfg_Shop_Price (商店价格配置)

| 商品 ID | 商品类型 | 商品名 | 价格 (源点) | 说明 |
|--------|---------|--------|------------|------|
| 101 | 技能 | 盘前内参 | 100 | 消耗现金流，换取信息优势 |
| 102 | 技能 | 紧急熔断 | 3000 | 极昂贵。要么你现实里狂跑，要么你股市里大赚后套现 |
| 103 | 礼物 | 奶茶 | 50 | 便宜。跑步 500 步就能换 |
| 201 | 礼物 | 限定手办 | 2000 | 昂贵。相当于 2 天的运动量，或者一次成功的波段操作利润 |
| 202 | 剧情 | 心智覆写 | 5000 | 巨额消耗。必须在股市里赚到大钱并及时套现才能发动 |

### Cfg_Stock_Asset (资产定义)

| 资产名 | 类型 | 功能 |
|-------|------|------|
| AERA | 权益 (Equity) | 不能交易物品。只能买入/持有/卖出。它是通关的"积分牌" |
| 源点 | 货币 (Currency) | 唯一通货。现实产出，股市增值，商店消耗 |

## San 值惩罚公式系数

```
San_drop = Δt × K_style × (浮亏 × 10)²
```

我们通过调整 K_style 来控制不同日子的压抑程度。

### Cfg_Sanity_Calc (San 值计算配置)

| 风格 | K_Style 系数 | 浮亏 10% 时的每秒扣除量 | 60秒后累计扣除 |
|-----|------------|---------------------|--------------|
| 修仙 | 0.5 | 0.5 点/秒 | -30 点(还能忍) |
| 赛博 | 1.0 | 1.0 点/秒 | -60 点(开始手抖) |
| 末日 | 2.0 | 2.0 点/秒 | -120 点(直接崩盘) |

**设计意图**: 在"末日"风格下，如果你敢满仓扛单(浮亏 10%)，只要 1 分钟不操作，你就会直接心态崩盘(Game Over)。逼迫玩家在末日风格下必须"快进快出"或"空仓观望"。

## 好感度与礼物经济

女主是 AERA 资金的主要消耗口(回收站)。

### Cfg_Heroine_Economy (女主经济配置)

| 好感度等级 | 升级所需经验 | 推荐礼物价格 (AERA) | 说明 |
|----------|------------|-------------------|------|
| Lv 0 -> 1 | 100 | 0 | 只需要聊天即可 |
| Lv 1 -> 2 | 500 | 200 | 送点小零食、奶茶 |
| Lv 3 -> 4 | 2000 | 1000 | 送轻奢品(项链、限定手办) |
| Lv 6 -> 7 | 10000 | 5000 | 送车/帮还债。需要你在股市里赚大钱 |

## 配表结构详解

### 1. Cfg_Style_Corpus.xlsx (语料库表)

定义 AI 每天读什么。

| ID | Style_Tag | Text_Content (TextChunk) | Weight (抽取权重) |
|----|-----------|------------------------|-----------------|
| 1 | Xianxia | "韩立眉头一皱，退至众人身后..." | 10 |
| 2 | Cyber | "霓虹灯在积水中倒映出破碎的代码..." | 10 |
| 3 | Cthulhu | "那不可名状的几何体在疯狂旋转..." | 5 (稀有) |

### 2. Cfg_Prompt_Template.xlsx (提示词表)

定义系统 Prompt，方便策划热更新调整 AI 人格。

| ID | Function_Type | System_Prompt_Text | Max_Tokens | Temperature |
|----|--------------|-------------------|------------|-------------|
| 1 | Daily_Gen | "你是一个沉浸式游戏的..." | 500 | 0.7 |
| 2 | Intel_News | "你是一个跨维度的金融终端..." | 100 | 1.2 (高创造性) |

### 3. Cfg_IoT_Mapping.xlsx (行为映射表)

这张表决定了不同风格下，UI 显示什么文案。

| ID | Style_Tag | Action_Type | Name_Key | Desc_Key | Icon_Path |
|----|-----------|-------------|----------|----------|-----------|
| 101 | Xianxia | Steps | 缩地成寸 | 积攒脚力，转化灵气 | Img/Icon/Sword_Fly |
| 102 | Xianxia | Sleep | 闭关打坐 | 稳固元神，恢复道心 | Img/Icon/Sit_Down |
| 201 | Cyber | Steps | 数据运送 | 躲避防火墙扫描 | Img/Icon/Cyber_Run |
| 202 | Cyber | Sleep | 系统维护 | 挂机清理缓存 | Img/Icon/Cyber_Sleep |

### 4. Cfg_Stock_Market.xlsx (市场参数表)

定义不同风格下的市场基础参数。

| Style_ID | Base_Volatility | Volume_Multiplier | Slippage_Rate | Desc |
|----------|----------------|------------------|---------------|------|
| Xianxia | 0.02 (平稳) | 1.0 | 0.05% | 修仙日: 古波不惊，适合养生 |
| Cyber | 0.05 (剧烈) | 2.5 (高频) | 0.2% | 赛博日: 量化收割，上下插针 |
| Doom | 0.08 (极度) | 0.1 (枯竭) | 5.0% | 末日日: 流动性归零，买卖极难 |

### 5. Cfg_Intel_Shop.xlsx (情报/技能表)

定义源点可以购买的"外挂"。

| ID | Name_Key | Cost_Source | Effect_Type | Effect_Params | CD_GameTime | Icon |
|----|----------|-------------|-------------|---------------|-------------|------|
| 1 | 盘前内参 | 100 | SHOW_RANGE | Range=0.8 (显示80%置信区间) | 1 Day | Icon_Paper |
| 2 | 资金透视 | 500 | SHOW_WHALE | Depth=3 (显示3档主力单) | 60 Min | Icon_Eye |
| 3 | 紧急熔断 | 1000 | FREEZE_MARKET | Duration=30s (停牌30秒) | 1 Day | Icon_Stop |

### 6. Cfg_Market_Event.xlsx (黑天鹅事件表)

定义突发利空/利好。

| ID | Style_Tag | Type | Probability | Impact_Delta (跌幅) | Duration (秒) | News_Template_Key |
|----|-----------|------|-------------|-------------------|--------------|------------------|
| 901 | Cyber | CRASH | 0.05 | -0.3 (跌30%) | 60 | NEWS_CYBER_HACK |
| 902 | Xianxia | BOOM | 0.02 | +0.5 (涨50%) | 120 | NEWS_XIANXIA_ASCEND |

### 7. Cfg_Sanity_State.xlsx (状态阈值表)

定义不同阶段的阈值和效果。

| State_ID | Name | Min_Value | Max_Value | UI_Effect_Prefab | Input_Delay | Button_Swap_Prob |
|----------|------|-----------|-----------|------------------|-------------|------------------|
| 1 | Lucid | 80 | 100 | None | 0.0s | 0.0 |
| 2 | Anxious | 40 | 79 | VFX_Vignette_Light | 0.2s | 0.0 |
| 3 | Panic | 10 | 39 | VFX_Heartbeat_Heavy | 0.5s | 0.3 (30%) |
| 4 | Breakdown | 0 | 9 | VFX_Blood_Screen | 99s | 1.0 |

### 8. Cfg_Sanity_Item.xlsx (恢复道具表)

定义在 TripX 里能买到的"精神药剂"。

| ID | Name | Cost_Source | Recover_Val | Side_Effect | Desc |
|----|------|-------------|-------------|-------------|------|
| 101 | 电子烟 | 50 | +10 | Health -1 | 稍微缓解焦虑，但在赛博世界也要注意肺 |
| 102 | 镇静剂 | 200 | +30 | Reaction -20% | 强行压制恐慌，但接下来的操作会变迟钝 |
| 103 | 昂贵的威士忌 | 500 | +50 | Skip_TimeSlot | 喝醉了就能睡个好觉。消耗 1 个时间槽 |

### 9. Cfg_Heroine_Schedule.xlsx (行程表)

定义她在哪里。

| ID | Time_Slot | Style_Tag | Location_ID | Dialog_Pool_ID | Req_Level |
|----|-----------|-----------|-------------|----------------|-----------|
| 101 | Noon | Default | Loc_Rooftop | Pool_School_Daily | 0 |
| 102 | Noon | Cyber | Loc_BlackMarket | Pool_Cyber_Trade | 3 |

### 10. Cfg_Gift_Reaction.xlsx (礼物反应表)

定义她喜欢什么。

| Gift_ID | Style_Tag | Affection_Add | Sanity_Recover | Response_Text_Key |
|---------|-----------|---------------|----------------|-------------------|
| G01 (鲜花) | Default | +10 | +5 | "谢谢，很香呢。" |
| G01 (鲜花) | Cyber | -5 | 0 | "这是...真的植物? 在霓虹城这可是违禁品! 快扔掉!" |
| G02 (显卡) | Cyber | +50 | +20 | "RTX 9090! 你从哪搞到的? 这下我的算力够用了!" |

## 数值平衡验证

### 日均源点流动

**产出**:
- 步数: 10000 步 × 0.1 = 1000 源点
- 睡眠: 7 小时 × 100 = 700 源点
- 总计: 1700 源点/天

**消耗**:
- 低级情报: 100 × 3 次 = 300 源点
- 中级情报: 500 × 1 次 = 500 源点
- 礼物: 200 × 1 次 = 200 源点
- 总计: 1000 源点/天

**留存**: 700 源点/天

### 经济健康度指标

- 日均产出: 1500-2000 源点
- 日均消耗: 1000-1500 源点
- 留存率: 60-70%
- 通胀率: 按 P0-P7 阶段递减汇率

### 平衡调整建议

如果发现:
- 玩家源点积累过多 → 降低产出率或提高消费价格
- 玩家源点不够用 → 增加产出率或降低消费价格
- 玩家不愿意花钱 → 增强技能效果或降低价格
- 玩家太容易通关 → 提高船票获取难度

## 配表热更新机制

### 实现方式

1. 配表存储在数据库
2. 服务端定期从数据库读取(每 5 分钟)
3. 策划通过管理后台修改配表
4. 无需重启服务器即可生效

### 热更新流程

```go
type ConfigService struct {
    cache      *ConfigCache
    db         *gorm.DB
    updateTick *time.Ticker
}

func (s *ConfigService) Start() {
    // 初次加载
    s.reloadAllConfigs()
    
    // 定期更新
    s.updateTick = time.NewTicker(5 * time.Minute)
    
    go func() {
        for range s.updateTick.C {
            s.reloadAllConfigs()
        }
    }()
}

func (s *ConfigService) reloadAllConfigs() {
    // 从数据库加载最新配置
    configs := s.db.LoadAllConfigs()
    
    // 原子更新缓存
    s.cache.Update(configs)
    
    log.Info("configs reloaded successfully")
}
```

## 下一步

查看详细文档:
- [市场系统详细设计](./modules/market-system.md)
- [San 值系统详细设计](./modules/sanity-system.md)
- [NPC 互动系统详细设计](./modules/npc-interaction.md)
