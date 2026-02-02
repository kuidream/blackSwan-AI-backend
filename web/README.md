# blackSwan API 测试前端

基于 Vue 3 + Vite 的 API 测试页面。

## 快速开始

### 1. 安装依赖

```bash
cd web
npm install
```

### 2. 启动开发服务器

```bash
npm run dev
```

前端会启动在 `http://localhost:5173`

### 3. 访问测试页面

打开浏览器访问 `http://localhost:5173`

## 技术栈

- Vue 3
- Vite 5
- 原生 JavaScript (无额外 UI 框架)

## 代理配置

开发环境下，Vite 会自动将 `/health` 和 `/v1/*` 的请求代理到后端 `http://localhost:8080`，无需担心 CORS 问题。

## 构建生产版本

```bash
npm run build
```

构建产物会输出到 `dist` 目录。

## 预览生产构建

```bash
npm run preview
```
