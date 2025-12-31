<?php
/**
 * Simple script to create second test user
 * Run: php create_user_simple.php
 * Or via SSH: ssh root@192.168.1.3 "cd /path/to/project && php create_user_simple.php"
 */

// Database credentials - UPDATE THESE for your server
$db_host = 'localhost';
$db_name = 'your_database_name'; // UPDATE THIS
$db_user = 'your_db_user'; // UPDATE THIS  
$db_pass = 'your_db_password'; // UPDATE THIS

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8mb4", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check if user exists
    $stmt = $pdo->prepare("SELECT id, email, username FROM users WHERE email = ? OR username = ?");
    $stmt->execute(['rider2@test.com', 'rider2']);
    $existing = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($existing) {
        echo "User already exists!\n";
        echo "ID: {$existing['id']}\n";
        echo "Email: {$existing['email']}\n";
        echo "Username: {$existing['username']}\n";
        exit(0);
    }
    
    // Generate password hash (bcrypt)
    $password = 'password123';
    $passwordHash = password_hash($password, PASSWORD_BCRYPT);
    
    // Insert new user
    $sql = "INSERT INTO users (
        firstname, lastname, email, username, password,
        ev, sv, ts, tv, profile_complete, is_deleted, status,
        created_at, updated_at
    ) VALUES (
        'Rider', 'Two', 'rider2@test.com', 'rider2', ?,
        1, 1, 0, 1, 1, 0, 1,
        NOW(), NOW()
    )";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$passwordHash]);
    
    $userId = $pdo->lastInsertId();
    
    echo "User created successfully!\n";
    echo "ID: $userId\n";
    echo "Email: rider2@test.com\n";
    echo "Username: rider2\n";
    echo "Password: $password\n";
    
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}










