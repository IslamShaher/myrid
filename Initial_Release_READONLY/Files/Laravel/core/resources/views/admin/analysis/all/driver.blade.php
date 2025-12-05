@extends('admin.layouts.app')
@section('panel')
    <div class="row responsive-row">
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.report.rider.payment') }}?driver_id={{ $driver->id }}"
                :currency="true" variant="info" title="Total Earning" :value="$widget['total_earning']" icon="las la-file-invoice-dollar" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.report.driver.commission') }}?driver_id={{ $driver->id }}"
                :currency="true" variant="primary" title="Total Commission Paid" :value="$widget['total_commission_paid']" icon="las la-coins" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.rides.tips') }}?driver_id={{ $driver->id }}"
                :currency="true" variant="warning" title="Total Tips Earning" :value="$widget['total_tips']"
                icon="las la-search-dollar" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.report.rider.payment') }}?driver_id={{ $driver->id }}"
                :currency="true" variant="success" title="Average Earning Per Ride" :value="$widget['average_earning_per_ride']"
                icon="las la-money-bill-alt" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.report.rider.payment.today') }}?driver_id={{ $driver->id }}"
                :currency="true" variant="success" title="Today Earning" :value="$widget['today_earning']" icon="las la-calendar" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four
                url="{{ route('admin.report.rider.payment.week') }}?driver_id={{ $driver->id }}"
                :currency="true" variant="warning" title="This Week Earning" :value="$widget['this_week_earning']" icon="las la-calendar" />
        </div>

        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four
                url="{{ route('admin.report.rider.payment.month') }}?driver_id={{ $driver->id }}"
                :currency="true" variant="primary" title="This Month Earning" :value="$widget['this_month_earning']" icon="las la-calendar" />
        </div>

        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four
                url="{{ route('admin.report.rider.payment.year') }}?driver_id={{ $driver->id }}"
                :currency="true" variant="info" title="This Year Earning" :value="$widget['this_year_earning']" icon="las la-calendar" />
        </div>

    </div>
    <div class="row responsive-row">
        <div class="col-xxl-12">
            <x-admin.ui.card class="shadow-none h-100 dw-card">
                <x-admin.ui.card.header class="flex-between py-3 gap-2">
                    <h5 class="card-title mb-0 fs-16">@lang('Total Earning')</h5>
                    <div class="d-flex gap-2 flex-wrap flex-md-nowrap">
                        <select class="form-select form-select-sm  form-control">
                            <option value="daily" selected>@lang('Daily')</option>
                            <option value="weekly">@lang('Weekly')</option>
                            <option value="monthly">@lang('Monthly')</option>
                            <option value="yearly">@lang('Yearly')</option>
                            <option value="date_range">@lang('Date Range')</option>
                        </select>
                        <div class="date-picker-wrapper d-none w-100">
                            <input type="text" class="form-control-sm date-picker form-control" name="date"
                                placeholder="@lang('Select Date')">
                        </div>
                    </div>
                </x-admin.ui.card.header>
                <x-admin.ui.card.body>
                    <div id="dwChartArea"> </div>
                </x-admin.ui.card.body>
            </x-admin.ui.card>
        </div>
    </div>
    <div class="row">
        <div class="col-12">
            <x-admin.ui.card class="table-has-filter">
                <x-admin.ui.card.body :paddingZero="true">
                    <x-admin.ui.card.header>
                        <h4 class="card-title">@lang('All Earnings Details')</h4>
                    </x-admin.ui.card.header>
                    <x-admin.ui.table.layout searchPlaceholder="Trx, username"
                        filterBoxLocation="reports.transaction_filter_form">
                        <x-admin.ui.table>
                            <x-admin.ui.table.header>
                                <tr>
                                    <th>@lang('Ride')</th>
                                    <th>@lang('Payment Type')</th>
                                    <th>@lang('Amount')</th>
                                    <th>@lang('Date')</th>
                                </tr>
                            </x-admin.ui.table.header>
                            <x-admin.ui.table.body>
                                @forelse($payments as $payment)
                                    <tr>
                                        <td>
                                            <a href="{{ route('admin.rides.detail', $payment->ride_id) }}">
                                                {{ @$payment->ride->uid }}
                                            </a>
                                        </td>
                                        <td>
                                            @if ($payment->payment_type == Status::PAYMENT_TYPE_CASH)
                                                <span class="badge badge--success">
                                                    @lang('Cash Payment')
                                                </span>
                                            @else
                                                <span class="badge badge--info">
                                                    @lang('Online Payment')
                                                </span>
                                            @endif
                                        </td>
                                        <td>
                                            {{ showAmount($payment->amount) }}
                                        </td>
                                        <td>
                                            <div>
                                                <strong class="d-block ">{{ showDateTime($payment->created_at) }}</strong>
                                                <small class="d-block"> {{ diffForHumans($payment->created_at) }}</small>
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <x-admin.ui.table.empty_message />
                                @endforelse
                            </x-admin.ui.table.body>
                        </x-admin.ui.table>
                        @if ($payments->hasPages())
                            <x-admin.ui.table.footer>
                                {{ paginateLinks($payments) }}
                            </x-admin.ui.table.footer>
                        @endif
                    </x-admin.ui.table.layout>
                </x-admin.ui.card.body>
            </x-admin.ui.card>
        </div>
    </div>
@endsection

@push('style-lib')
    <link rel="stylesheet" type="text/css" href="{{ asset('assets/global/css/flatpickr.min.css') }}">
@endpush

@push('script-lib')
    <script src="{{ asset('assets/admin/js/apexcharts.min.js') }}"></script>
    <script src="{{ asset('assets/admin/js/charts.js') }}"></script>
    <script src="{{ asset('assets/global/js/flatpickr.js') }}"></script>
@endpush

@push('script')
    <script>
        "use strict";
        (function($) {

            let dwChart = barChart(
                document.querySelector("#dwChartArea"),
                @json(__(gs('cur_text'))),
                [{
                    name: 'Spent',
                    data: []
                }],
                [],
            );
            const spentChart = (startDate, endDate) => {
                const url = @json(route('admin.analysis.driver.chart.spent', $driver->id));
                const timePeriod = $(".dw-card").find('select').val();

                if (timePeriod == 'date_range') {
                    $(".dw-card").find('.date-picker-wrapper').removeClass('d-none')
                } else {
                    $(".dw-card").find('.date-picker-wrapper').addClass('d-none')
                }
                const date = $(".dw-card").find('input[name=date]').val();
                const data = {
                    time_period: timePeriod,
                    date: date
                }

                $.get(url, data,
                    function(data, status) {
                        if (status == 'success') {
                            const updatedData = ['Spent'].map(name => ({
                                name,
                                data: Object.values(data).map(item => item[name.toLowerCase() +
                                    '_amount'])
                            }));

                            dwChart.updateSeries(updatedData);
                            dwChart.updateOptions({
                                xaxis: {
                                    categories: Object.keys(data),
                                }
                            });
                        }
                    }
                );
            }
            spentChart();

            $(".dw-card").on('change', 'select', function(e) {
                spentChart();
            });

            $(".dw-card").on('change', '.date-picker', function(e) {
                spentChart();
            });
            $(".date-picker").flatpickr({
                mode: 'range',
                maxDate: new Date(),
            });
        })(jQuery);
    </script>
@endpush


@push('style')
    <style>
        .verification-switch {
            grid-template-columns: repeat(2, 1fr);
        }
    </style>
@endpush
