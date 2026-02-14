# blackSwan AI Backend - Agent Skills 使用指南

## 技能体系概览

本项目为 blackSwan 游戏后端建立了 4 个专业 Agent Skills，每个技能专注于特定领域，确保 AI 助手在不同场景下提供最精准的帮助。

```
.cursor/skills/
├── database-architect/    # 数据库架构师
├── go-backend-dev/        # Go 后端开发专家
├── quality-assurance/     # 质检员
└── project-navigator/     # 项目导航员
```

## 技能详解

### 1. 数据库架构师 (database-architect)

**定位：** 数据库 Schema 变更和 Atlas 迁移的专家

**何时使用：**
- 需要添加/修改/删除数据库表或字段
- 生成 GORM 模型代码
- 理解表关系和数据结构
- 执行 Schema 迁移

**核心原则：**
- `.ai/database/schema.sql` 是唯一真理来源
- 严格遵守 PostgreSQL 类型标准
- 金额必须使用 NUMERIC(30,10)
- 时间戳必须使用 timestamptz
- 所有 ID 使用 UUID

**使用示例：**
```
用户：给 player 表添加一个 level 字段

AI 会：
1. 读取 schema.sql
2. 修改 schema.sql 添加字段
3. 生成对应的 GORM 模型
4. 建议运行 Atlas 验证命令
```

### 2. Go 后端开发专家 (go-backend-dev)

**定位：** 实现业务逻辑和 API 端点的专家

**何时使用：**
- 实现 API 接口
- 编写业务逻辑
- 创建 Handler/Usecase/Repository 代码
- 处理 HTTP 请求和响应

**核心原则：**
- 严格遵守分层架构（Handler → Usecase → Repository → Domain）
- API 响应必须符合 `api-reference.md` 契约
- 所有写操作支持幂等性
- 金额使用 decimal.Decimal
- 禁止使用 emoji 和装饰符号

**使用示例：**
```
用户：实现 IoT 数据同步接口

AI 会：
1. 读取 API 文档了解接口定义
2. 读取业务文档理解逻辑
3. 创建 DTO、Handler、Usecase、Repository
4. 遵守统一响应格式
5. 实现幂等性支持
```

### 3. 质检员 (quality-assurance)

**定位：** 代码测试和质量审查的专家

**何时使用：**
- 编写单元测试
- 审查代码质量
- 发现并发问题
- 检查 N+1 查询
- 修复 bug

**核心原则：**
- 必须使用表驱动测试
- 检查并发安全（Race Condition）
- 检查 N+1 查询问题
- 验证事务边界
- 确保金额计算精度

**使用示例：**
```
用户：帮我测试这个下单功能

AI 会：
1. 审查代码找出潜在问题
2. 生成表驱动测试用例
3. 检查并发安全
4. 检查事务完整性
5. 提供改进建议
```

### 4. 项目导航员 (project-navigator)

**定位：** 项目架构和文档导航的专家

**何时使用：**
- 询问"XXX 功能在哪里？"
- 理解项目架构设计
- 不确定代码应该放在哪个目录
- 需要了解模块间关系
- 查找相关文档

**核心原则：**
- 不编写实现代码，只提供导航
- 解释架构设计决策
- 指导文件放置位置
- 引用具体文档路径

**使用示例：**
```
用户：用户登录逻辑在哪里？

AI 会：
1. 定位相关文件路径
2. 解释各层职责
3. 说明数据流向
4. 引用相关文档
```

## 技能协作流程

### 场景 1：添加新功能

```
1. 使用 project-navigator
   → 理解功能应该放在哪里
   → 查看相关文档

2. 使用 database-architect
   → 设计数据库表结构
   → 生成 GORM 模型

3. 使用 go-backend-dev
   → 实现业务逻辑
   → 创建 API 端点

4. 使用 quality-assurance
   → 编写测试用例
   → 审查代码质量
```

### 场景 2：修复 Bug

```
1. 使用 project-navigator
   → 定位问题代码位置

2. 使用 quality-assurance
   → 审查代码找出问题
   → 建议修复方案

3. 使用 go-backend-dev
   → 修复业务逻辑

4. 使用 quality-assurance
   → 添加回归测试
```

### 场景 3：重构代码

