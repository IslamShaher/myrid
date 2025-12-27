#!/bin/bash
# Simple script to create SQL dump on remote machine
# Copy this to remote and run it, or run commands directly

# Create dump
mysqldump -u root -pElc2024@ ovoride > /tmp/ovoride_dump_$(date +%Y%m%d_%H%M%S).sql

# Or with password prompt (safer)
# mysqldump -u root -p ovoride > /tmp/ovoride_dump_$(date +%Y%m%d_%H%M%S).sql

echo "Dump created at: /tmp/ovoride_dump_*.sql"
echo "Download with: scp root@192.168.1.3:/tmp/ovoride_dump_*.sql ."



