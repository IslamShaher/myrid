<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('rides', function (Blueprint $table) {
            $table->decimal('second_pickup_latitude', 10, 8)->nullable()->after('second_user_id');
            $table->decimal('second_pickup_longitude', 11, 8)->nullable()->after('second_pickup_latitude');
            $table->decimal('second_destination_latitude', 10, 8)->nullable()->after('second_pickup_longitude');
            $table->decimal('second_destination_longitude', 11, 8)->nullable()->after('second_destination_latitude');
            $table->text('shared_ride_sequence')->nullable()->after('second_destination_longitude');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('rides', function (Blueprint $table) {
            $table->dropColumn([
                'second_pickup_latitude',
                'second_pickup_longitude',
                'second_destination_latitude',
                'second_destination_longitude',
                'shared_ride_sequence'
            ]);
        });
    }
};
