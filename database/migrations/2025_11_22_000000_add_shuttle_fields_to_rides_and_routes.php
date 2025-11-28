<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('rides', function (Blueprint $table) {
            if (!Schema::hasColumn('rides', 'route_id')) {
                $table->unsignedBigInteger('route_id')->nullable()->after('user_id');
            }
            if (!Schema::hasColumn('rides', 'start_stop_id')) {
                $table->unsignedBigInteger('start_stop_id')->nullable()->after('route_id');
            }
            if (!Schema::hasColumn('rides', 'end_stop_id')) {
                $table->unsignedBigInteger('end_stop_id')->nullable()->after('start_stop_id');
            }
        });

        Schema::table('routes', function (Blueprint $table) {
            if (!Schema::hasColumn('routes', 'capacity')) {
                $table->integer('capacity')->default(10)->after('code');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('rides', function (Blueprint $table) {
            $table->dropColumn(['route_id', 'start_stop_id', 'end_stop_id']);
        });

        Schema::table('routes', function (Blueprint $table) {
            $table->dropColumn('capacity');
        });
    }
};