```
1. 使用 project-navigator
   → 理解当前架构
   → 确认重构范围

2. 使用 quality-assurance
   → 编写测试保护现有功能

3. 使用 go-backend-dev
   → 执行重构

4. 使用 quality-assurance
   → 验证测试通过
```

## 如何触发技能

### 方式 1：明确指定技能
```
请使用 database-architect 技能帮我添加一个订单表
```

### 方式 2：自然语言（AI 自动识别）
```
给 player 表添加 level 字段
→ AI 自动激活 database-architect

实现 IoT 数据同步接口
→ AI 自动激活 go-backend-dev

帮我测试这段代码
→ AI 自动激活 quality-assurance

登录逻辑在哪里？
→ AI 自动激活 project-navigator
```

## 文档体系

所有技能都依赖统一的文档体系：

```
.ai/
├── database/
│   └── schema.sql              # 数据库唯一真源
├── api/
│   └── api-reference.md       # API 契约唯一真源
└── docs/
    ├── 01-architecture.md     # 架构总览
    ├── 02-world-setting.md    # 世界观设定
    ├── 03-time-mapping.md     # 时空映射
    ├── 04-market-mechanism.md # 市场机制
    ├── 05-tech-implementation.md # 技术实现
    ├── 06-economy-model.md    # 经济模型
    └── modules/               # 模块详细文档
```

## 核心规则

### 单一事实来源 (SSOT)
- 数据库结构：`.ai/database/schema.sql`
- API 契约：`.ai/api/api-reference.md`
- 项目结构：`project_structure.tree`
- 编码规范：`.cursorrules`

### 铁律
1. **禁止使用 emoji 和装饰符号**
2. **金额必须使用 NUMERIC/decimal，禁止 float**
3. **严格遵守分层架构，避免循环依赖**
4. **所有写操作必须支持幂等性**
5. **数据库字段必须与 schema.sql 完全一致**
6. **API 响应必须与 api-reference.md 完全一致**

## 技能维护

### 更新技能
编辑对应的 `SKILL.md` 文件：
```bash
.cursor/skills/{skill-name}/SKILL.md
```

### 添加新技能
1. 创建新目录：`.cursor/skills/{new-skill}/`
2. 创建 `SKILL.md` 文件
3. 遵循现有技能的格式：
   ```yaml
   ---
   name: skill-name
   description: Brief description
   ---
   
   # 技能名称
   
   ## 能力定位
   ## 何时使用本技能
   ## 上下文加载
   ## 核心规则
   ...
   ```

## 最佳实践

### 1. 渐进式披露
技能应该按需加载文档，不要一次性加载所有内容：
- ✅ 先读核心文档（schema.sql, api-reference.md）
- ✅ 根据任务按需加载其他文档
- ❌ 不要一开始就加载所有文档

### 2. 明确职责边界
- database-architect：只管 Schema，不写业务逻辑
- go-backend-dev：只写实现，不设计 Schema
- quality-assurance：只测试和审查，不实现功能
- project-navigator：只导航和解释，不写代码

### 3. 引用具体路径
回答时总是引用具体的文件路径：
- ✅ "请查看 `.ai/api/api-reference.md` 第 82 行"
- ❌ "请查看 API 文档"

### 4. 遵守编码规范
所有生成的代码必须遵守 `.cursorrules` 中的规范：
- 使用 snake_case（SQL/数据库）
- 使用 camelCase（Go 变量）
- 使用 PascalCase（Go 类型）
- 禁止 emoji
- 简洁注释

## 故障排除

### 问题：AI 没有使用正确的技能
**解决：** 明确指定技能名称
```
请使用 database-architect 技能...
```

### 问题：AI 加载了不必要的文档
**解决：** 在技能的"上下文加载"部分优化加载策略

### 问题：技能之间的建议冲突
**解决：** 参考优先级
```
schema.sql > api-reference.md > 模块文档 > 其他
```

## 总结

这套 Agent Skills 体系通过明确的职责划分和协作机制，确保 AI 助手能够：
1. **精准定位**：快速找到正确的代码和文档位置
2. **规范输出**：生成符合项目标准的高质量代码
3. **质量保证**：通过测试和审查确保代码健壮性
4. **架构一致**：保持项目架构的清晰和可维护性

使用这些技能时，记住：**每个技能都是专家，相互协作完成复杂任务。**
