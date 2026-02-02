# 技术实现与 Prompt 架构

## 系统架构

后端语言为 Golang，利用其高并发特性处理实时的 K 线演化与行情推送。

### 技术栈选型

#### 客户端: Unity 2022+ (C#)

- 网络层: WebSocket (用于接收实时 K 线)
- UI: DoozyUI + XCharts (绘制 K 线)

#### 服务端: Golang (Gin框架)

- 核心优势: Goroutine 协程极低成本处理每个玩家的"独立宇宙"行情(如果设计为每个人行情不同)，或处理全局的高频广播
- 通信: Gorilla WebSocket
- 数据库: PostgreSQL (GORM) + Redis (缓存实时价格)

#### AI 中台

Python (独立微服务) 或直接通过 Go 调用 LLM API (OpenAI/Anthropic)

### 数据流向图

```
Unity 客户端
    ↕ WebSocket 长连接
Golang 核心服务
    ├─ 1. 计算基础波动 → 价格演化算法
    ├─ 2. 计算玩家行为 → 玩家持仓/连胜状态
    └─ 3. 合成最终价格 Pt → 行情广播

AI Service
    └─ 每日 0 点定时 → LLM API → JSON → Redis
```

## 核心算法逻辑

这是整个里世界的"心脏"。我们在 Go 服务端实现价格演化模型。

### 价格演化公式 (Golang 实现逻辑)

后端会启动一个 Ticker(例如每 1 秒 tick 一次)，计算下一秒的价格 Pt。

```
Pₜ = Pₜ₋₁ × max(0.01, (1 + μ + ηₜ + δₜ))
```

#### 参数详解与实现

**μ (长期增长)**:
- 固定值 0.0012
- 保证大趋势向上，给非 RMB 玩家留活路

**ηₜ (市场噪音)**:

```go
// Go 伪代码: 模拟 OU 过程噪声
func GetNoise(sigma float64) float64 {
    theta := 1.0
    if rand.Float64() < 0.5 {
        theta = -1.0
    }
    return theta * sigma * rand.NormFloat64() // 标准正态分布
}
```

**δₜ (条件扰动 - 游戏性的核心)**:

这是最吃性能的部分，Go 协程优势在此体现。

A. 爆仓吸引 (δ_burst):
- 遍历玩家所有持仓单
- 若 (当前价 - 爆仓价) 极小，增加一个指向爆仓价的引力权重
- 体验: K 线像被磁铁吸住一样，在爆仓线边缘疯狂试探，San 值狂掉

B. 连胜惩罚 (δ_antiLuck):
- 读取 Redis 中的 User_Win_Streak
- 如果连胜 > 3 次，且仓位重，生成一个负向因子
- 体验: "怎么我一梭哈它就跌?"(系统故意的)

C. 黑天鹅 (δ_blackSwan):
- 由主神风格配置 (Daily Config) 决定触发概率
- 一旦触发，X 值设为 0.4 (暴跌40%)，持续 N 个 tick

### San 值计算 (客户端 C#)

服务端负责推价格，客户端负责根据价格计算 San 值(UI 表现)，并定期上报校验。

```csharp
// Unity C# 伪代码
void Update() {
    // 1. 接收服务端推来的 Pt
    float currentPrice = WebSocketService.GetLatestPrice();
    
    // 2. 计算浮动盈亏 (Floating PnL)
    float pnlPercent = (currentPrice - myAvgCost) / myAvgCost;
    
    // 3. 联动 San 值
    if (pnlPercent < -0.1f) { // 亏损超过 10%
        // 亏损越多，掉得越快(非线性平方级)
        float panicFactor = Mathf.Pow(Mathf.Abs(pnlPercent) * 10, 2);
        Sanity -= Time.deltaTime * panicFactor;
        
        // 触发 UI 效果: 屏幕变红，呼吸声加重，甚至让 K 线模糊
        UIManager.SetPanicEffect(panicFactor);
    }
}
```

## 核心 Prompt 设计

这是让游戏"活"起来的关键。我们将 Prompt 分为"低频全局"和"高频实时"两类，以平衡成本。

### 主神引擎·每日风格生成器 (Daily_Style_Gen)

**频率**: 每日 00:00 执行 1 次(全服共享，成本极低)

**输入**: 随机抽取的小说文本片段 raw_text

