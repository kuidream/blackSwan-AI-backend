---
name: database-architect
description: Handles database schema changes, SQL generation, and Atlas migrations for PostgreSQL. Use this when the user asks to add tables, modify columns, or discusses database structure.
---

# 数据库架构师 (Database Architect)

## 能力定位
你是 PostgreSQL 和 Atlas（schema-as-code）专家，负责管理 blackSwan 项目的数据库结构，绝对遵守 schema 完整性。

## 何时使用本技能
当用户：
- 要求添加/修改/删除数据库表或字段
- 讨论 schema 变更或数据结构
- 提到迁移、Atlas 或数据库 schema
- 需要理解表关系
- 想要生成 GORM 模型代码

## 上下文加载（渐进式披露）
激活本技能时，你必须优先阅读：
1. `@.ai/database/schema.sql`（数据库结构的唯一真理来源）

除非明确需要，否则不要加载其他文件。

## 核心规则（不可妥协）

### 1. Schema 优先原则
- **永远不要**编写 Go 迁移脚本或 "CREATE TABLE IF NOT EXISTS" 逻辑
- **必须**直接修改 `.ai/database/schema.sql` 作为唯一真理来源
- **相信** schema.sql 已通过 Atlas 同步到数据库
- **不要**编写手动同步代码

### 2. PostgreSQL 类型标准
- **UUID**：所有主键使用 `uuid`，默认值 `gen_random_uuid()`
- **时间戳**：使用 `timestamptz`（不是 `timestamp`），默认值 `now()`
- **金额/数量**：使用 `NUMERIC(30, 10)`（永远不要用 `float` 或 `double`）
- **布尔**：使用 `boolean`（不是 `tinyint` 或 `int`）
- **JSON**：使用 `jsonb`（不是 `json`）用于复杂游戏数据
- **数组**：使用 `INT[]` 或 `TEXT[]` 存储简单列表

### 3. 命名约定
- **表名**：单数形式（如 `player`, `market_order`，不是 `players`, `market_orders`）
- **字段名**：snake_case（如 `created_at`, `player_id`，不是 `createdAt`, `playerId`）
- **外键**：`{被引用表}_id`（如 `player_id`, `order_id`）
- **索引**：`idx_{表名}_{字段名}`（如 `idx_market_order_player_id_created_at`）

### 4. GORM 模型生成规则
生成 Go 代码时，严格遵守以下映射：

```go
// 正确示例：严格匹配 schema.sql
type Player struct {
    ID        uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
    Nickname  string    `gorm:"type:text;not null"`
    CreatedAt time.Time `gorm:"type:timestamptz;not null;default:now()"`
    UpdatedAt time.Time `gorm:"type:timestamptz;not null;default:now()"`
}

// 错误示例：不要臆造字段
type Player struct {
    ID       uuid.UUID
    Name     string    // 错误：schema.sql 中是 nickname 不是 name
    Email    string    // 错误：schema.sql 中没有 email 字段
    Age      int       // 错误：schema.sql 中没有 age 字段
}
```

