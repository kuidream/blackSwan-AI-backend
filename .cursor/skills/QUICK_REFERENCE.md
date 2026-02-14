# Agent Skills 快速参考卡

## 我应该使用哪个技能？

### 📊 数据库相关 → `database-architect`

**触发关键词：**
- "添加/修改/删除 表/字段"
- "schema"
- "数据库结构"
- "GORM 模型"
- "迁移/migration"

**典型任务：**
```
✓ 给 player 表添加 level 字段
✓ 创建一个新的订单表
✓ 修改 balance 表的字段类型
✓ 生成 GORM 模型代码
✓ 设计表关系和索引
```

**关键原则：**
- 只修改 `.ai/database/schema.sql`
- 严禁臆造字段
- 金额用 NUMERIC(30,10)
- ID 用 UUID

---

### 💻 业务实现 → `go-backend-dev`

**触发关键词：**
- "实现 XXX 功能/接口"
- "创建 API"
- "Handler/Usecase/Repository"
- "业务逻辑"
- "路由"

**典型任务：**
```
✓ 实现 IoT 数据同步接口
✓ 创建下单 API
✓ 编写订单撮合逻辑
✓ 实现 JWT 认证中间件
✓ 添加 WebSocket 推送
```

**关键原则：**
- 遵守分层架构
- 严格按 API 文档实现
- 支持幂等性
- 使用 decimal 处理金额

---

### 🧪 测试审查 → `quality-assurance`

**触发关键词：**
- "测试"
- "审查/review"
- "bug"
- "单元测试"
- "代码质量"

**典型任务：**
```
✓ 帮我测试这个下单功能
✓ 审查这段代码有没有问题
✓ 检查并发安全
✓ 生成测试用例
✓ 发现 N+1 查询问题
```

**关键原则：**
- 使用表驱动测试
- 检查并发安全
- 验证事务边界
- 确保金额精度

---

### 🗺️ 架构导航 → `project-navigator`

**触发关键词：**
- "在哪里？"
- "架构"
- "应该放在哪个目录？"
- "模块关系"
- "设计决策"

**典型任务：**
```
✓ 登录逻辑在哪里？
✓ 这个功能应该放在哪个目录？
✓ 解释一下分层架构
✓ Handler 和 Usecase 的职责是什么？
✓ 如何组织新功能的代码？
```

**关键原则：**
- 只导航，不实现
- 引用具体路径
- 解释设计理由
- 指引正确方向

---

## 技能协作示例

### 场景：实现"购买内幕消息"功能

```
步骤 1：project-navigator
问：这个功能应该怎么组织代码？
答：→ 告诉你文件结构和职责划分

步骤 2：database-architect
问：需要什么表结构？
答：→ 设计 shop_purchase 表，生成 GORM 模型

步骤 3：go-backend-dev
问：实现购买接口
答：→ 创建 Handler/Usecase/Repository 代码

步骤 4：quality-assurance
问：测试这个功能
答：→ 生成测试用例，审查代码质量
```

---

## 快速决策树

```
我的问题是...

├─ 数据库相关？
│  └─ YES → database-architect
│
├─ 需要实现功能？
│  └─ YES → go-backend-dev
│
├─ 需要测试/审查？
│  └─ YES → quality-assurance
│
└─ 不知道从哪开始？
   └─ YES → project-navigator
```

---

## 常见误区

### ❌ 错误使用
```
用 go-backend-dev 修改数据库
→ 应该用 database-architect

用 database-architect 实现 API
→ 应该用 go-backend-dev

用 quality-assurance 实现功能
→ 应该先用 go-backend-dev，再用 quality-assurance 测试
```

### ✅ 正确使用
```
不确定从哪开始
→ 先用 project-navigator 导航

要添加新功能
→ project-navigator → database-architect → go-backend-dev → quality-assurance

要修复 bug
→ project-navigator 定位 → quality-assurance 审查 → go-backend-dev 修复
```

---

## 技能特点对比

| 技能 | 写代码？ | 修改数据库？ | 生成测试？ | 解释架构？ |
|-----|---------|------------|----------|----------|
| database-architect | ✓ (GORM) | ✓ | ✗ | ✗ |
| go-backend-dev | ✓ | ✗ | ✗ | ✗ |
| quality-assurance | ✗ | ✗ | ✓ | ✗ |
| project-navigator | ✗ | ✗ | ✗ | ✓ |

---

## 使用技巧

### 1. 明确指定技能
```
请使用 database-architect 技能帮我...
```

### 2. 自然语言（AI 自动识别）
```
给 player 表添加字段
→ AI 自动选择 database-architect

实现登录接口
→ AI 自动选择 go-backend-dev
```

### 3. 链式使用
```
先用 project-navigator 告诉我架构，
然后用 go-backend-dev 实现功能，
最后用 quality-assurance 生成测试
```

---

## 紧急救援

### "我完全不知道从哪开始..."
→ **使用 project-navigator**
它会告诉你：
- 相关代码在哪里
- 需要修改哪些文件
- 应该使用哪个技能

### "我的代码有问题但不知道哪里错了..."
→ **使用 quality-assurance**
它会检查：
- 并发安全问题
- N+1 查询
- 事务边界
- 金额精度

### "数据库报错/字段不匹配..."
→ **使用 database-architect**
它会：
- 检查 schema.sql
- 验证字段类型
- 修正 GORM 模型

### "不知道怎么实现某个功能..."
→ **使用 go-backend-dev**
它会：
- 读取 API 文档
- 生成标准代码
- 遵守架构规范

---

## 记住这些原则

1. **每个技能都是专家**，专注于自己的领域
2. **技能会协作**，一个任务可能需要多个技能
3. **先导航后实现**，不确定时先用 project-navigator
4. **实现后必测试**，用 quality-assurance 保证质量
5. **遵守单一职责**，不要让一个技能做它不擅长的事

---

**详细文档：** `.cursor/skills/README.md`
