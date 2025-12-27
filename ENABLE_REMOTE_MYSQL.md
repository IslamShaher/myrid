# Enable Remote MySQL Connections

This guide will help you configure MySQL on the remote machine (192.168.1.3) to accept connections from your local Windows machine (192.168.1.13).

## Quick Steps

### 1. SSH into Remote Machine
```bash
ssh root@192.168.1.3
```

### 2. Edit MySQL Configuration

Find and edit the MySQL configuration file:

**Ubuntu/Debian:**
```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# OR
sudo nano /etc/mysql/my.cnf
```

**CentOS/RHEL:**
```bash
sudo nano /etc/my.cnf
```

**Find and change this line:**
```ini
bind-address = 127.0.0.1
```

**Change to:**
```ini
bind-address = 0.0.0.0
```

Or comment it out:
```ini
# bind-address = 127.0.0.1
```

Save and exit (Ctrl+X, then Y, then Enter)

### 3. Update MySQL User Permissions

Connect to MySQL:
```bash
mysql -u root -p
# Enter password: Elc2024@
```

Run these SQL commands:
```sql
-- Create user for your local IP (replace 192.168.1.13 with your actual IP)
CREATE USER IF NOT EXISTS 'root'@'192.168.1.13' IDENTIFIED BY 'Elc2024@';

-- Or allow from entire local network (recommended for development)
CREATE USER IF NOT EXISTS 'root'@'192.168.1.%' IDENTIFIED BY 'Elc2024@';

-- Grant privileges
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.1.13' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.1.%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ovoride.* TO 'root'@'192.168.1.13';
GRANT ALL PRIVILEGES ON ovoride.* TO 'root'@'192.168.1.%';

-- Apply changes
FLUSH PRIVILEGES;

-- Verify
SELECT User, Host FROM mysql.user WHERE User='root';

-- Exit
EXIT;
```

### 4. Configure Firewall

**UFW (Ubuntu/Debian):**
```bash
sudo ufw allow 3306/tcp
sudo ufw status
```

**Firewalld (CentOS/RHEL):**
```bash
sudo firewall-cmd --permanent --add-service=mysql
sudo firewall-cmd --reload
```

**iptables (if used):**
```bash
sudo iptables -A INPUT -p tcp --dport 3306 -j ACCEPT
sudo iptables-save
```

### 5. Restart MySQL

```bash
# Ubuntu/Debian
sudo systemctl restart mysql
# OR
sudo service mysql restart

# CentOS/RHEL
sudo systemctl restart mysqld
```

### 6. Test Connection from Local Machine

From your Windows machine, test the connection:

```powershell
# If you have MySQL client installed
mysql -h 192.168.1.3 -u root -p ovoride

# Or test with PowerShell
Test-NetConnection -ComputerName 192.168.1.3 -Port 3306
```

### 7. Update Local .env File

Once the connection works, update your local `.env` file:
```ini
DB_HOST=192.168.1.3
DB_PORT=3306
DB_DATABASE=ovoride
DB_USERNAME=root
DB_PASSWORD=Elc2024@
```

Then test:
```powershell
php artisan config:clear
php artisan migrate:status
```

## Using the Automated Script

If you prefer, use the provided script:

```bash
# Copy script to remote machine
scp enable_remote_mysql.sh root@192.168.1.3:/tmp/

# SSH into remote
ssh root@192.168.1.3

# Make executable and run
chmod +x /tmp/enable_remote_mysql.sh
sudo /tmp/enable_remote_mysql.sh
```

## Troubleshooting

### Connection Refused
- Check if MySQL is running: `sudo systemctl status mysql`
- Verify bind-address is set to `0.0.0.0`
- Check firewall rules

### Access Denied
- Verify user permissions in MySQL
- Check if user exists: `SELECT User, Host FROM mysql.user;`
- Make sure you're using the correct password

### Can't Connect from Windows
- Test network connectivity: `Test-NetConnection -ComputerName 192.168.1.3 -Port 3306`
- Check Windows Firewall
- Verify MySQL is listening on port 3306: `sudo netstat -tlnp | grep 3306`

### Security Note

⚠️ **Important**: Allowing remote root access is a security risk. For production, consider:
- Creating a dedicated user instead of using root
- Using strong passwords
- Restricting to specific IP addresses
- Using SSH tunneling instead of direct MySQL connection



