#!/bin/bash
# Script to create SQL dump from remote MySQL database
# Run this on the remote machine OR use mysqldump directly

echo "=== Creating SQL Dump from Remote Database ==="
echo ""

# Configuration - adjust as needed
DB_HOST="127.0.0.1"
DB_USER="root"
DB_NAME="ovoride"
OUTPUT_FILE="ovoride_dump_$(date +%Y%m%d_%H%M%S).sql"

echo "Database: $DB_NAME"
echo "Output file: $OUTPUT_FILE"
echo ""

# Create dump with all options
mysqldump -h "$DB_HOST" -u "$DB_USER" -p \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --add-drop-database \
    --databases "$DB_NAME" > "$OUTPUT_FILE" 2>&1

if [ $? -eq 0 ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    echo "✓ Database dump created successfully!"
    echo "  File: $OUTPUT_FILE"
    echo "  Size: $FILE_SIZE"
    echo ""
    echo "You can now copy this file to your local machine:"
    echo "  scp $OUTPUT_FILE user@local-machine:/path/to/project/"
else
    echo "✗ Failed to create dump"
    exit 1
fi



