# PostgreSQL 本地安装指南

## 快速安装 PostgreSQL

### 方法 1: 使用官方安装程序（推荐）

1. **下载 PostgreSQL**
   - 访问: https://www.postgresql.org/download/windows/
   - 或直接下载: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
   - 推荐版本: PostgreSQL 15 或 16

2. **运行安装程序**
   - 双击下载的 `.exe` 文件
   - 安装路径: 默认 `C:\Program Files\PostgreSQL\15`
   - 组件选择: 全部勾选（PostgreSQL Server, pgAdmin, Command Line Tools）
   - 端口: 默认 5432
   - **重要**: 设置超级用户 (postgres) 密码并记住它

3. **验证安装**
   ```powershell
   # 检查服务
   Get-Service | Where-Object {$_.Name -like "*postgres*"}
   
   # 检查版本
   psql --version
   ```

4. **启动服务**
   ```powershell
   # 查看实际的服务名称
   Get-Service | Where-Object {$_.DisplayName -like "*postgres*"}
   
   # 启动服务（服务名可能是 postgresql-x64-15 或类似）
   net start postgresql-x64-15
   ```

### 方法 2: 使用 Chocolatey 包管理器

如果你安装了 Chocolatey:

```powershell
# 以管理员身份运行 PowerShell
choco install postgresql15
```

### 方法 3: 使用 Scoop 包管理器

如果你安装了 Scoop:

```powershell
scoop install postgresql
```

## 创建 blackswan 数据库

安装完成后，创建项目数据库：

### 方式 1: 使用 psql 命令行

```powershell
# 连接到 PostgreSQL（会提示输入密码）
psql -U postgres

# 在 psql 中执行
CREATE DATABASE blackswan;
\q
```

### 方式 2: 使用 pgAdmin

1. 打开 pgAdmin（安装时已包含）
2. 连接到 PostgreSQL 服务器
3. 右键 "Databases" -> "Create" -> "Database"
4. 数据库名: `blackswan`
5. 点击 "Save"

## 配置项目连接

1. **创建 .env 文件**
   ```powershell
   # 在项目根目录
   Copy-Item .env.example .env
   ```

2. **编辑 .env 文件**
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=postgres
   DB_PASSWORD=你设置的密码
   DB_NAME=blackswan
   DB_SSL_MODE=disable
   ```

3. **编辑 atlas.hcl 文件**
   ```hcl
   env "local" {
     src = "file://.ai/database/schema.sql"
     url = "postgres://postgres:你设置的密码@localhost:5432/blackswan?sslmode=disable"
   }
   ```

## 使用 Atlas 初始化数据库

```powershell
# 预览将要执行的 SQL
.\atlas.exe schema apply --env local --dry-run

# 实际应用 Schema
.\atlas.exe schema apply --env local
```

## 验证数据库

```powershell
# 连接到数据库
psql -U postgres -d blackswan

# 查看所有表
\dt

# 退出
\q
```

## 常见问题

### Q1: 忘记了 postgres 密码

**解决方案**:
1. 找到 PostgreSQL 配置文件 `pg_hba.conf`
2. 临时修改认证方式为 `trust`
3. 重启 PostgreSQL 服务
4. 使用 `ALTER USER` 修改密码
5. 改回原来的认证方式

### Q2: 端口 5432 被占用

**检查端口占用**:
```powershell
netstat -ano | findstr :5432
```

**解决方案**:
- 修改 PostgreSQL 端口（在安装时或配置文件中）
- 或关闭占用该端口的程序

### Q3: pgAdmin 无法连接

**检查**:
1. PostgreSQL 服务是否运行
2. 密码是否正确
3. 防火墙是否阻止连接

---

## 使用 Docker 替代方案（如果已安装 Docker）

如果你更倾向使用 Docker，请查看 `docker-setup.md`
