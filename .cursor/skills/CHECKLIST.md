# Agent Skills 配置清单

## ✅ 配置验证

### 目录结构检查
```
.cursor/skills/
├── README.md                      ✓ 使用指南
├── QUICK_REFERENCE.md             ✓ 快速参考
├── CHECKLIST.md                   ✓ 本文件
├── database-architect/
│   └── SKILL.md                   ✓ 数据库架构师技能
├── go-backend-dev/
│   └── SKILL.md                   ✓ Go 后端开发技能
├── quality-assurance/
│   └── SKILL.md                   ✓ 质检员技能
└── project-navigator/
    └── SKILL.md                   ✓ 项目导航员技能
```

### 技能元数据检查

#### ✅ database-architect
- [x] name: database-architect
- [x] description: 简短英文描述
- [x] 中文标题：数据库架构师
- [x] 能力定位明确
- [x] 触发场景清晰
- [x] 上下文加载策略
- [x] 核心规则完整

#### ✅ go-backend-dev
- [x] name: go-backend-dev
- [x] description: 简短英文描述
- [x] 中文标题：Go 后端开发专家
- [x] 能力定位明确
- [x] 触发场景清晰
- [x] 上下文加载策略
- [x] 核心规则完整

#### ✅ quality-assurance
- [x] name: quality-assurance
- [x] description: 简短英文描述
- [x] 中文标题：质检员
- [x] 能力定位明确
- [x] 触发场景清晰
- [x] 上下文加载策略
- [x] 核心规则完整

#### ✅ project-navigator
- [x] name: project-navigator
- [x] description: 简短英文描述
- [x] 中文标题：项目导航员
- [x] 能力定位明确
- [x] 触发场景清晰
- [x] 上下文加载策略
- [x] 核心规则完整

---

## 📋 文档依赖验证

### 核心真理来源
- [x] `.ai/database/schema.sql` 存在
- [x] `.ai/api/api-reference.md` 存在
- [x] `project_structure.tree` 存在
- [x] `.cursorrules` 已简化并引用技能

### 架构文档
- [x] `.ai/docs/01-architecture.md`
- [x] `.ai/docs/02-world-setting.md`
- [x] `.ai/docs/03-time-mapping.md`
- [x] `.ai/docs/04-market-mechanism.md`
- [x] `.ai/docs/05-tech-implementation.md`
- [x] `.ai/docs/06-economy-model.md`

### 模块文档
- [x] `.ai/docs/modules/iot-system.md`
- [x] `.ai/docs/modules/market-system.md`
- [x] `.ai/docs/modules/sanity-system.md`
- [x] `.ai/docs/modules/npc-interaction.md`
- [x] `.ai/docs/modules/ai-evolution.md`

---

## 🎯 技能职责验证

### database-architect 只负责
- [x] 读取 schema.sql
- [x] 修改 schema.sql
- [x] 生成 GORM 模型
- [x] 验证数据库类型
- [x] ❌ 不实现业务逻辑
- [x] ❌ 不编写测试
- [x] ❌ 不创建 API 端点

### go-backend-dev 只负责
- [x] 读取 API 文档
- [x] 实现 Handler/Usecase/Repository
- [x] 遵守分层架构
- [x] 编写业务逻辑
- [x] ❌ 不修改 schema.sql
- [x] ❌ 不编写测试（由 QA 负责）
- [x] ❌ 不解释架构（由 Navigator 负责）

### quality-assurance 只负责
- [x] 审查代码质量
- [x] 生成测试用例
- [x] 检查并发安全
- [x] 发现性能问题
- [x] ❌ 不实现功能
- [x] ❌ 不修改数据库
- [x] ❌ 不设计架构

### project-navigator 只负责
- [x] 解释项目结构
- [x] 定位代码位置
- [x] 解释架构决策
- [x] 引导使用其他技能
- [x] ❌ 不编写代码
- [x] ❌ 不修改文件
- [x] ❌ 不实现功能

---

## 🔗 技能协作验证

### 场景：添加新功能
```
✓ project-navigator   定位代码位置
  ↓
✓ database-architect  设计数据表
  ↓
✓ go-backend-dev      实现业务逻辑
  ↓
✓ quality-assurance   编写测试
```

### 场景：修复 Bug
```
✓ project-navigator   定位问题代码
  ↓
✓ quality-assurance   审查找出原因
  ↓
✓ go-backend-dev      修复问题
  ↓
✓ quality-assurance   添加回归测试
```

### 场景：重构
```
✓ project-navigator   理解当前架构
  ↓
✓ quality-assurance   编写保护测试
  ↓
✓ go-backend-dev      执行重构
  ↓
✓ quality-assurance   验证测试通过
```

---

## 📚 文档引用验证

### database-architect 引用
- [x] `.ai/database/schema.sql`（主要）
- [x] `project_structure.tree`（文件放置）
- [ ] 其他（按需）

