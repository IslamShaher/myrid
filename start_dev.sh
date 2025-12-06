#!/bin/bash

# Start MySQL if not running
if ! pgrep -x "mysqld" > /dev/null
then
    echo "Starting MySQL..."
    service mysql start
else
    echo "MySQL is already running."
fi

# Start Laravel Server if not running
if ps aux | grep -v "grep" | grep "php artisan serve" > /dev/null
then
    echo "Laravel server is already running."
else
    echo "Starting Laravel server..."
    nohup php artisan serve --host=0.0.0.0 --port=8000 > laravel.log 2>&1 &
    echo "Laravel server started on http://0.0.0.0:8000"
fi







