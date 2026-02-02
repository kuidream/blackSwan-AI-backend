# 快速启动指南

## 前置条件

确保你已安装 Go 1.21+。如果未安装，请参考 `scripts/setup.md`。

## 5 分钟启动

### 步骤 1: 配置环境变量（可选）

```bash
# 如果不配置，将使用默认值
cp .env.example .env
```

默认配置:
- 服务端口: 8080
- 模式: debug

### 步骤 2: 启动服务

#### 方式 1: 直接运行

```bash
go run cmd/api/main.go
```

#### 方式 2: 使用 Makefile

```bash
make run
```

#### 方式 3: 使用脚本

```bash
# Linux/macOS
./scripts/run.sh

# Windows PowerShell
./scripts/run.ps1
```

### 步骤 3: 验证服务

打开新终端，执行:

```bash
# 健康检查
curl http://localhost:8080/health

# 预期响应
# {"status":"ok","service":"blackSwan-backend"}

# 测试 API
curl http://localhost:8080/v1/ping

# 预期响应
# {"message":"pong"}
```

### 步骤 4: 停止服务

在运行服务的终端按 `Ctrl+C`，服务将优雅关闭。

## 当前功能

基础骨架已就绪，但业务逻辑尚未实现。

当前可用接口:
- `GET /health` - 健康检查
- `GET /v1/ping` - 测试接口

## 下一步

查看 `DEVELOPMENT.md` 了解完整的开发计划。

## 故障排查

### 问题: go 命令未找到

**解决方案**: 
1. 确认 Go 已安装: 访问 https://go.dev/dl/
2. 检查环境变量 PATH 中是否包含 Go 的 bin 目录

### 问题: 端口 8080 已被占用

**解决方案**:
1. 修改 `.env` 文件，设置 `SERVER_PORT=9090`
2. 或者杀掉占用端口的进程

### 问题: 依赖下载失败

**解决方案**:
```bash
# 设置 Go 代理（中国大陆）
go env -w GOPROXY=https://goproxy.cn,direct

# 重新下载
go mod download
```

## 参考文档

- 完整文档: `.ai/README.md`
- 开发指南: `DEVELOPMENT.md`
- 项目状态: `PROJECT_STATUS.md`
- 环境配置: `scripts/setup.md`