### go-backend-dev 引用
- [x] `.ai/api/api-reference.md`（主要）
- [x] `project_structure.tree`（主要）
- [x] `.ai/docs/01-architecture.md`（理解架构）
- [x] `.ai/docs/modules/*.md`（理解业务）

### quality-assurance 引用
- [x] 用户指定的代码文件（仅此）
- [ ] 不主动加载其他文档

### project-navigator 引用
- [x] `project_structure.tree`（主要）
- [x] `.cursorrules`（规范）
- [x] `README.md`（概览）
- [x] `.ai/docs/01-architecture.md`（架构）
- [ ] 其他（按需）

---

## 🚫 反面模式检查

### 禁止使用 emoji
- [x] 所有 SKILL.md 文件无 emoji
- [x] README.md 中仅在标题使用（可接受）
- [x] QUICK_REFERENCE.md 中仅在标题使用（可接受）

### 禁止循环依赖
- [x] database-architect 不调用 go-backend-dev
- [x] go-backend-dev 不调用 database-architect
- [x] quality-assurance 独立审查
- [x] project-navigator 只导航不实现

### 职责边界清晰
- [x] 没有技能越界操作
- [x] 每个技能有明确的"不要做"列表
- [x] 协作关系明确

---

## 🧪 测试技能

### 测试 database-architect
```
提问："给 player 表添加 level 字段"
预期：
✓ 读取 schema.sql
✓ 修改 schema.sql
✓ 生成 GORM 模型
✓ 建议 Atlas 验证命令
✓ 不实现业务逻辑
```

### 测试 go-backend-dev
```
提问："实现 IoT 数据同步接口"
预期：
✓ 读取 api-reference.md
✓ 创建 DTO
✓ 实现 Handler
✓ 实现 Usecase
✓ 实现 Repository
✓ 遵守分层架构
✓ 支持幂等性
```

### 测试 quality-assurance
```
提问："测试这个下单功能"
预期：
✓ 审查代码
✓ 生成表驱动测试
✓ 检查并发安全
✓ 检查事务边界
✓ 不实现功能
```

### 测试 project-navigator
```
提问："登录逻辑在哪里？"
预期：
✓ 定位文件位置
✓ 解释各层职责
✓ 说明数据流向
✓ 引用文档路径
✓ 不编写代码
```

---

## 📊 质量指标

### 技能完整性
- [x] 4 个核心技能全部创建
- [x] 每个技能有完整的 SKILL.md
- [x] 元数据格式正确
- [x] 中文正文清晰

### 文档完整性
- [x] README.md（详细指南）
- [x] QUICK_REFERENCE.md（快速参考）
- [x] CHECKLIST.md（本清单）
- [x] 简化的 .cursorrules

### 一致性
- [x] 所有技能使用统一格式
- [x] 命名规范一致
- [x] 引用路径一致
- [x] 编码规范一致

---

## 🔧 维护清单

### 定期检查（每月）
- [ ] 技能是否仍然适用当前架构
- [ ] 文档引用路径是否正确
- [ ] 是否有新的反面模式需要添加
- [ ] 示例代码是否过时

### 更新触发条件
- [ ] 项目结构发生重大变化
- [ ] 引入新的技术栈
- [ ] 发现技能职责不清
- [ ] 出现新的常见错误模式

### 扩展考虑
- [ ] 是否需要新的专业技能
- [ ] 是否需要拆分现有技能
- [ ] 是否需要合并某些技能

---

## ✨ 成功标准

技能体系成功运行的标志：

1. **AI 能自动选择正确的技能**
   - 用户不需要明确指定
   - 技能切换自然流畅

2. **生成的代码符合规范**
   - 无 emoji
   - 金额用 decimal
   - 遵守分层架构
   - API 符合契约

3. **文档引用准确**
   - 总是引用正确的文件
   - 路径完整准确
   - 按需加载，不过度

4. **职责边界清晰**
   - 不越界操作
   - 协作顺畅
   - 互相引导

5. **开发效率提升**
   - 减少重复劳动
   - 避免常见错误
   - 保持代码一致性

---

## 📞 问题排查

### 问题：AI 没有使用正确的技能
**排查步骤：**
1. 检查触发关键词是否在 SKILL.md 中
2. 明确指定技能名称
3. 查看 AI 的技能选择逻辑

### 问题：生成的代码不符合规范
**排查步骤：**
1. 检查技能的"核心规则"部分
2. 验证 .cursorrules 是否正确
3. 确认文档引用路径正确

### 问题：技能之间协作混乱
**排查步骤：**
1. 检查"与其他技能的协作"部分
2. 验证职责边界是否清晰
3. 查看是否有循环依赖

---

## 🎉 部署完成

如果你能看到这个文档，并且以上所有检查项都通过，那么：

**🎊 恭喜！blackSwan AI Backend 的 Agent Skills 体系已成功部署！**

现在你可以：
1. 阅读 `.cursor/skills/README.md` 了解详细用法
2. 参考 `.cursor/skills/QUICK_REFERENCE.md` 快速查询
3. 开始使用技能进行开发

**记住：** 每个技能都是专家，让它们做自己擅长的事！
