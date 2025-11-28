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
        Schema::table('general_settings', function (Blueprint $table) {
            $table->text('whatsapp_config')->nullable();
            $table->tinyInteger('wn')->default(0)->comment('WhatsApp Notification Status');
        });

        Schema::table('notification_templates', function (Blueprint $table) {
            $table->tinyInteger('whatsapp_status')->default(0);
            $table->text('whatsapp_body')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('general_settings', function (Blueprint $table) {
            $table->dropColumn('whatsapp_config');
            $table->dropColumn('wn');
        });

        Schema::table('notification_templates', function (Blueprint $table) {
            $table->dropColumn('whatsapp_status');
            $table->dropColumn('whatsapp_body');
        });
    }
};
