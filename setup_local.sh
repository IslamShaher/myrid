#!/bin/bash
echo "=== Setting up local Laravel environment ==="
# Set proper permissions
chmod -R 775 storage bootstrap/cache

# Install composer dependencies if composer is available
if command -v composer >/dev/null 2>&1; then
    composer install --no-interaction
else
    echo "Composer is not installed. Please install Composer manually."
fi

# Generate application key
php artisan key:generate

# Cache configuration and routes
php artisan config:cache


echo "Done! Access http://localhost/core"
