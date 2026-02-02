# 核心架构总览

## 高概念定义 (High Concept)

### "现实即副本，肉身即外挂"

blackSwan 是一个基于现实映射的、无限流风格的自动演进式 RPG 游戏。

### 核心要素

#### 世界观重构 (The Truth)

玩家所处的现实世界(表世界)本质上是"诸天主神空间"。玩家佩戴的智能设备(戒指/手表)是主神发放的"控制终端"。

#### 核心冲突 (The Conflict)

主神空间正在发生不可逆的数据坍塌(末世)。一个名为 TripX (AERA) 的公司在主神空间内创造了虚拟世界(里世界)，并声称拥有逃离主神空间的能力。玩家必须利用在"主神空间(现实)"赚取的高维能量，进入 TripX 模拟仓，在一次次黑天鹅事件中幸存，最终赎回唯一的方舟船票。

#### 自动演进 (Auto-Evolution)

游戏没有固定的"日常任务"。主神引擎(AI)每天会吞噬不同的原始文本(如武侠、科幻、克苏鲁小说)，将当天的现实世界规则重写。

示例:
- 今日: 吞噬《修仙指南》，你在公园跑步判定为"轻功"
- 明日: 吞噬《星际迷航》，你在公园跑步判定为"曲速引擎充能"

## 三位一体架构 (Trinity Architecture)

### L1. 后端层: 主神引擎 (Main God Engine)

**定义**: 服务器端的 AI 大脑

**核心职责**: 风格化渲染与规则映射

**工作流**:
1. 文本吞噬: 每日零点，系统随机抽取 Style_Corpus(如《修仙.txt》)
2. 规则覆写: 将 IoT 数据(心率、步数)的意义进行重定义
3. 叙事生成: 实时生成里世界的突发剧情与表世界的任务描述

### L2. 表世界: 诸天主神空间 (The Surface)

**定义**: 玩家肉身所在的物理现实世界

**核心玩法**: 快穿副本 (Sub-Worlds)

**IoT 交互本质**: 采集源点 (Source)

诸天行者(玩家)通过在物理世界的行为(运动、睡眠、探索)，从高维位面汲取能量。

**自动演进表现**:
- Day 1 (武侠流): 提示"前往练功房打坐"，奖励【真气(源点)】
- Day 2 (赛博流): 提示"寻找高频信号点骇入"，奖励【比特流(源点)】

**产出物**: 源点(所有风格的能量最终统一汇聚为源点，这是里世界的通用货币)

### L3. 里世界: TripX 模拟仓 (The Inner)

**定义**: 游戏中，主神空间内的 TripX (AERA) 公司创造的虚拟世界

**核心玩法**: 末日博弈 & 剧情抉择

**设定**: 这是一个被锁定的、极高难度的金融末日副本

**消耗机制**: 玩家必须消耗在表世界赚取的源点，才能:
- 降维打击: 在金融海啸中强行拉升 K 线
- 心智覆写: 解锁女主被锁死的"绝望"对话分支
- 兑换船票: 达成最终通关

## 核心循环

游戏中的一天(非地球的一天)流程:

```
早晨: 苏醒 → 查看今日主神风格

↓

表世界自动演进 (基于风格):
- 修仙位面: 跑步=御剑 / 睡眠=闭关
- 废土位面: 跑步=拾荒 / 睡眠=休眠

↓

获得核心资源: 源点 (Source)

↓

晚上: 进入 TripX 模拟仓

↓

里世界危机: 黑天鹅爆发 / 资产暴跌

↓

抉择:
- 消耗源点 → 高维干涉 / 剧情逆转
- 不消耗 → 依靠数值硬抗 / 承受 San 值惩罚

↓

推进主线 Px 阶段 → 积累资产，逼近终局
```

## 叙事结构: T 型架构

### 竖轴: 里世界主线 (The Constant)

**位置**: TripX 模拟仓内

**性质**: 稳定、连续、强叙事

**内容**: 包含 P0~P7 阶段、女主情感线、公司阴谋揭秘

**规则**: 这部分剧情不会因为当天的风格变化而面目全非

无论今天是修仙还是废土，TripX 里依然是那个冰冷的金融末日，校花依然需要被拯救。

### 横轴: 表世界日常 (The Variable)

**位置**: 主神空间(现实世界)

**性质**: 随机、碎片、弱叙事

**内容**: 由 AI 每日基于文本生成的快穿任务

**规则**: 它是玩家在现实生活中每一天的"滤镜"，只负责提供氛围和获取源点的理由

## 关键机制: 文本注入与自动演进

这是本项目的技术护城河。我们没有每日任务，我们由原始文本驱动任务。

### 文本注入 (Text Injection)

- 开发团队维护 Raw_Data 文件夹(包含小说片段/设定集)
- Prompt 逻辑: Main_God_Agent 读取文本 → 提取关键词 → 映射到 IoT 动作

### 双重干涉 (Dual Interference)

