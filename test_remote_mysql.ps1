# Test script to check remote MySQL connection from Windows

param(
    [string]$Host = "192.168.1.3",
    [int]$Port = 3306,
    [string]$User = "root",
    [string]$Password = "Elc2024@",
    [string]$Database = "ovoride"
)

Write-Host "=== Testing Remote MySQL Connection ===" -ForegroundColor Green
Write-Host ""

# Test network connectivity
Write-Host "1. Testing network connectivity..." -ForegroundColor Cyan
$tcpTest = Test-NetConnection -ComputerName $Host -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
if ($tcpTest) {
    Write-Host "   [OK] Port $Port is open on $Host" -ForegroundColor Green
} else {
    Write-Host "   [FAIL] Cannot connect to $Host on port $Port" -ForegroundColor Red
    Write-Host "   Check firewall and MySQL configuration on remote machine" -ForegroundColor Yellow
    exit 1
}

# Test MySQL connection (if MySQL client is available)
$mysqlPath = "C:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysql.exe"
if (Test-Path $mysqlPath) {
    Write-Host ""
    Write-Host "2. Testing MySQL connection..." -ForegroundColor Cyan
    $env:Path += ";C:\laragon\bin\mysql\mysql-8.4.3-winx64\bin"
    
    $mysqlCmd = "mysql -h $Host -u $User -p$Password -e `"SELECT 1 as test;`" $Database 2>&1"
    $result = cmd /c $mysqlCmd
    
    if ($LASTEXITCODE -eq 0 -or $result -match "test") {
        Write-Host "   [OK] MySQL connection successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "3. Testing database access..." -ForegroundColor Cyan
        $tablesCmd = "mysql -h $Host -u $User -p$Password -e `"SHOW TABLES;`" $Database 2>&1"
        $tables = cmd /c $tablesCmd
        if ($LASTEXITCODE -eq 0) {
            $tableCount = ($tables | Select-String -Pattern "^\|" | Measure-Object).Count - 2
            Write-Host "   [OK] Found $tableCount tables in database" -ForegroundColor Green
        }
    } else {
        Write-Host "   [FAIL] MySQL connection failed" -ForegroundColor Red
        Write-Host "   Error: $result" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Common issues:" -ForegroundColor Yellow
        Write-Host "   - MySQL not configured for remote access" -ForegroundColor Yellow
        Write-Host "   - Wrong username/password" -ForegroundColor Yellow
        Write-Host "   - User doesn't have remote access permission" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "   [INFO] MySQL client not found. Network test passed." -ForegroundColor Cyan
    Write-Host "   Install MySQL client or use Laragon to test connection" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Connection Test Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "If connection works, update your .env file:" -ForegroundColor Cyan
Write-Host "  DB_HOST=$Host" -ForegroundColor White
Write-Host "  DB_DATABASE=$Database" -ForegroundColor White
Write-Host "  DB_USERNAME=$User" -ForegroundColor White
Write-Host "  DB_PASSWORD=$Password" -ForegroundColor White
Write-Host ""



