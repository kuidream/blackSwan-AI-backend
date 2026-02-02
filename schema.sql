-- PostgreSQL schema for blackSwan backend (Gin + GORM)
-- 说明：
-- 1) 金额/数量使用 NUMERIC，避免 float 误差
-- 2) 高频 tick 表建议后续做分区/保留策略；此处给出基础结构与索引

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========
-- 0) 参考/字典表（可热扩展，避免频繁改 ENUM）
-- =========

CREATE TABLE ref_style_tag (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

COMMENT ON TABLE ref_style_tag IS '风格标签字典（如 Xianxia/Cyber/Doom/Cthulhu），每日演进与数值系数都依赖它。';
COMMENT ON COLUMN ref_style_tag.code IS '风格代码（稳定主键，建议使用英文驼峰或大写蛇形）。';
COMMENT ON COLUMN ref_style_tag.name IS '展示用名称（可本地化）。';

CREATE TABLE ref_time_slot (
  code TEXT PRIMARY KEY,
  sort_order INT NOT NULL,
  name TEXT NOT NULL
);

COMMENT ON TABLE ref_time_slot IS '时间槽字典（Morning/Afternoon/Evening/Night 等），用于 TripX 单日推进。';

CREATE TABLE ref_asset_type (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

COMMENT ON TABLE ref_asset_type IS '资产类型字典：CASH（源点现金）、SECURITY（AERA 股票/份额）、TOKEN（其它）。';

CREATE TABLE asset (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  asset_type_code TEXT NOT NULL REFERENCES ref_asset_type(code),
  precision_scale INT NOT NULL DEFAULT 2,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE asset IS '资产主表。SOURCE=源点现金；AERA=股票/份额（也可作为礼物/互动消耗资产）。';
COMMENT ON COLUMN asset.code IS '资产代码（SOURCE/AERA/…）。';
COMMENT ON COLUMN asset.precision_scale IS '小数精度（数值层面约束，实际计算仍用 NUMERIC）。';

CREATE TABLE ref_iot_metric (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

COMMENT ON TABLE ref_iot_metric IS 'IoT 指标类型（steps/heart_rate_avg/sleep_total_hours/sleep_deep_hours 等）。';

CREATE TABLE ref_shop_category (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

COMMENT ON TABLE ref_shop_category IS '商店分类：INTEL（情报）、SKILL（技能）、SANITY_ITEM（精神道具）等。';

CREATE TABLE ref_order_side (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE ref_order_type (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE ref_order_status (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

COMMENT ON TABLE ref_order_status IS '订单状态字典：OPEN/FILLED/CANCELED/REJECTED 等。';

CREATE TABLE ref_sanity_state (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

COMMENT ON TABLE ref_sanity_state IS 'San 值阶段：LUCID/ANXIOUS/PANIC/BREAKDOWN。';

CREATE TABLE ref_npc_interaction_type (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

-- =========
-- 1) 玩家与认证
-- =========

CREATE TABLE player (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nickname TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE player IS '玩家主体。建议将强认证信息放在 auth_identity，player 只承载游戏身份。';
COMMENT ON COLUMN player.updated_at IS '由应用侧维护（更新时写入 now()）。';

CREATE TABLE auth_identity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  provider_subject TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_subject)
);

COMMENT ON TABLE auth_identity IS '第三方身份绑定（Apple/Google/游客等）。';
COMMENT ON COLUMN auth_identity.provider_subject IS '第三方唯一标识（不可逆/脱敏存储取决于平台规则）。';

CREATE INDEX idx_auth_identity_player_id ON auth_identity(player_id);

CREATE TABLE player_session (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  refresh_token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE player_session IS '登录会话（仅存 refresh_token 的 hash，避免明文泄露）。';
CREATE INDEX idx_player_session_player_id ON player_session(player_id);

CREATE TABLE player_device (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  vendor TEXT NULL,
  external_device_id TEXT NOT NULL,
  last_sync_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (player_id, external_device_id)
);

COMMENT ON TABLE player_device IS '玩家设备（手机/手表聚合标识）。external_device_id 来自客户端/系统 SDK。';
CREATE INDEX idx_player_device_player_id ON player_device(player_id);

-- =========
-- 2) 资产与账本（源点/股票/礼物消耗统一走账本，便于审计与回滚）
-- =========

CREATE TABLE player_balance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  asset_id UUID NOT NULL REFERENCES asset(id),
  available_amount NUMERIC(30, 10) NOT NULL DEFAULT 0,
  locked_amount NUMERIC(30, 10) NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (player_id, asset_id)
);

COMMENT ON TABLE player_balance IS '玩家资产余额（available 可用、locked 下单/冷却锁定）。可支持负余额（债务）但需由业务层控制。';
CREATE INDEX idx_player_balance_player_id ON player_balance(player_id);

CREATE TABLE ledger_entry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  asset_id UUID NOT NULL REFERENCES asset(id),
  delta_amount NUMERIC(30, 10) NOT NULL,
  reason_code TEXT NOT NULL,
  reference_id UUID NULL,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ledger_entry IS '账本流水（单边记账）。所有入账/扣款都必须落流水，便于审计与问题追踪。';
COMMENT ON COLUMN ledger_entry.reason_code IS '原因码：IOT_REWARD/ORDER_TRADE/SHOP_PURCHASE/SANITY_BREAKDOWN_FEE/NPC_INTERACTION 等。';
CREATE INDEX idx_ledger_entry_player_time ON ledger_entry(player_id, created_at DESC);
CREATE INDEX idx_ledger_entry_ref ON ledger_entry(reference_id);

-- =========
-- 3) 世界演进（每日风格、语料库、Prompt、LLM 调用审计）
-- =========

CREATE TABLE style_corpus_entry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  style_tag_code TEXT NOT NULL REFERENCES ref_style_tag(code),
  text_content TEXT NOT NULL,
  weight INT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE style_corpus_entry IS '语料库条目（用于每日 00:00 抽取 raw_text_chunk）。';
CREATE INDEX idx_style_corpus_tag ON style_corpus_entry(style_tag_code);

CREATE TABLE prompt_template (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  function_type TEXT NOT NULL,
  system_prompt_text TEXT NOT NULL,
  max_tokens INT NOT NULL,
  temperature NUMERIC(6, 3) NOT NULL,
  version INT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE prompt_template IS 'LLM Prompt 模板（支持策划热更、灰度与版本回滚）。';
CREATE INDEX idx_prompt_template_fn ON prompt_template(function_type, is_active);

CREATE TABLE llm_run (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  function_type TEXT NOT NULL,
  prompt_template_id UUID NULL REFERENCES prompt_template(id),
  model TEXT NOT NULL,
  input_hash TEXT NOT NULL,
  input_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  output_text TEXT NULL,
  output_json JSONB NULL,
  status TEXT NOT NULL,
  token_usage JSONB NOT NULL DEFAULT '{}'::jsonb,
  cost_usd NUMERIC(18, 6) NULL,
  error_message TEXT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ NULL
);

COMMENT ON TABLE llm_run IS 'LLM 调用审计与成本记录。注意输入可能含敏感信息，需脱敏策略与访问控制。';
CREATE INDEX idx_llm_run_fn_time ON llm_run(function_type, started_at DESC);
CREATE UNIQUE INDEX uq_llm_run_input_hash ON llm_run(function_type, input_hash);

CREATE TABLE world_day (
  world_date DATE PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE world_day IS '世界日历（按自然日）。每日风格与黑天鹅事件的发生锚定在 world_date。';

CREATE TABLE world_day_style (
  world_date DATE PRIMARY KEY REFERENCES world_day(world_date) ON DELETE CASCADE,
  style_tag_code TEXT NOT NULL REFERENCES ref_style_tag(code),
  corpus_entry_id UUID NULL REFERENCES style_corpus_entry(id),
  llm_run_id UUID NULL REFERENCES llm_run(id),
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE world_day_style IS '每日风格配置（00:00 生成/兜底）。config 为客户端可直接使用的 JSON（主题色、术语替换、IoT 文案等）。';
CREATE INDEX idx_world_day_style_tag ON world_day_style(style_tag_code);

-- =========
-- 4) IoT 数据同步（增量、幂等、防作弊标记）
-- =========

CREATE TABLE iot_sync_batch (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  device_id UUID NOT NULL REFERENCES player_device(id) ON DELETE CASCADE,
  idempotency_key TEXT NOT NULL,
  client_ts BIGINT NOT NULL,
  since_ts BIGINT NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  signature_alg TEXT NOT NULL,
  signature_nonce TEXT NOT NULL,
  signature_value TEXT NOT NULL,
  status TEXT NOT NULL,
  added_source NUMERIC(30, 10) NOT NULL DEFAULT 0,
  bonus_source NUMERIC(30, 10) NOT NULL DEFAULT 0,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (player_id, idempotency_key)
);

COMMENT ON TABLE iot_sync_batch IS '一次 IoT 同步批次（用于幂等与风控）。added_source/bonus_source 为最终入账结果。';
CREATE INDEX idx_iot_sync_batch_player_time ON iot_sync_batch(player_id, received_at DESC);

CREATE TABLE iot_data_point (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sync_batch_id UUID NOT NULL REFERENCES iot_sync_batch(id) ON DELETE CASCADE,
  metric_code TEXT NOT NULL REFERENCES ref_iot_metric(code),
  start_ts BIGINT NULL,
  end_ts BIGINT NULL,
  value NUMERIC(30, 10) NOT NULL,
  unit TEXT NULL,
  raw JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE iot_data_point IS 'IoT 指标明细（可选存明细；若仅需要结算，可只存聚合值）。';
CREATE INDEX idx_iot_data_point_batch ON iot_data_point(sync_batch_id);
CREATE INDEX idx_iot_data_point_metric ON iot_data_point(metric_code);

CREATE TABLE iot_anti_cheat_flag (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sync_batch_id UUID NOT NULL REFERENCES iot_sync_batch(id) ON DELETE CASCADE,
  flag_code TEXT NOT NULL,
  severity INT NOT NULL DEFAULT 1,
  detail TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE iot_anti_cheat_flag IS 'IoT 风控标记（速度物理墙/时间旅行/重复哈希等）。';
CREATE INDEX idx_iot_flag_batch ON iot_anti_cheat_flag(sync_batch_id);

-- =========
-- 5) TripX：玩家单日、时间槽、行动日志
-- =========

CREATE TABLE player_day (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  world_date DATE NOT NULL REFERENCES world_day(world_date) ON DELETE RESTRICT,
  time_slot_total INT NOT NULL DEFAULT 3,
  time_slot_used INT NOT NULL DEFAULT 0,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ NULL,
  UNIQUE (player_id, world_date)
);

COMMENT ON TABLE player_day IS '玩家在 TripX 的“单日”进度（时间槽推进制）。';
CREATE INDEX idx_player_day_player_date ON player_day(player_id, world_date DESC);

CREATE TABLE player_day_action (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_day_id UUID NOT NULL REFERENCES player_day(id) ON DELETE CASCADE,
  time_slot_code TEXT NOT NULL REFERENCES ref_time_slot(code),
  action_code TEXT NOT NULL,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE player_day_action IS '时间槽内的主要行动日志（买情报/交易/互动/休息等），用于审计与回放。';
CREATE INDEX idx_player_day_action_day ON player_day_action(player_day_id, created_at);

-- =========
-- 6) 市场：标的、tick、黑天鹅、订单、成交、仓位
-- =========

CREATE TABLE market_symbol (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  base_asset_id UUID NOT NULL REFERENCES asset(id),
  quote_asset_id UUID NOT NULL REFERENCES asset(id),
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE market_symbol IS '交易标的（默认 AERA/SOURCE）。base_asset=股票份额，quote_asset=源点现金。';

CREATE TABLE market_tick (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  symbol_id UUID NOT NULL REFERENCES market_symbol(id) ON DELETE CASCADE,
  ts BIGINT NOT NULL,
  price NUMERIC(30, 10) NOT NULL,
  volume NUMERIC(30, 10) NOT NULL DEFAULT 0,
  trend_flag INT NOT NULL DEFAULT 0,
  debug JSONB NOT NULL DEFAULT '{}'::jsonb
);

COMMENT ON TABLE market_tick IS '行情 tick（高频写入表）。建议后续按 ts 做分区与保留策略（例如保留 7~30 天）。';
CREATE INDEX idx_market_tick_symbol_ts ON market_tick(symbol_id, ts DESC);

CREATE TABLE market_event_def (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  style_tag_code TEXT NULL REFERENCES ref_style_tag(code),
  event_type TEXT NOT NULL,
  probability NUMERIC(10, 6) NOT NULL,
  impact_delta NUMERIC(10, 6) NOT NULL,
  duration_seconds INT NOT NULL,
  news_template_key TEXT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE market_event_def IS '黑天鹅/利好等事件定义（对应策划配表）。';
CREATE INDEX idx_market_event_def_active ON market_event_def(is_active, style_tag_code);

CREATE TABLE market_event_instance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_date DATE NOT NULL REFERENCES world_day(world_date) ON DELETE CASCADE,
  symbol_id UUID NOT NULL REFERENCES market_symbol(id) ON DELETE CASCADE,
  event_def_id UUID NOT NULL REFERENCES market_event_def(id),
  status TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ NULL,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb
);

COMMENT ON TABLE market_event_instance IS '事件实例（某日某标的实际发生的一次黑天鹅）。';
CREATE INDEX idx_market_event_instance_day ON market_event_instance(world_date, symbol_id);

CREATE TABLE market_order (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  symbol_id UUID NOT NULL REFERENCES market_symbol(id),
  side_code TEXT NOT NULL REFERENCES ref_order_side(code),
  type_code TEXT NOT NULL REFERENCES ref_order_type(code),
  status_code TEXT NOT NULL REFERENCES ref_order_status(code),
  client_order_id TEXT NULL,
  idempotency_key TEXT NOT NULL,
  requested_qty NUMERIC(30, 10) NOT NULL,
  filled_qty NUMERIC(30, 10) NOT NULL DEFAULT 0,
  avg_price NUMERIC(30, 10) NOT NULL DEFAULT 0,
  reject_reason TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (player_id, idempotency_key)
);

COMMENT ON TABLE market_order IS '订单主表（简化为市价单为主；技能单也可挂此表）。';
CREATE INDEX idx_market_order_player_time ON market_order(player_id, created_at DESC);
CREATE INDEX idx_market_order_status ON market_order(status_code, created_at DESC);

CREATE TABLE market_trade (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES market_order(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  symbol_id UUID NOT NULL REFERENCES market_symbol(id),
  qty NUMERIC(30, 10) NOT NULL,
  price NUMERIC(30, 10) NOT NULL,
  fee_asset_id UUID NOT NULL REFERENCES asset(id),
  fee_amount NUMERIC(30, 10) NOT NULL DEFAULT 0,
  slippage_rate NUMERIC(10, 6) NOT NULL DEFAULT 0,
  executed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE market_trade IS '成交明细（用于仓位均价、手续费、San 演算）。';
CREATE INDEX idx_market_trade_player_time ON market_trade(player_id, executed_at DESC);
CREATE INDEX idx_market_trade_order ON market_trade(order_id);

CREATE TABLE market_position (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  symbol_id UUID NOT NULL REFERENCES market_symbol(id),
  qty NUMERIC(30, 10) NOT NULL DEFAULT 0,
  avg_price NUMERIC(30, 10) NOT NULL DEFAULT 0,
  realized_pnl_quote NUMERIC(30, 10) NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (player_id, symbol_id)
);

COMMENT ON TABLE market_position IS '持仓汇总（T+0 交易下的净仓位）。';
CREATE INDEX idx_market_position_player ON market_position(player_id);

CREATE TABLE market_position_snapshot (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  symbol_id UUID NOT NULL REFERENCES market_symbol(id),
  ts BIGINT NOT NULL,
  qty NUMERIC(30, 10) NOT NULL,
  avg_price NUMERIC(30, 10) NOT NULL,
  mark_price NUMERIC(30, 10) NOT NULL,
  floating_pnl_quote NUMERIC(30, 10) NOT NULL,
  floating_pnl_pct NUMERIC(18, 10) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE market_position_snapshot IS '持仓快照（用于 San 被动压力实时计算与回放）。';
CREATE INDEX idx_market_pos_snap_player_ts ON market_position_snapshot(player_id, ts DESC);

-- =========
-- 7) San 值系统
-- =========

CREATE TABLE player_sanity (
  player_id UUID PRIMARY KEY REFERENCES player(id) ON DELETE CASCADE,
  value NUMERIC(10, 4) NOT NULL DEFAULT 100.0,
  base_value NUMERIC(10, 4) NOT NULL DEFAULT 100.0,
  max_value NUMERIC(10, 4) NOT NULL DEFAULT 100.0,
  state_code TEXT NOT NULL REFERENCES ref_sanity_state(code),
  last_calc_ts BIGINT NOT NULL DEFAULT 0,
  last_breakdown_at TIMESTAMPTZ NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE player_sanity IS '玩家 San 值状态（心理保证金）。state_code 决定 UI/操作惩罚与强制机制。';

CREATE TABLE sanity_event (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  delta_value NUMERIC(10, 4) NOT NULL,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE sanity_event IS 'San 事件日志（黑天鹅冲击、拒绝、踏空、强制平仓等）。';
CREATE INDEX idx_sanity_event_player_time ON sanity_event(player_id, created_at DESC);

-- =========
-- 8) 商店（情报/技能/精神道具）
-- =========

CREATE TABLE shop_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_code TEXT NOT NULL REFERENCES ref_shop_category(code),
  name_key TEXT NOT NULL,
  cost_asset_id UUID NOT NULL REFERENCES asset(id),
  cost_amount NUMERIC(30, 10) NOT NULL,
  effect_type TEXT NOT NULL,
  effect_params JSONB NOT NULL DEFAULT '{}'::jsonb,
  cooldown_seconds INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE shop_item IS '商店条目（情报/技能/道具统一建模）。effect_* 由服务端解释执行。';
CREATE INDEX idx_shop_item_category ON shop_item(category_code, is_active);

CREATE TABLE player_shop_purchase (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  shop_item_id UUID NOT NULL REFERENCES shop_item(id),
  idempotency_key TEXT NOT NULL,
  qty INT NOT NULL DEFAULT 1,
  purchased_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NULL,
  consumed_at TIMESTAMPTZ NULL,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (player_id, idempotency_key)
);

COMMENT ON TABLE player_shop_purchase IS '购买记录（用于幂等、发放与追溯）。';
CREATE INDEX idx_player_shop_purchase_player_time ON player_shop_purchase(player_id, purchased_at DESC);

CREATE TABLE player_shop_cooldown (
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  shop_item_id UUID NOT NULL REFERENCES shop_item(id) ON DELETE CASCADE,
  next_available_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (player_id, shop_item_id)
);

COMMENT ON TABLE player_shop_cooldown IS '玩家维度的商店冷却（技能/情报限次）。';

-- =========
-- 9) NPC（校花）与好感度
-- =========

CREATE TABLE npc (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE npc IS 'NPC 主表（当前核心：校花 HEROINE）。';

CREATE TABLE npc_schedule_cfg (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  npc_id UUID NOT NULL REFERENCES npc(id) ON DELETE CASCADE,
  time_slot_code TEXT NOT NULL REFERENCES ref_time_slot(code),
  style_tag_code TEXT NOT NULL REFERENCES ref_style_tag(code),
  location_code TEXT NOT NULL,
  dialog_pool_id TEXT NULL,
  req_affection_level INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE npc_schedule_cfg IS 'NPC 行程配置（受时间槽与风格影响）。对应策划表 Cfg_Heroine_Schedule。';
CREATE INDEX idx_npc_schedule_cfg_lookup ON npc_schedule_cfg(npc_id, time_slot_code, style_tag_code);

CREATE TABLE gift_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name_key TEXT NOT NULL,
  cost_asset_id UUID NOT NULL REFERENCES asset(id),
  cost_amount NUMERIC(30, 10) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE gift_item IS '礼物定义（常规互动消耗，通常以 AERA 或 SOURCE 定价）。';

CREATE TABLE npc_gift_reaction_cfg (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  npc_id UUID NOT NULL REFERENCES npc(id) ON DELETE CASCADE,
  gift_item_id UUID NOT NULL REFERENCES gift_item(id) ON DELETE CASCADE,
  style_tag_code TEXT NOT NULL REFERENCES ref_style_tag(code),
  affection_add INT NOT NULL,
  sanity_recover NUMERIC(10, 4) NOT NULL DEFAULT 0,
  response_text_key TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (npc_id, gift_item_id, style_tag_code)
);

COMMENT ON TABLE npc_gift_reaction_cfg IS '礼物在不同风格下的反应与收益（好感/回 san）。';

CREATE TABLE player_npc_state (
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  npc_id UUID NOT NULL REFERENCES npc(id) ON DELETE CASCADE,
  affection_level INT NOT NULL DEFAULT 0,
  affection_points INT NOT NULL DEFAULT 0,
  mood_code TEXT NOT NULL DEFAULT 'NORMAL',
  last_interaction_at TIMESTAMPTZ NULL,
  consecutive_missed_days INT NOT NULL DEFAULT 0,
  npc_hidden_sanity NUMERIC(10, 4) NOT NULL DEFAULT 100.0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (player_id, npc_id)
);

COMMENT ON TABLE player_npc_state IS '玩家- NPC 关系状态（好感度等级、连续冷落天数、黑化风险等）。';

CREATE TABLE player_npc_interaction (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id) ON DELETE CASCADE,
  npc_id UUID NOT NULL REFERENCES npc(id) ON DELETE CASCADE,
  interaction_type_code TEXT NOT NULL REFERENCES ref_npc_interaction_type(code),
  time_slot_code TEXT NOT NULL REFERENCES ref_time_slot(code),
  world_date DATE NOT NULL REFERENCES world_day(world_date) ON DELETE RESTRICT,
  style_tag_code TEXT NOT NULL REFERENCES ref_style_tag(code),
  cost_asset_id UUID NULL REFERENCES asset(id),
  cost_amount NUMERIC(30, 10) NOT NULL DEFAULT 0,
  affection_delta INT NOT NULL DEFAULT 0,
  sanity_delta NUMERIC(10, 4) NOT NULL DEFAULT 0,
  related_gift_id UUID NULL REFERENCES gift_item(id),
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE player_npc_interaction IS '互动流水（聊天/送礼/约会/心智覆写），用于结算与剧情触发审计。';
CREATE INDEX idx_player_npc_interaction_player_time ON player_npc_interaction(player_id, created_at DESC);

COMMIT;
