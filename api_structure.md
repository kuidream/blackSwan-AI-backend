# 核心 API 结构（RESTful）

## 风险点（先列出，再给出 API）
1. **行情引擎一致性风险**：Tick 广播、撮合/成交、仓位与余额扣减若不在同一“权威状态机”里，会出现回放不一致与套利漏洞。
2. **Tick 数据爆炸**：200ms 推送意味着单日千万级记录，若无冷热分层/分区/保留策略，DB 会先死于 IO 与索引膨胀。
3. **反作弊与 IoT 可信度**：只靠客户端上报必然被重放/篡改；签名、幂等、速率物理墙与异常画像缺一不可。
4. **经济通胀与刷钱**：源点是现金本金；若上限、系数、风格加成与黑天鹅消耗不闭环，会导致数值失控。
5. **LLM 可用性与成本**：每日风格与实时情报若强依赖 LLM，会遭遇超时/额度/成本爆炸；必须有缓存与兜底配置。
6. **合规与内容安全**：LLM 输出可能触发敏感内容；需要输出过滤、审计与回退文案。
7. **幂等与并发扣款**：下单、购买情报/技能、心智覆写、IoT 同步都涉及扣款；缺幂等键会导致重复扣减。
8. **循环依赖与工程失控**：Gin Handler、Usecase、Repo、Domain 若边界不清，后期会变成“互相 import”。

---

## 通用约定
- **Base URL**：`/v1`
- **认证**：`Authorization: Bearer <access_token>`
- **幂等**：对“会扣款/会生成订单/会入账”的写接口支持 `Idempotency-Key`（同一玩家同一键 24h 内返回同一结果）。
- **时间**：全部使用 Unix 秒或 RFC3339（UTC）。
- **金额/数量**：避免 float；用字符串或 decimal（示例中用字符串表示）。
- **统一响应**
  - Success
    ```json
    { "request_id": "uuid", "server_time": 1738029283, "data": {} }
    ```
  - Error
    ```json
    { "request_id": "uuid", "server_time": 1738029283, "error": { "code": "SANITY_LOW", "message": "San值过低，禁止该操作", "details": {} } }
    ```

---

## 核心对象（JSON 结构）
- **Player**
  ```json
  { "id":"uuid", "nickname":"string", "created_at":"RFC3339" }
  ```
- **Balance**
  ```json
  { "asset":"SOURCE", "available":"1500", "locked":"0" }
  ```
- **WorldDayStyle**
  ```json
  {
    "world_date":"2026-02-02",
    "style_tag":"Cyber",
    "theme":{"primary":"#00E5FF","warning":"#FF4500"},
    "currency_name":"灵石",
    "iot_mapping":{"run":{"name":"数据运送","desc":"..."}, "sleep":{"name":"系统维护","desc":"..."}},
    "market_terms":{"bull":"飞升","bear":"天劫","crash":"道崩"}
  }
  ```
- **MarketQuote**
  ```json
  { "symbol":"AERA", "ts":1738029283, "price":"124.56", "trend_flag":-1 }
  ```
- **Order**
  ```json
  {
    "id":"uuid","symbol":"AERA","side":"BUY","type":"MARKET",
    "requested_qty":"10","filled_qty":"10","avg_price":"124.60",
    "status":"FILLED","created_at":"RFC3339"
  }
  ```
- **Position**
  ```json
  { "symbol":"AERA", "qty":"10", "avg_price":"120.00", "mark_price":"124.56", "floating_pnl":"45.60", "floating_pnl_pct":"0.038" }
  ```
- **SanityStatus**
  ```json
  { "value":72.5, "max":100.0, "state":"ANXIOUS", "last_calc_at":1738029283 }
  ```
- **HeroineState**
  ```json
  { "npc":"HEROINE", "affection_level":3, "affection_points":120, "mood":"NORMAL", "last_interaction_at":"RFC3339" }
  ```

---

## Auth
### POST /v1/auth/login
- **用途**：登录/注册（建议接入 Apple/Google/游客凭证；后端统一签发 token）
- Headers：`Idempotency-Key`
- Request
  ```json
  { "provider":"APPLE|GOOGLE|GUEST", "provider_token":"string", "device":{"platform":"iOS","device_id":"string"} }
  ```
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "player":{ "id":"uuid","nickname":"string","created_at":"RFC3339" }, "access_token":"string","expires_in":3600, "refresh_token":"string" } }
  ```

### POST /v1/auth/refresh
- Request
  ```json
  { "refresh_token":"string" }
  ```
- Response：同 login（返回新 access_token）

### POST /v1/auth/logout
- Response：`data: {}`

---

## Player / 资产
### GET /v1/users/me
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "player":{ "id":"uuid","nickname":"string","created_at":"RFC3339" } } }
  ```

### GET /v1/wallet/balances
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "balances":[ { "asset":"SOURCE","available":"1500","locked":"0" }, { "asset":"AERA","available":"10","locked":"0" } ] } }
  ```

### GET /v1/wallet/ledger?limit=50&cursor=...
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "items":[ { "id":"uuid","asset":"SOURCE","delta":"-100","reason":"SHOP_PURCHASE","ref_id":"uuid","created_at":"RFC3339" } ], "next_cursor":"string" } }
  ```

