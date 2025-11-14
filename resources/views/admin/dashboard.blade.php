@extends('admin.layouts.app')
@section('panel')
    <x-permission_check permission="view rider payment report">
        <x-admin.ui.widget.group.dashboard.payment :widget="$widget" />
    </x-permission_check>

    <x-permission_check permission="view rides">
        <x-admin.ui.widget.group.dashboard.ride :widget="$widget" />
    </x-permission_check>

    <x-permission_check permission="view riders">
        <x-admin.ui.widget.group.dashboard.users :widget="$widget" />
    </x-permission_check>

    <x-permission_check permission="view drivers">
        <x-admin.ui.widget.group.dashboard.driver :widget="$widget" />
    </x-permission_check>

    <x-permission_check permission="view driver deposits">
        <x-admin.ui.widget.group.dashboard.financial_overview :widget="$widget" />
    </x-permission_check>

    <div class="row gy-4 mb-4">
        <x-permission_check permission="view driver transaction history">
            <x-admin.other.dashboard_trx_chart />
        </x-permission_check>
        <div class="col-xl-4">
            <x-permission_check permission="view rider login history">
                <x-admin.other.dashboard_login_chart :userLogin=$userLogin />
            </x-permission_check>
        </div>
    </div>
    <x-permission_check permission="cron job settings">
        <x-admin.other.cron_modal />
    </x-permission_check>
@endsection

@push('script-lib')
    <script src="{{ asset('assets/admin/js/apexcharts.min.js') }}"></script>
    <script src="{{ asset('assets/admin/js/charts.js') }}"></script>
    <script src="{{ asset('assets/global/js/flatpickr.js') }}"></script>
@endpush


@push('style-lib')
    <link rel="stylesheet" type="text/css" href="{{ asset('assets/global/css/flatpickr.min.css') }}">
@endpush

@push('script')
    <script>
        "use strict";
        (function($) {
            $(".date-picker").flatpickr({
                mode: 'range',
                maxDate: new Date(),
            });
        })(jQuery);
    </script>
@endpush
