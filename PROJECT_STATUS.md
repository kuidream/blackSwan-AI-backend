# 项目状态

## 基础骨架搭建完成

### 已完成的工作

#### 1. 文档整理
- [x] 创建 `.ai/` 目录结构
- [x] 整理所有核心文档到 `.ai/docs/`
- [x] 整理模块文档到 `.ai/docs/modules/`
- [x] 复制 SQL Schema 到 `.ai/database/schema.sql`
- [x] 复制 API 文档到 `.ai/api/api-reference.md`
- [x] 创建开发规范 `.ai/README.md`

#### 2. 规则配置
- [x] 创建 `.cursorrules` 文件（Cursor IDE 规则）
- [x] 创建 `AGENTS.md` 文件（AI 助手指南）
- [x] 定义三大核心铁律：
  - 数据库真理（schema.sql）
  - 接口契约（api-reference.md）
  - 工程结构（project_structure.tree）

#### 3. 项目骨架
- [x] 创建完整的目录结构
- [x] 创建 `go.mod` 和依赖配置
- [x] 创建 `cmd/api/main.go`（含优雅关机）
- [x] 创建 `internal/config/config.go`（配置管理）
- [x] 创建 `internal/transport/http/router.go`（Gin 路由）
- [x] 创建基础 DTO 和错误定义
- [x] 创建 `.env.example` 配置模板
- [x] 创建 `.gitignore` 文件
- [x] 创建启动脚本（run.sh / run.ps1）
- [x] 创建 Makefile
- [x] 更新 README.md

### 当前可用功能

服务可以成功启动并响应以下接口:

```bash
# 健康检查
GET /health

# 测试接口
GET /v1/ping
```

## 待实现功能

### 高优先级

#### 1. 基础设施层 (Infra)
- [ ] 数据库连接池和 GORM 初始化
- [ ] Redis 客户端封装
- [ ] 结构化日志系统（zap）
- [ ] 中间件实现（RequestID, Logger, Recovery, CORS）

#### 2. 认证系统 (Auth)
- [ ] JWT Token 生成和验证
- [ ] Login/Refresh/Logout 接口
- [ ] 认证中间件

#### 3. 玩家系统 (Player)
- [ ] Player 领域模型
- [ ] Balance 余额管理
- [ ] Ledger 流水记录
- [ ] PlayerRepository 实现

### 中优先级

#### 4. IoT 系统
- [ ] IoT 数据同步接口
- [ ] 防作弊校验逻辑
- [ ] 源点奖励计算
- [ ] 风格加成应用

#### 5. 世界演进系统
- [ ] 每日风格生成定时任务
- [ ] LLM 客户端封装
- [ ] 风格配置缓存
- [ ] 容错和兜底机制

#### 6. 市场系统
- [ ] Ticker Engine（价格演算引擎）
- [ ] WebSocket Hub（行情推送）
- [ ] 订单撮合逻辑
- [ ] 持仓管理

### 低优先级

#### 7. San 值系统
- [ ] San 值计算逻辑
- [ ] 状态机实现
- [ ] 强制平仓机制

#### 8. 商店系统
- [ ] 商品购买接口
- [ ] 冷却时间管理
- [ ] 技能效果应用

#### 9. NPC 互动系统
- [ ] 好感度计算
- [ ] 行程查询
- [ ] 互动处理
- [ ] 心智覆写

## 开发顺序建议

### Sprint 1: 基础功能（1-2周）
1. 完成数据库和 Redis 连接
2. 实现认证系统（Login/Logout）
3. 实现玩家基础信息查询
4. 实现余额查询

### Sprint 2: IoT 系统（1周）
1. 实现 IoT 数据同步接口
2. 实现防作弊校验
3. 实现源点奖励计算
4. 集成测试

### Sprint 3: 世界演进（1周）
1. 实现每日风格生成
2. 接入 LLM API
3. 实现风格配置下发
4. 测试演进机制

### Sprint 4: 市场系统（2周）
1. 实现 Ticker Engine
2. 实现 WebSocket 推送
3. 实现订单系统
4. 实现持仓管理
5. 压力测试

### Sprint 5: San 值和商店（1周）
1. 实现 San 值系统
2. 实现商店购买
3. 实现技能效果

### Sprint 6: NPC 系统（1周）
1. 实现好感度系统
2. 实现互动逻辑
3. 实现剧情触发

## 技术债务追踪

### 待优化
- [ ] 添加单元测试覆盖
- [ ] 添加集成测试
- [ ] 性能压测和优化
- [ ] 添加 OpenAPI/Swagger 文档
- [ ] 实现监控和告警
- [ ] 添加 Docker 支持
- [ ] CI/CD 配置

### 待决策
- [ ] 日志库选择（zap vs logrus vs slog）
- [ ] 依赖注入工具（手写 vs wire）
- [ ] 数据库迁移工具（Atlas vs golang-migrate）
- [ ] WebSocket 库（gorilla vs nhooyr）

## 环境要求

### 开发环境
- Go 1.21+
- PostgreSQL 14+
- Redis 6+
- Git

### 推荐工具
- Cursor IDE（已配置 .cursorrules）
- TablePlus / DataGrip（数据库管理）
- Postman / Bruno（API 测试）
- Redis Insight（Redis 管理）

## 注意事项

### 开发前必读
1. `.cursorrules` - Cursor IDE 规则
2. `AGENTS.md` - AI 助手指南
3. `.ai/README.md` - 完整开发规范
4. `.ai/database/schema.sql` - 数据库结构真理
5. `.ai/api/api-reference.md` - API 契约

### 三大铁律
1. 数据库字段必须严格匹配 schema.sql
2. API 接口必须严格遵守 api-reference.md
3. 代码必须放在正确的目录，遵守分层架构

### Schema 同步
- schema.sql 是唯一真理
- 严禁手动修改云端数据库
- 变更必须通过 Atlas 工具同步
- 代码中不需要检查表是否存在

## 获取帮助

遇到问题时:
1. 先查阅 `.ai/docs/` 相关文档
2. 检查是否违反三大铁律
3. 查看 `AGENTS.md` 中的常见问题
4. 提交 Issue 描述问题

## 最后更新

- 日期: 2026-02-02
- 状态: 基础骨架已完成，可开始业务开发
- 下一步: 实现数据库连接和认证系统
