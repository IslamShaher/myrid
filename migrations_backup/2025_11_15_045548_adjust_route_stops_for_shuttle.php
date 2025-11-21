<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        // This migration is intentionally left blank.
        // The actual fix is done in fix_route_stops_for_shuttle migration.
    }

    public function down()
    {
        // No rollback required.
    }
};

