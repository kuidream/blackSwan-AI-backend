# AI 演进与情报生成系统详细设计

## 模块概述

本模块负责文本流 (Text Stream) 的处理。

### 输入

每日随机抽取的原始小说片段 (Raw_Text) + 实时游戏数据 (Game_State)

### 核心

LLM (大语言模型) + Prompt 模板库

### 输出

1. 全局配置 (JSON): 每日 UI 主题色、IoT 动作重命名
2. 情报文案 (String): 带有风格滤镜和 San 值扭曲的金融新闻

## 每日演进流程 (Global Evolution)

### 执行时机

每日 00:00 (服务端定时任务)

### 资源消耗

低 (每日 1 次调用)

### 风格生成 Prompt

该 Prompt 负责"读小说"，并提取出游戏的"今日规则"。

```
# System Prompt: Game_World_Architect

## Role
你是一个沉浸式游戏的"世界观架构师"。

## Input
今日原始文本: {{raw_text_chunk}} (约 500 字)

## Task
1. 分析文本的题材风格 (武侠/赛博/末日/克苏鲁/都市)
2. 提取文本中的核心名词，替换游戏内的 IoT 术语
3. 生成一组 UI 配色方案 (Hex Code)

## Constraints
- 输出必须为标准 JSON 格式
- "steps_action" (跑步) 必须是动词短语 (如: 御剑)
- "sanity_name" (理智) 必须符合风格 (如: 道心/算力/San值)

## Output JSON Structure
{
  "style_tag": "Xianxia",
  "theme_color_primary": "#E0FFFF",
  "theme_color_warning": "#FF4500",
  "currency_name": "灵石",
  "iot_mapping": {
    "run": {
      "name": "神行",
      "desc": "消耗体力，积累天地灵气"
    },
    "sleep": {
      "name": "闭关",
      "desc": "稳固境界"
    }
  },
  "market_terms": {
    "bull": "飞升",
    "bear": "天劫",
    "crash": "道崩"
  }
}
```

### 容错机制

如果 LLM API 超时或返回非 JSON 格式:

**机制**: 后端捕获异常，自动加载本地默认配置 (Default_Cyberpunk.json)

**日志**: 记录 Error Log，但不影响玩家登录

## 实时情报渲染 (Real-time Intel)

### 执行时机

玩家付费点击"购买情报"时

### 资源消耗

中 (单人日均 < 10 次)

### 动态文案 Prompt

该 Prompt 负责"说黑话"。它需要结合风格和玩家当前的 San 值。

```
# System Prompt: TripX_Narrator

## Role
你是一个跨维度的金融终端 AI。

## Context
- 当前风格: {{current_style}} (例如: 克苏鲁)
- 玩家 San 值: {{user_sanity}} (0-100)
- 市场事件: {{market_event}} (例如: AERA 股价即将下跌 15%)

## Task
生成一条简短的快讯 (30字以内)。

## Rules
1. 若 San 值 > 60: 语言逻辑清晰，带有风格隐喻
   - 例: "星辰的位置不对，深渊正在凝视 AERA 的股价。"
2. 若 San 值 < 30: 语言破碎，充满恐惧、乱码和幻觉
   - 例: "不要看! K线变成了触手... 它们在吃... 15%... 逃..."

## Output
(直接输出纯文本，无需 JSON)
```

### 幻觉注入 (Hallucination Injection)

为了节省 Token，部分简单的"乱码效果"不需要 LLM 生成，而是由客户端着色器 (Shader) 或字符串处理函数完成。

```csharp
// 客户端后处理 C#
string ProcessText(string rawText, float sanity) {
    if (sanity > 50) return rawText;
    
    // San值低时，随机插入乱码字符
    char[] glitchChars = {'#', '?', '§', 'µ', 'ø'};
    
    // 算法: 每隔 N 个字符替换一个乱码
    return GlitchAlgorithm.Apply(rawText, intensity: (100 - sanity));
}
```

## 安全与风控

既然接入了 LLM，就必须防止 AI 生成敏感内容(政治、色情、暴力)。

### 输入侧防御 (Input Shield)

**语料库清洗**: Raw_Data 中的小说文本必须经过人工或脚本审核，确保不包含违规内容

### 输出侧过滤 (Output Shield)

**关键词黑名单 (Blocklist)**:
- 在 Go 服务端维护一个 sensitive_words.txt
- LLM 返回的文本若包含黑名单词汇，直接丢弃，并返回兜底文案(如: "[数据流受损，无法解析]")

**长度截断**: 限制 LLM 输出 max_tokens = 60，防止 AI 废话连篇或"写小说"

## 实现示例

### 每日风格生成服务

