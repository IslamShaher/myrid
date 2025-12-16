#!/bin/bash

PROJECT_DIR="/var/www/html/core"

# Navigate to project directory
cd "$PROJECT_DIR" || { echo "Failed to cd to $PROJECT_DIR"; exit 1; }

echo "Searching for existing Laravel server process..."
# Find PID of "php artisan serve"
PID=$(pgrep -f "php artisan serve")

if [ -n "$PID" ]; then
    echo "Found Laravel server (PID: $PID). Stopping..."
    kill $PID
    
    # Wait for process to exit
    TIMEOUT=10
    COUNT=0
    while kill -0 $PID 2>/dev/null; do
        sleep 1
        COUNT=$((COUNT+1))
        if [ $COUNT -ge $TIMEOUT ]; then
            echo "Force killing..."
            kill -9 $PID
            break
        fi
    done
    echo "Server stopped."
else
    echo "No running Laravel server found."
fi

echo "Starting server..."
chmod +x start_dev.sh
./start_dev.sh

