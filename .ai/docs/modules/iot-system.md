# IoT 与资源映射系统详细设计

## 模块概述

本模块负责处理从物理世界 (Physical Layer) 到表世界 (Surface Layer) 的所有数据交互。

### 输入

智能设备(Apple Watch / Huawei / Android Wear)的三项基础数据: 步数、心率、睡眠

### 处理

经过【主神风格滤镜】的包装与【防作弊校验】

### 输出

玩家账户中的源点 (Source) 增加

## 数据标准与采集规则

不使用 MQTT 直连，而是采用"Native Bridge (原生桥接)"模式(mqtt太费电了)。

### 数据流向

```
Hardware Layer (The Chaos)
    Apple Watch
    小米手环
    Huawei Watch
    Garmin

    ↓ BLE / App Sync

OS Aggregation Layer (The Hub)
    iOS HealthKit
    Android Health Connect

    ↓ Native Plugin

Unity Client (Your Game)

    ↓ HTTPS/JSON

Golang Backend
```

### 核心数据定义

| 数据类型 | 数据源 (SDK Key) | 采集频率 | 有效性阈值 | 说明 |
|---------|----------------|---------|-----------|------|
| 步数 (Steps) | step_count | 每次启动/切回前台 | 0 ~ 100,000 /日 | 超过 10万步/日 标记为异常数据 |
| 心率 (HR) | heart_rate.avg | 每 10 分钟采样一次 | 40 ~ 220 bpm | 用于判定"冥想"或"爆发"状态 |
| 睡眠 (Sleep) | sleep.duration | 每日 08:00 后结算 | 0 ~ 24 小时 | 需包含 deep_sleep (深睡) 字段以计算暴击 |

### 数据同步逻辑

1. **冷启动/前台激活**: App 检查上次同步时间戳 (Last_Sync_Time)
2. **增量获取**: 调用 SDK (HealthKit/GoogleFit) 获取 Last_Sync_Time 到 Now 之间的新增数据
3. **本地缓存**: 客户端本地暂存，等待玩家点击"提取"或自动上传

## 资源产出公式

源点是游戏内的现金本金。产出公式必须严格控制通胀，同时保证玩家有动力去运动。

### 基础产出 (Base Yield)

```
产出源点 = (新增数据值 × 转化率) + 额外奖励
```

**步数转化**: 10 步 = 1 源点
- 例: 跑 5 公里(约 7000 步) = 700 源点(初始本金)

**日上限**: 每日步数奖励上限 2000 源点(防止摇步器刷钱)

### 风格化加成

根据每日 00:00 生成的 Daily_Style_Config，特定行为会有加成。

| 今日风格 | 加成行为 | 判定条件 | 加成系数 (Multiplier) |
|---------|---------|---------|---------------------|
| 修仙 (Xianxia) | 静息 (Meditation) | 任意连续 30分钟的心率 < 70 bpm | 额外 +300 源点 (每日限1次) |
| 赛博 (Cyber) | 充能 (Charge) | 睡眠时长 > 7 小时 | 结算系数 1.5x (睡眠奖励翻倍) |
| 末日 (Doom) | 逃生 (Sprint) | 任意 10分钟内步频 > 160 | 额外 +200 源点 (每日限3次) |

### 防作弊风控 (Anti-Cheat)

后端 IoT_Validator 服务需执行以下检查:

1. **速度物理墙**: 如果 (NewSteps - OldSteps) / TimeDelta > 5步/秒 且持续超过 1 分钟 → 判定为摇步器，该段数据无效
2. **时间旅行者**: 上传的时间戳晚于服务器当前时间 → 拒绝同步
3. **重复哈希**: 相同的数据包 Hash 被重复提交 → 丢弃

## 系统流程

```
玩家点击"提取能量"
    ↓
Unity 客户端 → 智能手表/手机SDK: Request Incremental Data (Since LastSync)
    ↓
智能手表/手机SDK → Unity 客户端: Return JSON {steps: 5000, hr: 80, ...}
    ↓
Unity 客户端: Pre-process (格式化)
    ↓
Unity 客户端 → Golang Backend: API: /api/iot/sync (Payload + Signature)
    ↓
Golang Backend: 防作弊校验 (速率/时间戳)
    ↓
    [校验通过]
    ↓
Golang Backend: 读取今日风格配置 (Redis)
    ↓
Golang Backend: 计算源点 = steps*rate * style_bonus
    ↓
Golang Backend → Database: Update User_Wallet (+500 Source)
    ↓
Golang Backend → Unity 客户端: Success {added: 500, total: 1500}
    ↓
    [校验失败]
    ↓
Golang Backend → Unity 客户端: Error {code: 1001, msg: "异常数据"}
    ↓
Unity 客户端: 播放"能量入账"动画
```

## API 接口设计

### POST /v1/iot/sync

#### Headers
```
Authorization: Bearer <access_token>
Idempotency-Key: <unique_key>
```

#### Request
```json
{
  "device": {
    "platform": "iOS",
    "vendor": "AppleWatch",
    "external_id": "string"
  },
  "client_ts": 1738029200,
  "since_ts": 1738020000,
  "metrics": {
    "steps": 7000,
    "heart_rate_avg": 80,
    "sleep": {
      "total_hours": 7.5,
      "deep_hours": 2.0
    }
  },
  "signature": {
    "alg": "HMAC-SHA256",
    "nonce": "string",
    "sig": "hex"
  }
}
```

#### Response (Success)
```json
{
  "request_id": "uuid",
  "server_time": 1738029283,
  "data": {
    "added_source": "700",
    "bonus_source": "300",
    "total_added_source": "1000",
    "balances": [
      {
        "asset": "SOURCE",
        "available": "1500",
        "locked": "0"
      }
    ],
    "anti_cheat": {
      "status": "PASS",
      "flags": []
    }
  }
}
```

