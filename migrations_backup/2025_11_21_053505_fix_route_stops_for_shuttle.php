<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        // 1) Drop any shuttle_route_id FK if exists
        $fk = DB::select("
            SELECT CONSTRAINT_NAME 
            FROM information_schema.KEY_COLUMN_USAGE 
            WHERE TABLE_NAME = 'route_stops'
              AND COLUMN_NAME = 'shuttle_route_id'
              AND CONSTRAINT_SCHEMA = DATABASE()
              AND REFERENCED_TABLE_NAME IS NOT NULL
        ");

        if (!empty($fk)) {
            Schema::table('route_stops', function (Blueprint $table) use ($fk) {
                $table->dropForeign($fk[0]->CONSTRAINT_NAME);
            });
        }

        // 2) Drop shuttle_route_id column
        Schema::table('route_stops', function (Blueprint $table) {
            if (Schema::hasColumn('route_stops', 'shuttle_route_id')) {
                $table->dropColumn('shuttle_route_id');
            }
        });

        // 3) Drop existing FKs on route_id / stop_id ONLY if they exist
        $constraints = DB::select("
            SELECT CONSTRAINT_NAME, COLUMN_NAME 
            FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_NAME = 'route_stops'
              AND CONSTRAINT_SCHEMA = DATABASE()
              AND REFERENCED_TABLE_NAME IS NOT NULL
        ");

        Schema::table('route_stops', function (Blueprint $table) use ($constraints) {
            foreach ($constraints as $c) {
                $table->dropForeign($c->CONSTRAINT_NAME);
            }
        });

        // 4) Recreate clean FKs
        Schema::table('route_stops', function (Blueprint $table) {
            $table->foreign('route_id')
                ->references('id')->on('routes')
                ->onDelete('cascade');

            $table->foreign('stop_id')
                ->references('id')->on('stops')
                ->onDelete('cascade');
        });
    }

    public function down()
    {
        // No-op rollback
    }
};