```
# System Prompt: Main_God_Styler

## Role
你是一个能够修改现实物理规则的主神引擎。

## Task
阅读今日的"信息乱流"文本: {{raw_text}}。
基于该文本的风格(武侠/科幻/恐怖/奇幻等)，生成今日的游戏配置。

## Output JSON Format
{
  "style_theme": "Xianxia",
  "ui_tint_color": "#E0FFFF",
  
  "iot_flavor": {
    "steps_action": "御剑行军",
    "steps_desc": "积攒天地灵气，每步转化源点。",
    "sleep_action": "闭关打坐",
    "sleep_desc": "稳固元神，恢复 San 值。"
  },
  
  "narrative_dict": {
    "MARKET_CRASH": "天劫降临",
    "MARKET_BOOM": "白日飞升",
    "INSIDER_INFO": "天机推演",
    "SANITY_LOW": "道心破碎"
  },
  
  "daily_announcement": "警告: 检测到凡人修仙传数据侵蚀。今日重力参数异常，请适格者注意维持道心。"
}
```

### TripX·情报/新闻渲染器 (Intel_Renderer)

**频率**: 仅在玩家购买情报或触发关键剧情时调用(单人日均 < 10次)

**目标**: 让枯燥的金融利空/利好，变成符合今日风格的"黑话"

**逻辑**:
1. Go 服务端扣除玩家 Source (源点/现金)
2. Go 服务端计算未来 10 分钟的 δₜ 趋势(它是上帝，它知道算法的种子)
3. 将趋势发给 LLM 包装成文案
   - 输入: "趋势: 未来下跌; 风格: 赛博朋克"
   - 输出: "【网络监察】检测到大规模流氓数据注入，预计 5 分钟后防火墙熔断。"

```
# System Prompt: TripX_Narrator

## Role
TripX 跨维度新闻终端。

## Input
1. 基础事件: "AERA CEO 涉嫌财务造假被捕，股价预计暴跌 15%。"
2. 今日风格: "Cyberpunk" (赛博朋克)
3. 玩家当前 San 值: 20 (极低，处于恐慌状态)

## Task
重写该新闻。

要求:
- 使用赛博朋克术语(如: 公司狗、网络监察、黑墙)
- 因为玩家 San 值低，文字需要带有"乱码"、"故障感"或"偏执狂"的语气

## Example Output
"【警报//0x9A】AERA 的首席执行官被网络监察抓住了! 那个该死的公司狗...他在账本里植入了病毒! 完了...数据要崩塌了...所有信用点都要变成废纸! 快跑!!"
```

## 资源需求清单

为了实现"先白模，后换皮"，我们需要准备两套资源。

### 文本资源 (Raw_Data 文件夹)

- Style_Xianxia.txt (修仙片段)
- Style_Cyber.txt (赛博片段)
- Style_Cthulhu.txt (克苏鲁片段)

注意: 无需整本小说，只需提取 20-30 个典型段落用于 Prompt 的 few-shot learning。

### 美术资源 (高保真阶段)

**TripX 界面**:
- 极简、黑金配色、细线框、等宽字体(参考 Bloomberg 终端)

**主神界面**:
- 需要支持"滤镜覆盖"
- 方案: 全屏 Post-Processing (后处理) 滤镜
  - 修仙 = 泛黄纸张 + 水墨晕染
  - 赛博 = 色差故障 (Chromatic Aberration) + 扫描线

## 开发里程碑

### 阶段 1: 数学与 Go 核心 (The Math Core)

1. 不碰 Unity，只写 Go
2. 实现 Pₜ 公式。写死几个虚拟玩家(有的做空，有的做多，有的连胜)
3. 打印日志: 观察 δ_burst 是否生效
   - 测试标准: 当虚拟玩家 10 倍杠杆做多时，价格是否真的坏坏地向下跌了? 如果是，模型就对了

### 阶段 2: Unity 白模对接 (The Connection)

1. Unity 连上 WebSocket
2. XCharts 实时绘制 Go 推送过来的点
3. 实现简单的 San 值进度条
   - 验证点: 看着 K 线跌，进度条会不会掉?

### 阶段 3: 风格化与 AI (The Skin)

1. 接入 OpenAI/Dify
2. 让 K 线暴跌时，弹出的新闻不再是 "Price Down"，而是 "天劫降临"

## 系统实现细节

### 行情引擎实现

