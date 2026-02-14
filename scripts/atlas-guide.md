# Atlas 数据库迁移工具使用指南

## 问题解决: atlas 命令不可用

已解决。Atlas CLI 工具已下载到项目根目录 (`atlas.exe`)。

## Atlas 配置文件

已创建 `atlas.hcl` 配置文件,包含以下环境:

- `local`: 本地开发环境
- `prod`: 生产环境(示例)

## 使用前准备

### 1. 确保 PostgreSQL 正在运行

**检查数据库状态**:
```powershell
# Windows - 检查 PostgreSQL 服务状态
Get-Service | Where-Object {$_.Name -like "*postgres*"}

# 启动 PostgreSQL 服务
net start postgresql-x64-14  # 根据你的版本号调整
```

**使用 Docker**:
```bash
# 启动 PostgreSQL 容器
docker run --name blackswan-postgres \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=blackswan \
  -p 5432:5432 \
  -d postgres:15

# 验证容器运行状态
docker ps | grep blackswan-postgres
```

### 2. 配置数据库连接

编辑 `atlas.hcl` 文件,修改 `local` 环境的数据库连接字符串:

```hcl
env "local" {
  src = "file://.ai/database/schema.sql"
  
  // 修改这里的连接信息
  url = "postgres://用户名:密码@主机:端口/数据库名?sslmode=disable"
}
```

例如:
```
url = "postgres://postgres:mypassword@localhost:5432/blackswan?sslmode=disable"
```

## Atlas 常用命令

### 1. 检查 Schema 变更 (Dry Run)

查看将要应用的变更,但不实际执行:

```powershell
# 使用相对路径(项目根目录)
.\atlas.exe schema apply --env local --dry-run

# 如果 atlas.exe 在 PATH 中
atlas schema apply --env local --dry-run
```

### 2. 应用 Schema 变更

实际执行数据库变更:

```powershell
.\atlas.exe schema apply --env local
```

### 3. 检查当前 Schema 状态

```powershell
.\atlas.exe schema inspect --env local
```

### 4. 查看 Schema 差异

```powershell
.\atlas.exe schema diff --from "postgres://..." --to "file://.ai/database/schema.sql"
```

## 开发工作流

### 修改数据库结构的标准流程

1. **修改 Schema 文件**:
   ```bash
   # 编辑单一真理来源
   .ai/database/schema.sql
   ```

2. **查看变更预览**:
   ```powershell
   .\atlas.exe schema apply --env local --dry-run
   ```

3. **确认变更后应用**:
   ```powershell
   .\atlas.exe schema apply --env local
   ```

4. **更新 GORM 模型**:
   - 根据 schema.sql 的变更,同步更新 Go 代码中的 GORM 模型
   - 确保字段名、类型、约束完全一致

## 常见问题

### 问题 1: atlas 命令不可用

**错误**:
```
atlas : 无法将"atlas"项识别为 cmdlet、函数、脚本文件或可运行程序的名称
```

**解决方案**:
已解决。使用 `.\atlas.exe` (相对路径) 或将 atlas.exe 添加到系统 PATH。

### 问题 2: 连接数据库失败

**错误**:
```
Error: postgres: querying system variables: dial tcp [::1]:5432: connectex: 
No connection could be made because the target machine actively refused it.
```

**解决方案**:
1. 检查 PostgreSQL 是否运行: `Get-Service | Where-Object {$_.Name -like "*postgres*"}`
2. 检查端口是否正确: `netstat -ano | findstr :5432`
3. 检查 atlas.hcl 中的连接配置是否正确

### 问题 3: SQL 语法错误

**错误**:
```
Error: parsing schema: syntax error at line XX
```

**解决方案**:
检查 `.ai/database/schema.sql` 文件的 SQL 语法,确保兼容 PostgreSQL。

### 问题 4: 权限不足

**错误**:
```
Error: postgres: permission denied for database
```

**解决方案**:
确保连接字符串中的用户具有 CREATE/ALTER/DROP 权限。

## 将 Atlas 添加到 PATH (可选)

如果希望直接使用 `atlas` 命令而不是 `.\atlas.exe`:

### Windows PowerShell:
```powershell
# 临时添加(当前会话)
$env:Path += ";F:\MCP\blackSwan-AI-backend"

# 永久添加(需要管理员权限)
[Environment]::SetEnvironmentVariable(
  "Path",
  [Environment]::GetEnvironmentVariable("Path", "User") + ";F:\MCP\blackSwan-AI-backend",
  "User"
)
```

### 或者移动到系统目录:
```powershell
# 需要管理员权限
Copy-Item .\atlas.exe -Destination C:\Windows\System32\
```

## 参考资源

- Atlas 官方文档: https://atlasgo.io/
- blackSwan Schema 文件: `.ai/database/schema.sql`
- 项目开发规范: `.cursorrules`