1. 表 → 里: 现实的高维能量(源点)决定了你在 TripX 里有多大的"修改器权限"
2. 里 → 表: TripX 里的重大故障(如病毒爆发)会反向污染现实 UI，甚至强制锁定第二天的"主神风格"(如: 强制进入生化危机模式)

## 技术架构概览

### 服务端架构

```
客户端 (Unity)
    ↕ WebSocket / HTTPS
Golang 核心服务 (Gin)
    ├── Handler Layer
    ├── Usecase Layer
    ├── Repository Layer
    └── Domain Layer
    ↕
PostgreSQL + Redis
    ↕
AI 服务 (LLM API)
```

### 核心模块

1. 认证系统 (Auth)
2. IoT 数据同步 (IoT Sync)
3. 世界演进引擎 (World Evolution)
4. 行情引擎 (Market Engine)
5. 交易系统 (Trading)
6. San 值系统 (Sanity)
7. 商店系统 (Shop)
8. NPC 互动系统 (NPC Interaction)

### 数据流向

```
IoT 设备 → Unity 客户端 → Golang API
    ↓
风控校验 → 计算奖励 → 更新余额
    ↓
记录流水 → 缓存同步 → 返回结果
```

## 核心对象定义

### Player (玩家)
```json
{
  "id": "uuid",
  "nickname": "string",
  "created_at": "RFC3339"
}
```

### Balance (余额)
```json
{
  "asset": "SOURCE",
  "available": "1500",
  "locked": "0"
}
```

### WorldDayStyle (每日风格)
```json
{
  "world_date": "2026-02-02",
  "style_tag": "Cyber",
  "theme": {
    "primary": "#00E5FF",
    "warning": "#FF4500"
  },
  "currency_name": "灵石",
  "iot_mapping": {
    "run": {
      "name": "数据运送",
      "desc": "躲避防火墙扫描"
    }
  },
  "market_terms": {
    "bull": "飞升",
    "bear": "天劫",
    "crash": "道崩"
  }
}
```

### MarketQuote (行情)
```json
{
  "symbol": "AERA",
  "ts": 1738029283,
  "price": "124.56",
  "trend_flag": -1
}
```

### Order (订单)
```json
{
  "id": "uuid",
  "symbol": "AERA",
  "side": "BUY",
  "type": "MARKET",
  "requested_qty": "10",
  "filled_qty": "10",
  "avg_price": "124.60",
  "status": "FILLED",
  "created_at": "RFC3339"
}
```

### Position (持仓)
```json
{
  "symbol": "AERA",
  "qty": "10",
  "avg_price": "120.00",
  "mark_price": "124.56",
  "floating_pnl": "45.60",
  "floating_pnl_pct": "0.038"
}
```

### SanityStatus (San 值状态)
```json
{
  "value": 72.5,
  "max": 100.0,
  "state": "ANXIOUS",
  "last_calc_at": 1738029283
}
```

### HeroineState (女主状态)
```json
{
  "npc": "HEROINE",
  "affection_level": 3,
  "affection_points": 120,
  "mood": "NORMAL",
  "last_interaction_at": "RFC3339"
}
```

## 关键设计决策

### 1. 为什么使用 Golang

- 高并发支持 (Goroutine)
- 适合实时行情推送
- 优秀的性能
- 简单的部署

### 2. 为什么使用 PostgreSQL

- ACID 事务保证
- 丰富的数据类型 (JSONB, NUMERIC)
- 强大的索引能力
- 成熟的生态

### 3. 为什么不强制平仓

- 增加策略深度
- 允许持仓过夜
- 风险由 San 值限制
- 更真实的交易体验

### 4. 为什么使用 LLM

- 动态内容生成
- 降低开发成本
- 提高可玩性
- 自动演进核心机制

## 扩展性考虑

### 水平扩展

- Stateless API 设计
- Redis 共享状态
- 行情引擎可集群部署
- 数据库读写分离

### 垂直扩展

- 配置表驱动
- Prompt 模板化
- 模块解耦
- 热更新支持

## 性能指标

### 目标性能

- API 响应: < 100ms (P95)
- WebSocket 延迟: < 50ms
- 行情推送频率: 200ms
- 并发用户: 10000+
- 数据库 TPS: 5000+

### 监控指标

- API 成功率 > 99.9%
- 数据库连接池使用率 < 80%
- Redis 命中率 > 95%
- LLM 调用成功率 > 99%

## 安全考虑

### 数据安全

- 所有密码 Hash 存储
- Token 使用 JWT
- Session 使用 Refresh Token
- 敏感数据加密

### 业务安全

- 幂等性保证 (Idempotency Key)
- 防重放攻击
- 防刷钱作弊
- 限流熔断

### AI 安全

- LLM 输入脱敏
- 输出内容过滤
- 敏感词黑名单
- 审计日志

## 下一步

查看详细文档:
- [世界观设定](./02-world-setting.md)
- [时空映射机制](./03-time-mapping.md)
- [市场博弈机制](./04-market-mechanism.md)
- [技术实现](./05-tech-implementation.md)
- [经济模型](./06-economy-model.md)
