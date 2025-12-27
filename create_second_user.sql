-- SQL script to create a second test user for shared ride testing
-- Run this via: ssh root@192.168.1.3 "mysql -u your_db_user -p your_db_name < create_second_user.sql"
-- Or connect to MySQL and run these commands

-- Note: You'll need to replace 'your_password_hash_here' with an actual bcrypt hash
-- You can generate one using: php -r "echo password_hash('password123', PASSWORD_BCRYPT);"

-- Check if user exists first (optional - remove the user if exists)
-- DELETE FROM users WHERE email = 'rider2@test.com' OR username = 'rider2';

-- Insert second test user
-- Replace 'YOUR_PASSWORD_HASH' with actual bcrypt hash
INSERT INTO users (
    firstname, 
    lastname, 
    email, 
    username, 
    password,
    ev,
    sv,
    ts,
    tv,
    profile_complete,
    is_deleted,
    status,
    created_at,
    updated_at
) VALUES (
    'Rider',
    'Two',
    'rider2@test.com',
    'rider2',
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: password123 (bcrypt)
    1, -- ev: verified
    1, -- sv: verified
    0, -- ts: 2fa disabled
    1, -- tv: 2fa verified
    1, -- profile_complete: yes
    0, -- is_deleted: no
    1, -- status: active
    NOW(),
    NOW()
) ON DUPLICATE KEY UPDATE updated_at = NOW();

-- Verify the user was created
SELECT id, email, username, firstname, lastname FROM users WHERE email = 'rider2@test.com';