---

## 世界演进（每日风格）
### GET /v1/world/today
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "world_day":{ "world_date":"2026-02-02" }, "style":{  } } }
  ```

### GET /v1/world/history?from=2026-01-01&to=2026-02-02
- Response：`data.styles: WorldDayStyle[]`

---

## IoT 同步（源点入账）
### POST /v1/iot/sync
- Headers：`Idempotency-Key`
- Request（最小可行；raw 可用于稽核/回放）
  ```json
  {
    "device":{"platform":"iOS","vendor":"AppleWatch","external_id":"string"},
    "client_ts":1738029200,
    "since_ts":1738020000,
    "metrics":{
      "steps":7000,
      "heart_rate_avg":80,
      "sleep":{"total_hours":7.5,"deep_hours":2.0}
    },
    "signature":{"alg":"HMAC-SHA256","nonce":"string","sig":"hex"}
  }
  ```
- Response
  ```json
  {
    "request_id":"uuid","server_time":1738029283,
    "data":{
      "added_source":"700",
      "bonus_source":"300",
      "total_added_source":"1000",
      "balances":[ { "asset":"SOURCE","available":"1500","locked":"0" } ],
      "anti_cheat":{"status":"PASS","flags":[]}
    }
  }
  ```

---

## TripX 单日与时间槽
### POST /v1/tripx/day/start
- Headers：`Idempotency-Key`
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "player_day":{ "id":"uuid","world_date":"2026-02-02","time_slot_total":3,"time_slot_used":0 } } }
  ```

### POST /v1/tripx/actions
- Headers：`Idempotency-Key`
- Request
  ```json
  { "action":"REST|WORK|VISIT_HEROINE|BUY_INTEL|TRADE", "time_slot":"NOON", "meta":{} }
  ```
- Response：返回更新后的 `player_day`

### POST /v1/tripx/day/end
- Response：`data: {}`

---

## 行情 / 交易（REST）
### GET /v1/market/symbols
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "symbols":[ { "symbol":"AERA","quote_asset":"SOURCE","base_asset":"AERA","status":"ACTIVE" } ] } }
  ```

### GET /v1/market/quote?symbol=AERA
- Response：`data: MarketQuote`

### GET /v1/market/position?symbol=AERA
- Response：`data: Position`

### POST /v1/market/orders
- Headers：`Idempotency-Key`
- Request（T+0 市价单最小版）
  ```json
  { "symbol":"AERA", "side":"BUY|SELL", "type":"MARKET", "qty":"10", "client_order_id":"string" }
  ```
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "order":{  }, "balances":[  ], "position":{  } } }
  ```

### GET /v1/market/orders?status=OPEN&limit=50&cursor=...
- Response：`data.items: Order[]`

---

## 行情 / Tick（WebSocket）
### GET /v1/ws/market/ticks?symbol=AERA
- **S2C：MarketTick**
  ```json
  { "type":"market_tick","symbol":"AERA","ts":1738029283,"price":"124.56","volume":"5000","trend_flag":-1 }
  ```
- **S2C：MarketEvent**
  ```json
  { "type":"market_event","event":"BLACK_SWAN","severity":"HIGH","msg":"..." }
  ```
- **C2S：Ping**
  ```json
  { "type":"ping","ts":1738029283 }
  ```

---

## San 值
### GET /v1/sanity/status
- Response：`data: SanityStatus`

### GET /v1/sanity/events?limit=50&cursor=...
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "items":[ { "id":"uuid","type":"BLACK_SWAN","delta":-20,"created_at":"RFC3339","meta":{} } ], "next_cursor":"string" } }
  ```

---

## 商店（情报 / 技能 / Sanity 道具）
### GET /v1/shop/items?category=INTEL|SKILL|SANITY_ITEM
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "items":[ { "id":"uuid","category":"INTEL","name":"盘前内参","cost":{"asset":"SOURCE","amount":"100"},"cooldown_seconds":86400,"effect":{"type":"SHOW_RANGE","params":{"range":0.8}} } ] } }
  ```

### POST /v1/shop/purchase
- Headers：`Idempotency-Key`
- Request
  ```json
  { "item_id":"uuid", "qty":1 }
  ```
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "purchase_id":"uuid", "balances":[  ], "granted":{ "type":"BUFF","expires_at":"RFC3339" } } }
  ```

---

## 校花（NPC）互动 / 好感度
### GET /v1/npcs/heroine/state
- Response：`data: HeroineState`

### GET /v1/npcs/heroine/schedule?world_date=2026-02-02
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "slots":[ { "time_slot":"NOON","location":"Loc_Rooftop","req_level":0 }, { "time_slot":"EVENING","location":"Loc_Library","req_level":0 } ] } }
  ```

### POST /v1/npcs/heroine/interact
- Headers：`Idempotency-Key`
- Request
  ```json
  { "time_slot":"NOON", "type":"CHAT|GIFT|DATE|MIND_OVERWRITE", "gift_id":"uuid|null", "meta":{} }
  ```
- Response
  ```json
  { "request_id":"uuid","server_time":1738029283,"data":{ "heroine_state":{  }, "sanity":{  }, "balances":[  ], "story":{ "event_key":"Event_Library_Help","lines":[ "..." ] } } }
  ```
