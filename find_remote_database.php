<?php
/**
 * Script to find database location and create dump on remote machine
 * Run this on the remote machine: php find_remote_database.php
 */

echo "=== Finding Database Location on Remote Machine ===\n\n";

// Find SQL dump files
echo "1. Searching for SQL dump files...\n";
$searchPaths = ['/var/www', '/home', '/opt', '/root', '/var/backups'];
foreach ($searchPaths as $path) {
    if (is_dir($path)) {
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($path, RecursiveDirectoryIterator::SKIP_DOTS),
            RecursiveIteratorIterator::SELF_FIRST
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile() && $file->getExtension() === 'sql') {
                $size = filesize($file->getPathname());
                $sizeMB = round($size / 1024 / 1024, 2);
                if ($sizeMB > 0.1) { // Only show files > 100KB
                    echo "   Found: {$file->getPathname()} ({$sizeMB} MB)\n";
                }
            }
        }
    }
}
echo "\n";

// Try to get database info from .env
echo "2. Checking Laravel project directories...\n";
$projectPaths = ['/var/www/html', '/var/www', '/home'];
foreach ($projectPaths as $basePath) {
    if (is_dir($basePath)) {
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($basePath, RecursiveDirectoryIterator::SKIP_DOTS),
            RecursiveIteratorIterator::SELF_FIRST
        );
        
        foreach ($iterator as $file) {
            if ($file->getFilename() === '.env' && $file->isFile()) {
                $envPath = $file->getPathname();
                $projectDir = dirname($envPath);
                
                // Check if this looks like our project
                if (file_exists($projectDir . '/artisan') || 
                    file_exists($projectDir . '/composer.json')) {
                    echo "   Found Laravel project: $projectDir\n";
                    
                    // Read .env to find database name
                    $envContent = file_get_contents($envPath);
                    if (preg_match('/DB_DATABASE=(.+)/', $envContent, $matches)) {
                        $dbName = trim($matches[1]);
                        echo "      Database name: $dbName\n";
                    }
                    
                    // Check for SQL files in this directory
                    $sqlFiles = glob($projectDir . '/*.sql');
                    foreach ($sqlFiles as $sqlFile) {
                        $size = filesize($sqlFile);
                        $sizeMB = round($size / 1024 / 1024, 2);
                        echo "      SQL file: $sqlFile ({$sizeMB} MB)\n";
                    }
                }
            }
        }
    }
}
echo "\n";

// Create database dump if we can connect
echo "3. Creating fresh database dump...\n";
if (file_exists(__DIR__ . '/.env')) {
    require __DIR__ . '/vendor/autoload.php';
    $app = require_once __DIR__ . '/bootstrap/app.php';
    $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();
    
    try {
        $dbName = env('DB_DATABASE');
        $dbUser = env('DB_USERNAME');
        $dbPass = env('DB_PASSWORD');
        $dbHost = env('DB_HOST', '127.0.0.1');
        
        echo "   Database: $dbName\n";
        echo "   Host: $dbHost\n";
        
        // Use mysqldump if available
        $dumpFile = '/tmp/ovoride_dump_' . date('Ymd_His') . '.sql';
        $passwordArg = $dbPass ? "-p'$dbPass'" : '';
        $command = "mysqldump -h $dbHost -u $dbUser $passwordArg $dbName > $dumpFile 2>&1";
        
        exec($command, $output, $returnCode);
        
        if ($returnCode === 0 && file_exists($dumpFile)) {
            $size = filesize($dumpFile);
            $sizeMB = round($size / 1024 / 1024, 2);
            echo "   ✓ Database dump created: $dumpFile ({$sizeMB} MB)\n";
            echo "   You can copy this file to your local machine.\n";
        } else {
            echo "   ✗ Failed to create dump. Output: " . implode("\n", $output) . "\n";
            echo "   Try running manually: mysqldump -u $dbUser -p $dbName > dump.sql\n";
        }
    } catch (\Exception $e) {
        echo "   Error: " . $e->getMessage() . "\n";
    }
} else {
    echo "   .env file not found in current directory.\n";
    echo "   Run this script from your Laravel project root.\n";
}

echo "\n=== Done ===\n";





