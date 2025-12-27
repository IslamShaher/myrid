#!/bin/bash
# Script to enable remote MySQL connections on the remote server
# Run this on the remote machine (192.168.1.3)

echo "=== Enabling Remote MySQL Connections ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Configuration
MYSQL_USER="root"
MYSQL_DB="ovoride"
REMOTE_IP="192.168.1.13"  # Your local Windows machine IP
# Or allow all local network: REMOTE_IP="192.168.1.%" 

echo "Configuring MySQL for remote access..."
echo "Remote IP: $REMOTE_IP"
echo ""

# Backup current my.cnf
if [ -f /etc/mysql/my.cnf ]; then
    cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup.$(date +%Y%m%d_%H%M%S)
    echo "[OK] Backed up my.cnf"
elif [ -f /etc/my.cnf ]; then
    cp /etc/my.cnf /etc/my.cnf.backup.$(date +%Y%m%d_%H%M%S)
    echo "[OK] Backed up my.cnf"
fi

# Find MySQL configuration file
MYSQL_CONF=""
if [ -f /etc/mysql/mysql.conf.d/mysqld.cnf ]; then
    MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
elif [ -f /etc/mysql/my.cnf ]; then
    MYSQL_CONF="/etc/mysql/my.cnf"
elif [ -f /etc/my.cnf ]; then
    MYSQL_CONF="/etc/my.cnf"
fi

if [ -n "$MYSQL_CONF" ]; then
    echo "Found MySQL config: $MYSQL_CONF"
    
    # Check if bind-address exists
    if grep -q "^bind-address" "$MYSQL_CONF"; then
        # Comment out or change bind-address
        sed -i 's/^bind-address/#bind-address/' "$MYSQL_CONF"
        echo "[OK] Commented out bind-address"
    fi
    
    # Add bind-address if it doesn't exist
    if ! grep -q "bind-address" "$MYSQL_CONF"; then
        echo "" >> "$MYSQL_CONF"
        echo "# Allow remote connections" >> "$MYSQL_CONF"
        echo "bind-address = 0.0.0.0" >> "$MYSQL_CONF"
        echo "[OK] Added bind-address = 0.0.0.0"
    fi
else
    echo "[WARNING] Could not find MySQL config file"
    echo "You may need to manually edit MySQL config"
fi

# Update MySQL user to allow remote connections
echo ""
echo "Updating MySQL user permissions..."

# Get MySQL root password (you may need to adjust this)
read -sp "Enter MySQL root password: " MYSQL_PASS
echo ""

mysql -u root -p"$MYSQL_PASS" << EOF
-- Create user for remote access (if doesn't exist)
CREATE USER IF NOT EXISTS 'root'@'$REMOTE_IP' IDENTIFIED BY 'Elc2024@';

-- Or allow from entire subnet
CREATE USER IF NOT EXISTS 'root'@'192.168.1.%' IDENTIFIED BY 'Elc2024@';

-- Grant all privileges
GRANT ALL PRIVILEGES ON *.* TO 'root'@'$REMOTE_IP' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.1.%' WITH GRANT OPTION;

-- Grant privileges on specific database
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO 'root'@'$REMOTE_IP';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO 'root'@'192.168.1.%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Show users
SELECT User, Host FROM mysql.user WHERE User='root';
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "[OK] MySQL user permissions updated"
else
    echo ""
    echo "[ERROR] Failed to update MySQL user permissions"
    exit 1
fi

# Restart MySQL service
echo ""
echo "Restarting MySQL service..."
if systemctl restart mysql 2>/dev/null; then
    echo "[OK] MySQL restarted"
elif service mysql restart 2>/dev/null; then
    echo "[OK] MySQL restarted"
else
    echo "[WARNING] Could not restart MySQL automatically"
    echo "Please restart MySQL manually: systemctl restart mysql"
fi

# Check firewall
echo ""
echo "Checking firewall..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "UFW is active. Adding MySQL port rule..."
        ufw allow 3306/tcp
        echo "[OK] Firewall rule added"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if systemctl is-active --quiet firewalld; then
        echo "Firewalld is active. Adding MySQL port rule..."
        firewall-cmd --permanent --add-service=mysql
        firewall-cmd --reload
        echo "[OK] Firewall rule added"
    fi
else
    echo "[INFO] No firewall detected or firewall management not available"
fi

echo ""
echo "=== Configuration Complete! ==="
echo ""
echo "MySQL should now accept remote connections from:"
echo "  - $REMOTE_IP"
echo "  - 192.168.1.% (entire subnet)"
echo ""
echo "Test connection from local machine:"
echo "  mysql -h 192.168.1.3 -u root -p ovoride"
echo ""



