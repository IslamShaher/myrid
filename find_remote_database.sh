#!/bin/bash
# Script to find database location on remote machine
# Run this on the remote machine: bash find_remote_database.sh

echo "=== Finding Database Location on Remote Machine ==="
echo ""

# Find SQL dump files
echo "1. Searching for SQL dump files..."
find /var/www /home /opt /root -name "*.sql" -type f 2>/dev/null | head -20
echo ""

# Check common database backup locations
echo "2. Checking common backup directories..."
for dir in /var/backups /home/backups /opt/backups /root/backups /var/www/html/backups; do
    if [ -d "$dir" ]; then
        echo "Found: $dir"
        ls -lh "$dir"/*.sql 2>/dev/null | head -5
    fi
done
echo ""

# Check Laravel project directories
echo "3. Searching for Laravel projects with database files..."
find /var/www /home -type d -name "myrid9" -o -name "ovoride" -o -name "*laravel*" 2>/dev/null | while read dir; do
    if [ -f "$dir/database.sql" ] || [ -f "$dir/*.sql" ]; then
        echo "Found Laravel project: $dir"
        ls -lh "$dir"/*.sql 2>/dev/null
    fi
done
echo ""

# Check if MySQL is running and get database location
echo "4. MySQL database directory (if MySQL is running)..."
if command -v mysql &> /dev/null; then
    mysql -u root -e "SHOW VARIABLES LIKE 'datadir';" 2>/dev/null || echo "Cannot connect to MySQL"
fi
echo ""

# List databases
echo "5. Available databases..."
if command -v mysql &> /dev/null; then
    mysql -u root -e "SHOW DATABASES;" 2>/dev/null || echo "Cannot connect to MySQL"
fi
echo ""

# Create a dump of the current database (if we can connect)
echo "6. Creating fresh database dump..."
if command -v mysqldump &> /dev/null; then
    read -p "Enter MySQL root password (or press Enter if no password): " -s MYSQL_PWD
    echo ""
    if [ -z "$MYSQL_PWD" ]; then
        mysqldump -u root ovoride > /tmp/ovoride_dump_$(date +%Y%m%d_%H%M%S).sql 2>/dev/null && \
            echo "Database dump created at: /tmp/ovoride_dump_$(date +%Y%m%d_%H%M%S).sql" || \
            echo "Failed to create dump (might need password)"
    else
        export MYSQL_PWD
        mysqldump -u root ovoride > /tmp/ovoride_dump_$(date +%Y%m%d_%H%M%S).sql 2>/dev/null && \
            echo "Database dump created at: /tmp/ovoride_dump_$(date +%Y%m%d_%H%M%S).sql" || \
            echo "Failed to create dump"
    fi
fi