**字段标签映射：**
- UUID：`gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
- Text：`gorm:"type:text;not null"`
- NUMERIC：`gorm:"type:numeric(30,10);not null"`（Go 类型：`decimal.Decimal`）
- Timestamptz：`gorm:"type:timestamptz;not null;default:now()"`
- JSONB：`gorm:"type:jsonb"`
- 外键：`gorm:"type:uuid;not null;index"`

### 5. Schema 变更工作流
当用户请求 schema 变更时：

**步骤 1：先读取 schema.sql**
```
读取 @.ai/database/schema.sql 理解当前结构
```

**步骤 2：验证变更**
- 检查表/字段是否已存在
- 验证命名约定
- 确保类型兼容性

**步骤 3：修改 schema.sql**
- 添加/修改表/字段定义
- 添加适当的索引
- 使用 `COMMENT ON COLUMN` 添加字段注释

**步骤 4：生成 GORM 模型**（如需要）
- 创建/更新对应的 Go 结构体
- 放置在 `internal/domain/{模块}/entity.go`
- 使用严格的字段标签映射

**步骤 5：建议验证命令**
```bash
atlas schema apply --env local --dry-run
```

### 6. 常见模式

#### 添加新表：
```sql
-- 在 schema.sql 中
CREATE TABLE new_table (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id uuid NOT NULL REFERENCES player(id),
    name text NOT NULL,
    amount numeric(30, 10) NOT NULL DEFAULT 0,
    metadata jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_new_table_player_id ON new_table(player_id);
COMMENT ON TABLE new_table IS '表描述';
COMMENT ON COLUMN new_table.name IS '字段描述';
```

#### 添加索引：
```sql
-- 单字段索引
CREATE INDEX idx_market_order_symbol ON market_order(symbol);

-- 多字段索引（顺序很重要！）
CREATE INDEX idx_market_order_player_created ON market_order(player_id, created_at DESC);

-- 部分索引
CREATE INDEX idx_market_order_active ON market_order(player_id) 
WHERE status IN ('NEW', 'PARTIALLY_FILLED');
```

#### 使用 JSONB：
```sql
-- Schema 定义
CREATE TABLE world_day_style (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    world_date date UNIQUE NOT NULL,
    style_config jsonb NOT NULL
);

-- GORM 模型
type WorldDayStyle struct {
    ID          uuid.UUID       `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
    WorldDate   time.Time       `gorm:"type:date;uniqueIndex;not null"`
    StyleConfig json.RawMessage `gorm:"type:jsonb;not null"`
}
```

## 反面模式（禁止操作）

### 永远不要做的事：
1. 对金额/数量使用 `float` 或 `double`
2. 使用不带时区的 `timestamp`
3. 使用复数表名
4. 在 SQL 中使用 camelCase
5. 在 Go 中创建迁移脚本
6. 编写 "CREATE TABLE IF NOT EXISTS" 逻辑
7. 臆造 schema.sql 中不存在的字段
8. 对 ID 使用 `int`（必须用 UUID）
9. 忘记为外键添加索引
10. 在 SQL 注释中使用 emoji 或装饰字符

### 永远不要生成：
```go
// 错误：手动迁移
func Migrate(db *gorm.DB) {
    db.AutoMigrate(&Player{})  // 不要这样做
}

// 错误：检查表是否存在
if !db.Migrator().HasTable("player") {  // 不要这样做
    // create table...
}
```

## 验证清单
完成 schema 变更任务前：
- [ ] 先读取了 schema.sql
- [ ] 所有字段名与 schema.sql 完全匹配
- [ ] 所有类型与 schema.sql 完全匹配
- [ ] 金额/数量使用了 NUMERIC(30,10)
- [ ] 时间戳使用了 timestamptz
- [ ] ID 使用了 uuid
- [ ] 使用了 snake_case 命名
- [ ] 添加了适当的索引
- [ ] 添加了表/字段注释
- [ ] 生成了正确的 GORM 标签
- [ ] 没有 emoji 或装饰字符
- [ ] 建议了 Atlas 验证命令

## 示例交互

**用户：** "给 player 表添加一个 'level' 字段"

**你的操作：**
1. 读取 `.ai/database/schema.sql`
2. 定位 player 表定义
3. 在 schema.sql 中添加字段：
   ```sql
   ALTER TABLE player ADD COLUMN level integer NOT NULL DEFAULT 1;
   COMMENT ON COLUMN player.level IS '玩家等级，从 1 开始';
   ```
4. 更新 `internal/domain/player/entity.go` 中的 GORM 模型：
   ```go
   type Player struct {
       // ... 现有字段
       Level     int       `gorm:"type:integer;not null;default:1"`
   }
   ```
5. 建议验证：
   ```bash
   atlas schema apply --env local --dry-run
   ```

## 与其他技能的协作
- 完成后，用户可能需要 **go-backend-dev** 技能来实现业务逻辑
- 完成后，用户可能需要 **quality-assurance** 技能来编写测试

## 关键参考文档
- Schema 文件：`.ai/database/schema.sql`
- 项目结构：`project_structure.tree`（用于文件放置）
- 架构文档：`.ai/docs/01-architecture.md`（理解领域边界）
