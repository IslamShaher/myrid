<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        Schema::table('route_stops', function (Blueprint $table) {
            if (!Schema::hasColumn('route_stops', 'shuttle_route_id')) {
                $table->unsignedBigInteger('shuttle_route_id')
                      ->nullable()
                      ->after('route_id');
            }
        });

        // Add FK in a second Schema::table to avoid driver issues
        if (Schema::hasTable('shuttle_routes')) {
            Schema::table('route_stops', function (Blueprint $table) {
                // Only add FK if it does not exist
                $hasForeign = DB::select("
                    SELECT CONSTRAINT_NAME 
                    FROM information_schema.KEY_COLUMN_USAGE 
                    WHERE TABLE_NAME = 'route_stops'
                      AND COLUMN_NAME = 'shuttle_route_id'
                      AND CONSTRAINT_SCHEMA = DATABASE()
                      AND REFERENCED_TABLE_NAME IS NOT NULL
                ");

                if (empty($hasForeign)) {
                    $table->foreign('shuttle_route_id')
                          ->references('id')
                          ->on('shuttle_routes')
                          ->onDelete('cascade');
                }
            });
        }
    }

    public function down()
    {
        Schema::table('route_stops', function (Blueprint $table) {

            // Drop FK ONLY if exists
            try {
                $table->dropForeign(['shuttle_route_id']);
            } catch (\Exception $e) {
                // FK doesn’t exist — ignore
            }

            // Drop column ONLY if exists
            if (Schema::hasColumn('route_stops', 'shuttle_route_id')) {
                $table->dropColumn('shuttle_route_id');
            }
        });
    }
};