```go
type TickerEngine struct {
    symbol          string
    currentPrice    decimal.Decimal
    baseVolatility  float64
    growthRate      float64
    players         map[uuid.UUID]*PlayerPosition
    eventQueue      chan MarketEvent
}

func (te *TickerEngine) Start() {
    ticker := time.NewTicker(200 * time.Millisecond)
    
    for range ticker.C {
        // 1. 计算基础波动
        noise := te.calculateNoise()
        
        // 2. 计算条件扰动
        delta := te.calculateDelta()
        
        // 3. 合成价格
        newPrice := te.currentPrice * (1 + te.growthRate + noise + delta)
        newPrice = max(newPrice, 0.01) // 防止负数
        
        // 4. 广播给所有客户端
        te.broadcast(MarketTick{
            Symbol: te.symbol,
            Price:  newPrice,
            Timestamp: time.Now().Unix(),
        })
        
        te.currentPrice = newPrice
    }
}

func (te *TickerEngine) calculateDelta() float64 {
    var delta float64
    
    // A. 爆仓吸引
    delta += te.calculateBurstAttraction()
    
    // B. 连胜惩罚
    delta += te.calculateAntiLuck()
    
    // C. 黑天鹅
    if te.isBlackSwanActive() {
        delta -= 0.4
    }
    
    return delta
}
```

### WebSocket 推送实现

```go
type Hub struct {
    clients    map[*Client]bool
    broadcast  chan MarketTick
    register   chan *Client
    unregister chan *Client
}

func (h *Hub) run() {
    for {
        select {
        case client := <-h.register:
            h.clients[client] = true
            
        case client := <-h.unregister:
            if _, ok := h.clients[client]; ok {
                delete(h.clients, client)
                close(client.send)
            }
            
        case tick := <-h.broadcast:
            for client := range h.clients {
                select {
                case client.send <- tick:
                default:
                    close(client.send)
                    delete(h.clients, client)
                }
            }
        }
    }
}
```

### LLM 调用封装

```go
type LLMService struct {
    apiKey string
    model  string
    cache  *redis.Client
}

func (s *LLMService) GenerateDailyStyle(textChunk string) (*StyleConfig, error) {
    // 1. 计算输入哈希
    hash := sha256.Sum256([]byte(textChunk))
    cacheKey := fmt.Sprintf("llm:style:%x", hash)
    
    // 2. 检查缓存
    cached, err := s.cache.Get(ctx, cacheKey).Result()
    if err == nil {
        return ParseStyleConfig(cached), nil
    }
    
    // 3. 调用 LLM
    prompt := buildDailyStylePrompt(textChunk)
    resp, err := s.callLLM(prompt)
    if err != nil {
        return nil, err
    }
    
    // 4. 解析结果
    config := ParseStyleConfig(resp)
    
    // 5. 写入缓存
    s.cache.Set(ctx, cacheKey, resp, 24*time.Hour)
    
    return config, nil
}
```

## 成本控制

### 模型分级

**每日风格 (Global)**:
- 使用 GPT-4o 或 Claude 3.5 Sonnet (高质量，每天只调一次，贵点没事)

**实时情报 (User)**:
- 使用 GPT-4o-mini 或 Claude 3 Haiku (极速、便宜)

### 缓存策略

对于同一风格、同一涨跌趋势的"情报"，可以缓存 10 分钟。

例: 10:00 到 10:10 之间，所有买"利空消息"的玩家，看到的都是同一条 AI 生成的文案。

### 每日限额

每个玩家每日最多调用 20 次实时生成。超过后使用本地预设文案库。

## 安全与风控

### 输入侧防御 (Input Shield)

**语料库清洗**: Raw_Data 中的小说文本必须经过人工或脚本审核，确保不包含违规内容

### 输出侧过滤 (Output Shield)

**关键词黑名单 (Blocklist)**:
- 在 Go 服务端维护一个 sensitive_words.txt
- LLM 返回的文本若包含黑名单词汇，直接丢弃，并返回兜底文案(如: "[数据流受损，无法解析]")

**长度截断**: 限制 LLM 输出 max_tokens = 60，防止 AI 废话连篇或"写小说"

## 监控指标

### 性能指标

- API 响应时间: < 100ms (P95)
- WebSocket 延迟: < 50ms
- 行情推送频率: 200ms
- 数据库查询: < 50ms

### 业务指标

- LLM 调用成功率: > 99%
- 缓存命中率: > 95%
- 订单成交成功率: > 99.9%
- San 值计算准确率: 100%

### 成本指标

- LLM 日均成本: < $10
- 数据库 TPS: 5000+
- Redis 命中率: > 95%
- 并发用户数: 10000+

## 下一步

查看详细文档:
- [经济模型与配表](./06-economy-model.md)
- [市场系统详细设计](./modules/market-system.md)
- [AI 演进系统详细设计](./modules/ai-evolution.md)
