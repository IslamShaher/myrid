# Commands to Find Database on Remote Machine

## Quick Commands (Run on Remote Machine)

### Option 1: Create Fresh Database Dump (Recommended)
This is the best option - it creates a current dump of the live database:

```bash
# SSH into remote machine (192.168.1.3 or 192.168.1.13)
ssh root@192.168.1.3

# Navigate to your Laravel project directory (adjust path as needed)
cd /var/www/html/core  # or wherever your project is

# Create database dump
mysqldump -u root -p ovoride > /tmp/ovoride_dump_$(date +%Y%m%d_%H%M%S).sql

# Or if no password:
mysqldump -u root ovoride > /tmp/ovoride_dump_$(date +%Y%m%d_%H%M%S).sql

# Copy the file to a location you can access
# Then download it using scp from your local machine:
# scp root@192.168.1.3:/tmp/ovoride_dump_*.sql .
```

### Option 2: Find Existing SQL Files

```bash
# Search for SQL files
find /var/www /home /opt /root -name "*.sql" -type f -size +100k 2>/dev/null

# Check Laravel project directories specifically
find /var/www -name "*.sql" -type f 2>/dev/null

# List files in common backup locations
ls -lh /var/backups/*.sql 2>/dev/null
ls -lh /home/*/backups/*.sql 2>/dev/null
```

### Option 3: Use the PHP Script (If in Laravel Project Directory)

```bash
# Copy find_remote_database.php to remote machine
scp find_remote_database.php root@192.168.1.3:/var/www/html/core/

# SSH into remote
ssh root@192.168.1.3
cd /var/www/html/core

# Run the script
php find_remote_database.php
```

### Option 4: Use the Bash Script

```bash
# Copy find_remote_database.sh to remote machine
scp find_remote_database.sh root@192.168.1.3:/tmp/

# SSH into remote
ssh root@192.168.1.3
chmod +x /tmp/find_remote_database.sh
bash /tmp/find_remote_database.sh
```

## Find Database Location (MySQL Data Directory)

```bash
# Check MySQL data directory
mysql -u root -e "SHOW VARIABLES LIKE 'datadir';"

# List databases
mysql -u root -e "SHOW DATABASES;"

# Check if ovoride database exists
mysql -u root -e "USE ovoride; SHOW TABLES;" | head -20
```

## After Getting the Database File

Once you have the database file (either from dump or existing file):

1. Copy it to your local Windows machine (if not already there)
2. Place it in your project directory (e.g., `database.sql` or `ovoride_dump.sql`)
3. Run the setup script:
   ```powershell
   .\setup_local_db.ps1 database.sql
   ```





