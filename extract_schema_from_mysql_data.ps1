# Script to check MySQL data directory and provide information
# Note: Extracting data from .ibd files directly is complex and not recommended

Write-Host "=== MySQL Data Directory Analysis ===" -ForegroundColor Green
Write-Host ""

$mysqlDataPath = "mysql"
if (-not (Test-Path $mysqlDataPath)) {
    Write-Host "[ERROR] mysql directory not found!" -ForegroundColor Red
    exit 1
}

# Check for ovoride database
$ovoridePath = Join-Path $mysqlDataPath "ovoride"
if (Test-Path $ovoridePath) {
    Write-Host "[OK] Found ovoride database" -ForegroundColor Green
    
    $tables = Get-ChildItem $ovoridePath -Filter "*.ibd" | 
        Select-Object Name, @{Name="SizeKB";Expression={[math]::Round($_.Length/1KB,2)}}
    
    Write-Host "`nFound $($tables.Count) tables:" -ForegroundColor Cyan
    $tables | Format-Table -AutoSize
    
    Write-Host "`n[IMPORTANT] These are MySQL InnoDB data files (.ibd)" -ForegroundColor Yellow
    Write-Host "They cannot be directly imported into another MySQL instance." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "RECOMMENDED: Create SQL dump from remote machine:" -ForegroundColor Cyan
    Write-Host "  1. SSH into remote: ssh root@192.168.1.3" -ForegroundColor White
    Write-Host "  2. Run: mysqldump -u root -p ovoride > /tmp/ovoride_dump.sql" -ForegroundColor White
    Write-Host "  3. Download: scp root@192.168.1.3:/tmp/ovoride_dump.sql ." -ForegroundColor White
    Write-Host "  4. Import: .\setup_local_db.ps1 ovoride_dump.sql" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "[ERROR] ovoride database not found in mysql directory" -ForegroundColor Red
}

# Check total size
$totalSize = (Get-ChildItem $mysqlDataPath -Recurse -File -ErrorAction SilentlyContinue | 
    Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "Total data directory size: $totalSizeMB MB" -ForegroundColor Cyan





