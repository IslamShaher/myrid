<?php
ini_set('display_errors', 1);
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$db = $app->make('db');
$dbname = $db->connection()->getDatabaseName();
echo "DB_DATABASE = {$dbname}\n";
$tables = $db->select('SHOW TABLES');
foreach ($tables as $row) {
  echo array_values((array)$row)[0], "\n";
}
