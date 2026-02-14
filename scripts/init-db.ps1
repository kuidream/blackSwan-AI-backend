# 数据库初始化脚本
# 用途: 初始化 blackswan 数据库 Schema

Write-Host "初始化 blackSwan 数据库..." -ForegroundColor Cyan

# 检查 Docker 容器是否运行
$containerStatus = docker ps --filter "name=blackswan-postgres" --format "{{.Status}}"
if (-not $containerStatus) {
    Write-Host "错误: PostgreSQL 容器未运行" -ForegroundColor Red
    Write-Host "请先运行: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

if ($containerStatus -notlike "*healthy*") {
    Write-Host "警告: PostgreSQL 容器未就绪，等待 5 秒..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

# 应用 Schema
Write-Host "正在应用数据库 Schema..." -ForegroundColor Green
$OutputEncoding = [System.Text.Encoding]::UTF8
Get-Content -Encoding UTF8 .\.ai\database\schema.sql | docker exec -i blackswan-postgres psql -U postgres -d blackswan 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "数据库 Schema 应用成功!" -ForegroundColor Green
    
    # 显示统计信息
    $tableCount = docker exec blackswan-postgres psql -U postgres -d blackswan -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';"
    Write-Host "已创建 $($tableCount.Trim()) 张表" -ForegroundColor Cyan
    
    # 显示表列表
    Write-Host "`n数据库表列表:" -ForegroundColor Cyan
    docker exec blackswan-postgres psql -U postgres -d blackswan -c "\dt"
} else {
    Write-Host "错误: 数据库 Schema 应用失败" -ForegroundColor Red
    exit 1
}