#### Response (Error)
```json
{
  "request_id": "uuid",
  "server_time": 1738029283,
  "error": {
    "code": "INVALID_DATA",
    "message": "检测到异常数据",
    "details": {
      "flags": ["SPEED_VIOLATION"]
    }
  }
}
```

## 数据库设计

### player_device 表

```sql
CREATE TABLE player_device (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id),
  platform TEXT NOT NULL,
  vendor TEXT NULL,
  external_device_id TEXT NOT NULL,
  last_sync_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (player_id, external_device_id)
);
```

### iot_sync_batch 表

```sql
CREATE TABLE iot_sync_batch (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES player(id),
  device_id UUID NOT NULL REFERENCES player_device(id),
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
```

### iot_anti_cheat_flag 表

```sql
CREATE TABLE iot_anti_cheat_flag (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sync_batch_id UUID NOT NULL REFERENCES iot_sync_batch(id),
  flag_code TEXT NOT NULL,
  severity INT NOT NULL DEFAULT 1,
  detail TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## 实现示例

### 服务端验证逻辑

```go
type IoTSyncRequest struct {
    Device    DeviceInfo
    ClientTS  int64
    SinceTS   int64
    Metrics   MetricsData
    Signature SignatureInfo
}

func (s *IoTService) Sync(ctx context.Context, req *IoTSyncRequest) (*SyncResult, error) {
    // 1. 幂等性检查
    existing, err := s.repo.GetBatchByIdempotency(req.PlayerID, req.IdempotencyKey)
    if err == nil {
        return BuildResultFromBatch(existing), nil
    }
    
    // 2. 防作弊检查
    flags := s.validator.Validate(req)
    if len(flags) > 0 {
        // 记录风控标记
        s.repo.SaveAntiCheatFlags(req.PlayerID, flags)
        
        if HasCriticalFlag(flags) {
            return nil, ErrInvalidData
        }
    }
    
    // 3. 获取今日风格配置
    style, err := s.worldService.GetTodayStyle()
    if err != nil {
        return nil, err
    }
    
    // 4. 计算奖励
    baseReward := s.calculateBaseReward(req.Metrics)
    bonusReward := s.calculateBonusReward(req.Metrics, style)
    totalReward := baseReward + bonusReward
    
    // 5. 更新余额和记录流水
    err = s.walletService.AddBalance(req.PlayerID, "SOURCE", totalReward, "IOT_REWARD", batch.ID)
    if err != nil {
        return nil, err
    }
    
    // 6. 保存同步批次
    batch := &IoTSyncBatch{
        PlayerID:       req.PlayerID,
        AddedSource:    baseReward,
        BonusSource:    bonusReward,
        Status:         "SUCCESS",
    }
    s.repo.SaveBatch(batch)
    
    return BuildResult(batch), nil
}
```

### 客户端接入示例

```csharp
// Unity C# 示例
public class IoTService {
    public async Task<SyncResult> SyncData() {
        // 1. 从 HealthKit 读取数据
        var healthData = await HealthKitPlugin.GetIncrementalData(lastSyncTime);
        
        // 2. 构建请求
        var request = new IoTSyncRequest {
            Device = GetDeviceInfo(),
            ClientTS = DateTimeOffset.Now.ToUnixTimeSeconds(),
            SinceTS = lastSyncTime,
            Metrics = new MetricsData {
                Steps = healthData.Steps,
                HeartRateAvg = healthData.HeartRateAvg,
                Sleep = healthData.Sleep
            },
            Signature = SignData(healthData)
        };
        
        // 3. 发送请求
        var response = await ApiClient.Post("/v1/iot/sync", request);
        
        // 4. 更新本地状态
        lastSyncTime = DateTimeOffset.Now.ToUnixTimeSeconds();
        PlayerPrefs.SetInt("last_sync_time", (int)lastSyncTime);
        
        // 5. 播放动画
        UIManager.ShowSourceAddedAnimation(response.Data.TotalAddedSource);
        
        return response.Data;
    }
}
```

## UI/UX 交互逻辑

### 主界面仪表盘 (Main Dashboard)

- **状态**: 默认显示今日风格背景(如修仙风)
- **控件**: 一个巨大的圆环进度条，显示今日步数/目标
- **文案**: 不显示 "5000 步"，而是显示 "今日行军: 5000 里" (读取 Cfg_IoT_Mapping)

### 提取反馈 (Feedback)

**操作**: 玩家点击圆环中心的"提取"按钮

**动画**:
1. 数字滚动: 步数减少，源点增加
2. 粒子特效: 从圆环吸入能量到右上角的钱包
3. **暴击提示**: 如果触发了风格加成(如修仙日心率很低)，弹出特殊提示框:
   - "检测到道友心如止水，触发【冥想】加成! 额外获得 300 源点!"

### 异常处理

- **未授权**: 显示"未连接终端"，引导去系统设置开权限
- **作弊拦截**: 弹出红字警告: "检测到时空扰动(数据异常)，本次提取失败，请勿使用物理外挂。"

## 监控与优化

### 关键指标

- 同步请求成功率: > 99%
- 同步请求平均延迟: < 200ms
- 风控标记命中率: < 5%
- 数据有效率: > 95%

### 性能优化

- 使用 Redis 缓存今日风格配置
- 批量写入流水记录
- 异步处理风控检查
- 数据库连接池优化

## 下一步

查看相关文档:
- [世界观设定与源点经济学](../02-world-setting.md)
- [时空映射机制](../03-time-mapping.md)
- [AI 演进系统](./ai-evolution.md)