```go
type WorldEvolutionService struct {
    llmClient   *LLMClient
    corpusRepo  CorpusRepository
    promptRepo  PromptRepository
    cache       *redis.Client
}

func (s *WorldEvolutionService) GenerateDailyStyle() error {
    // 1. 抽取语料库条目
    corpus, err := s.corpusRepo.GetRandomChunk()
    if err != nil {
        return err
    }
    
    // 2. 构建 Prompt
    template, err := s.promptRepo.GetByFunctionType("Daily_Gen")
    if err != nil {
        return err
    }
    
    prompt := s.buildPrompt(template, map[string]string{
        "raw_text_chunk": corpus.TextContent,
    })
    
    // 3. 调用 LLM
    resp, err := s.llmClient.Generate(prompt, LLMOptions{
        MaxTokens:   500,
        Temperature: 0.7,
    })
    
    if err != nil {
        // 容错: 使用默认配置
        log.Error("LLM call failed, using default config", "error", err)
        return s.useDefaultConfig()
    }
    
    // 4. 解析结果
    config, err := ParseStyleConfig(resp.Text)
    if err != nil {
        log.Error("Failed to parse LLM output", "error", err)
        return s.useDefaultConfig()
    }
    
    // 5. 保存到数据库
    worldDate := time.Now().Format("2006-01-02")
    worldDay := &WorldDayStyle{
        WorldDate:     worldDate,
        StyleTagCode:  config.StyleTag,
        Config:        config.ToJSON(),
        LLMRunID:      resp.RunID,
    }
    
    err = s.repo.SaveWorldDayStyle(worldDay)
    if err != nil {
        return err
    }
    
    // 6. 缓存到 Redis
    cacheKey := fmt.Sprintf("world:style:%s", worldDate)
    s.cache.Set(ctx, cacheKey, config.ToJSON(), 24*time.Hour)
    
    log.Info("Daily style generated successfully",
        "date", worldDate,
        "style", config.StyleTag)
    
    return nil
}

func (s *WorldEvolutionService) useDefaultConfig() error {
    // 加载默认配置
    defaultConfig := LoadDefaultConfig("Cyberpunk")
    
    worldDate := time.Now().Format("2006-01-02")
    worldDay := &WorldDayStyle{
        WorldDate:    worldDate,
        StyleTagCode: "Cyber",
        Config:       defaultConfig.ToJSON(),
    }
    
    s.repo.SaveWorldDayStyle(worldDay)
    
    cacheKey := fmt.Sprintf("world:style:%s", worldDate)
    s.cache.Set(ctx, cacheKey, defaultConfig.ToJSON(), 24*time.Hour)
    
    return nil
}
```

### 实时情报生成服务

```go
type IntelService struct {
    llmClient      *LLMClient
    worldService   WorldEvolutionService
    sanityService  SanityService
    cache          *redis.Client
}

func (s *IntelService) GenerateIntel(playerID uuid.UUID, event string) (string, error) {
    // 1. 获取今日风格
    style, err := s.worldService.GetTodayStyle()
    if err != nil {
        return "", err
    }
    
    // 2. 获取玩家 San 值
    sanity, err := s.sanityService.GetPlayerSanity(playerID)
    if err != nil {
        return "", err
    }
    
    // 3. 构建缓存键 (相同条件缓存 10 分钟)
    cacheKey := fmt.Sprintf("intel:%s:san%d:%s",
        style.StyleTagCode,
        int(sanity.Value/10)*10, // 按 10 取整
        event)
    
    // 4. 检查缓存
    cached, err := s.cache.Get(ctx, cacheKey).Result()
    if err == nil {
        return cached, nil
    }
    
    // 5. 构建 Prompt
    template, _ := s.promptRepo.GetByFunctionType("Intel_News")
    prompt := s.buildPrompt(template, map[string]interface{}{
        "current_style": style.StyleTagCode,
        "user_sanity":   sanity.Value,
        "market_event":  event,
    })
    
    // 6. 调用 LLM
    resp, err := s.llmClient.Generate(prompt, LLMOptions{
        MaxTokens:   100,
        Temperature: 1.2, // 高创造性
    })
    
    if err != nil {
        // 容错: 返回兜底文案
        return "[数据流受损，无法解析]", nil
    }
    
    // 7. 敏感词过滤
    filteredText := s.filterSensitiveWords(resp.Text)
    
    // 8. 缓存结果
    s.cache.Set(ctx, cacheKey, filteredText, 10*time.Minute)
    
    return filteredText, nil
}

func (s *IntelService) filterSensitiveWords(text string) string {
    // 加载黑名单
    blacklist := LoadSensitiveWords()
    
    for _, word := range blacklist {
        if strings.Contains(text, word) {
            log.Warn("Sensitive word detected", "word", word)
            return "[内容违规，已被过滤]"
        }
    }
    
    return text
}
```

## 配表需求

### Cfg_Style_Corpus.xlsx

| ID | Style_Tag | Text_Content (TextChunk) | Weight |
|----|-----------|------------------------|--------|
| 1 | Xianxia | "韩立眉头一皱，退至众人身后..." | 10 |
| 2 | Cyber | "霓虹灯在积水中倒映出破碎的代码..." | 10 |
| 3 | Cthulhu | "那不可名状的几何体在疯狂旋转..." | 5 |

### Cfg_Prompt_Template.xlsx

| ID | Function_Type | System_Prompt_Text | Max_Tokens | Temperature |
|----|--------------|-------------------|------------|-------------|
| 1 | Daily_Gen | "你是一个沉浸式游戏的..." | 500 | 0.7 |
| 2 | Intel_News | "你是一个跨维度的金融终端..." | 100 | 1.2 |

## 系统流程图

```
Server Side (Golang)
    Cron 00:00 定时任务
    ↓
    1. 读取语料 → PostgreSQL
    ↓
    2. 组装 Prompt → LLM API
    ↓
    3. 返回 JSON → 格式校验
    ↓
    [通过] → Redis 今日全局配置
    [失败] → 加载兜底配置

Client Side (Unity)
    玩家购买情报
    ↓
    4. Request → Server API
    ↓
    5. 组装 San值 + 趋势 → LLM API
    ↓
    6. 返回文案 → 敏感词过滤
    ↓
    7. 下发 → UI 情报弹窗
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

## 监控与优化

### 关键指标

- LLM 调用成功率: > 99%
- LLM 平均延迟: < 2s
- 缓存命中率: > 80%
- 日均 LLM 成本: < $10

### 性能优化

- 使用缓存减少 LLM 调用
- 批量处理请求
- 异步调用 LLM
- 设置合理的超时时间

## 下一步

查看相关文档:
- [世界观设定](../02-world-setting.md)
- [时空映射机制](../03-time-mapping.md)
- [技术实现](../05-tech-implementation.md)
