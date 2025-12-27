# Local Database Setup Script for OvoRide
# This script will create the database and import the SQL file

Write-Host "=== OvoRide Local Database Setup ===" -ForegroundColor Green
Write-Host ""

# Add MySQL to PATH
$mysqlPath = "C:\laragon\bin\mysql\mysql-8.4.3-winx64\bin"
if (Test-Path $mysqlPath) {
    $env:Path += ";$mysqlPath"
    Write-Host "[OK] MySQL path added" -ForegroundColor Green
} else {
    Write-Host "[ERROR] MySQL not found at $mysqlPath" -ForegroundColor Red
    Write-Host "Please ensure Laragon MySQL is installed" -ForegroundColor Yellow
    exit 1
}

# Check if MySQL is running
Write-Host "Checking MySQL connection..." -ForegroundColor Cyan
$mysqlTest = mysql -u root -e "SELECT 1" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Cannot connect to MySQL server!" -ForegroundColor Red
    Write-Host "Please start MySQL from Laragon interface first:" -ForegroundColor Yellow
    Write-Host "1. Open Laragon" -ForegroundColor Yellow
    Write-Host "2. Click 'Start All' or click on MySQL to start it" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Then run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] MySQL is running" -ForegroundColor Green
Write-Host ""

# Create database
Write-Host "Creating database 'ovoride'..." -ForegroundColor Cyan
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ovoride CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Database created or already exists" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to create database" -ForegroundColor Red
    exit 1
}

# Get SQL file path
$sqlFile = $args[0]
if (-not $sqlFile) {
    # Try to find SQL files in common locations (excluding Initial_Release and vendor)
    Write-Host "Searching for SQL files..." -ForegroundColor Cyan
    $foundFiles = Get-ChildItem -Path . -Filter "*.sql" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { 
            $_.FullName -notlike "*Initial_Release*" -and 
            $_.FullName -notlike "*vendor*" -and
            $_.Length -gt 100KB  # Only files > 100KB
        } | 
        Select-Object FullName, @{Name="SizeMB";Expression={[math]::Round($_.Length/1MB,2)}}
    
    if ($foundFiles.Count -eq 0) {
        Write-Host "[ERROR] No SQL files found. Please provide the database file path." -ForegroundColor Red
        Write-Host "Usage: .\setup_local_db.ps1 [path-to-database.sql]" -ForegroundColor Yellow
        Write-Host "Example: .\setup_local_db.ps1 database.sql" -ForegroundColor Yellow
        Write-Host "Or: .\setup_local_db.ps1 C:\path\to\ovoride_dump.sql" -ForegroundColor Yellow
        exit 1
    } elseif ($foundFiles.Count -eq 1) {
        $sqlFile = $foundFiles[0].FullName
        Write-Host "[OK] Found SQL file: $sqlFile ({($foundFiles[0].SizeMB)} MB)" -ForegroundColor Green
    } else {
        Write-Host "Multiple SQL files found:" -ForegroundColor Yellow
        $index = 1
        foreach ($file in $foundFiles) {
            Write-Host "  [$index] $($file.FullName) ($($file.SizeMB) MB)" -ForegroundColor Cyan
            $index++
        }
        $choice = Read-Host "Select file number (1-$($foundFiles.Count))"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $foundFiles.Count) {
            $sqlFile = $foundFiles[[int]$choice - 1].FullName
            Write-Host "[OK] Selected: $sqlFile" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Invalid selection" -ForegroundColor Red
            exit 1
        }
    }
}

if (-not (Test-Path $sqlFile)) {
    Write-Host "[ERROR] SQL file not found: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Using SQL file: $sqlFile" -ForegroundColor Green
$fileSize = [math]::Round((Get-Item $sqlFile).Length / 1MB, 2)
Write-Host "      File size: $fileSize MB" -ForegroundColor Cyan
Write-Host ""

# Import database (this may take a while)
Write-Host "Importing database... This may take a few minutes..." -ForegroundColor Cyan
$importResult = mysql -u root ovoride < $sqlFile 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Database imported successfully!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to import database" -ForegroundColor Red
    Write-Host $importResult
    exit 1
}

Write-Host ""
Write-Host "=== Database Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Update .env file: DB_HOST=127.0.0.1, DB_DATABASE=ovoride" -ForegroundColor Yellow
Write-Host "2. Run: php artisan config:clear" -ForegroundColor Yellow
Write-Host "3. Test: php artisan migrate:status" -ForegroundColor Yellow
Write-Host "4. Access admin: http://localhost:8000/admin" -ForegroundColor Yellow
Write-Host "   Username: admin" -ForegroundColor Yellow
Write-Host ""

