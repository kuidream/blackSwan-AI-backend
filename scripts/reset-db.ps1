# 数据库重置脚本
# 警告: 此脚本会删除所有数据！

Write-Host "警告: 此操作将删除所有数据库数据!" -ForegroundColor Red
$confirmation = Read-Host "确定要继续吗? (输入 'YES' 确认)"

if ($confirmation -ne "YES") {
    Write-Host "操作已取消" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n开始重置数据库..." -ForegroundColor Cyan

# 1. 停止并删除容器及数据卷
Write-Host "1. 停止并删除容器..." -ForegroundColor Yellow
docker-compose down -v

# 2. 重新启动容器
Write-Host "2. 启动新容器..." -ForegroundColor Yellow
docker-compose up -d

# 3. 等待 PostgreSQL 就绪
Write-Host "3. 等待 PostgreSQL 就绪..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$ready = $false

while ($attempt -lt $maxAttempts -and -not $ready) {
    $attempt++
    Write-Host "   尝试连接... ($attempt/$maxAttempts)" -ForegroundColor Gray
    
    $result = docker exec blackswan-postgres pg_isready -U postgres 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ready = $true
        Write-Host "   PostgreSQL 已就绪!" -ForegroundColor Green
    } else {
        Start-Sleep -Seconds 2
    }
}

if (-not $ready) {
    Write-Host "错误: PostgreSQL 启动超时" -ForegroundColor Red
    exit 1
}

# 4. 应用 Schema
Write-Host "4. 应用数据库 Schema..." -ForegroundColor Yellow
$OutputEncoding = [System.Text.Encoding]::UTF8
Get-Content -Encoding UTF8 .\.ai\database\schema.sql | docker exec -i blackswan-postgres psql -U postgres -d blackswan 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n数据库重置成功!" -ForegroundColor Green
    
    # 显示统计信息
    $tableCount = docker exec blackswan-postgres psql -U postgres -d blackswan -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';"
    Write-Host "已创建 $($tableCount.Trim()) 张表" -ForegroundColor Cyan
} else {
    Write-Host "错误: 数据库 Schema 应用失败" -ForegroundColor Red
    exit 1
}
