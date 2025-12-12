<?php
$host = '127.0.0.1';
$db   = 'wbuvhbte_ovoride';
$user = 'wbuvhbte_adminnew';
$pass = 'adminnew@A';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
    exit(1);
}

// 1. Get the first shuttle route
$stmt = $pdo->query("SELECT * FROM routes LIMIT 1");
$route = $stmt->fetch();

if (!$route) {
    echo "No shuttle routes found.\n";
    exit;
}

echo "Route found: " . $route['name'] . " (ID: " . $route['id'] . ")\n";

// 2. Get stops for this route
$stmt = $pdo->prepare("
    SELECT s.name, s.latitude, s.longitude, rs.order 
    FROM stops s
    JOIN route_stops rs ON s.id = rs.stop_id
    WHERE rs.route_id = ?
    ORDER BY rs.order ASC
");
$stmt->execute([$route['id']]);
$stops = $stmt->fetchAll();

if (empty($stops)) {
    echo "No stops found for this route.\n";
} else {
    echo "Stops:\n";
    foreach ($stops as $stop) {
        echo "- " . $stop['name'] . " (Order: " . $stop['order'] . ")\n";
    }
}
