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
            $table->string('fare_screenshot')->nullable()->after('directions_data');
            $table->decimal('fare_amount_text', 10, 2)->nullable()->after('fare_screenshot');
            $table->decimal('rider1_fare', 10, 2)->nullable()->after('fare_amount_text');
            $table->decimal('rider2_fare', 10, 2)->nullable()->after('rider1_fare');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('rides', function (Blueprint $table) {
            $table->dropColumn(['fare_screenshot', 'fare_amount_text', 'rider1_fare', 'rider2_fare']);
        });
    }
};
