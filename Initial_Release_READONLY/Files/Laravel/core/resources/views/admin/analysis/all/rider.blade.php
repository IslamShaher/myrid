@extends('admin.layouts.app')
@section('panel')
    <div class="row responsive-row">
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.rides.all.rider') }}" :currency="false"
                variant="info" title="Total Ride" :value="$widget['total_ride']" icon="las la-list" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.rides.all.rider.completed') }}" :currency="false"
                variant="success" title="Completed Ride" :value="$widget['completed_ride']" icon="las la-check-double" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.rides.all.rider.canceled') }}" :currency="false"
                variant="danger" title="Canceled Ride" :value="$widget['canceled_ride']" icon="las la-times-circle" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.rides.all.rider.completed') }}" :currency="false"
                variant="success" title="Succesfull Ride" :value="$widget['successful_ride_percentage'] . '%'" icon="las la-percentage" />
        </div>

    </div>
    <div class="row responsive-row">
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.rides.all.rider') }}" :currency="false"
                variant="primary" title="Total Riding Distance" :value="$widget['total_distance_ride'] . ' KM'" icon="las la-road" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.rides.all.rider.completed') }}"
                :currency="false" variant="info" title="Total Riding Time" :value="$widget['total_riding_time'] . ' Minute'" icon="las la-clock" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.reviews.all.rider') }}" :currency="false" variant="warning" title="Average rating"
                :value="$widget['average_rating']" icon="las la-star" />
        </div>
        <div class="col-xxl-3 col-sm-6">
            <x-admin.ui.widget.four url="{{ route('admin.rides.all.rider.completed') }}"
                :currency="true" variant="success" title="Average Fare Per Ride" :value="$widget['average_fare_per_ride']"
                icon="las la-hand-holding-usd" />
        </div>

    </div>
    <div class="row responsive-row">
        <div class="col-xxl-6">
            <x-admin.ui.card class="shadow-none h-100 dw-card">
                <x-admin.ui.card.header class="flex-between py-3 gap-2">
                    <h5 class="card-title mb-0 fs-16">@lang('Total Spending Amount')</h5>
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
        <div class="col-xxl-6">
            <x-admin.ui.card class="tc-card h-100">
                <x-admin.ui.card.header class="py-4">
                    <h5 class="card-title fs-16">@lang('Payment methods used')</h5>
                </x-admin.ui.card.header>
                <x-admin.ui.card.body>
                    <div id="paymentMethodUsedChart"></div>
                </x-admin.ui.card.body>
            </x-admin.ui.card>
        </div>
    </div>

    <div class="row">
        <div class="col-12">
            <x-admin.ui.card>
                <x-admin.ui.card.body :paddingZero=true>
                     <x-admin.ui.card.header>
                        <h4 class="card-title">@lang('Rider Feedback')</h4>
                    </x-admin.ui.card.header>
                    <x-admin.ui.table.layout searchPlaceholder="Search" :renderExportButton="false">
                        <x-admin.ui.table>
                            <x-admin.ui.table.header>
                                <tr>
                                    <th>@lang('Review By')</th>
                                    <th>@lang('Ride ID')</th>
                                    <th>@lang('Rating')</th>
                                    <th>@lang('Date')</th>
                                    <th>@lang('Action')</th>
                                </tr>
                            </x-admin.ui.table.header>
                            <x-admin.ui.table.body>
                                @forelse($reviews as $review)
                                    <tr>
                                        <td>
                                            @if ($review->user_id)
                                                <div
                                                    class="d-flex align-items-end align-items-lg-center gap-2 flex-wrap  flex-column flex-lg-row">
                                                    <div>
                                                        <span
                                                            class="d-block fs-14">{{ @__($review->ride->driver->fullname) }}</span>
                                                        <small class="fs-12">@lang('driver')</small>
                                                    </div>
                                                    <span>
                                                        <i
                                                            class="fa fa-arrow-alt-circle-down text--info d-block d-lg-none"></i>
                                                        <i
                                                            class="fa fa-arrow-alt-circle-right text--info d-none d-lg-block"></i>
                                                    </span>
                                                    <div>
                                                        <span
                                                            class="d-block fs-14">{{ __(@$review->ride->user->fullname) }}</span>
                                                        <small class="fs-12">@lang('rider')</small>
                                                    </div>
                                                </div>
                                            @else
                                                <div
                                                    class="d-flex align-items-end align-items-lg-center gap-2 flex-wrap  flex-column flex-lg-row">
                                                    <div>
                                                        <span
                                                            class="d-block fs-14">{{ __(@$review->ride->user->fullname) }}</span>
                                                        <small class="fs-12">@lang('rider')</small>
                                                    </div>
                                                    <span>
                                                        <i
                                                            class="fa fa-arrow-alt-circle-down text--info d-block d-lg-none"></i>
                                                        <i
                                                            class="fa fa-arrow-alt-circle-right text--info d-none d-lg-block"></i>
                                                    </span>
                                                    <div>
                                                        <span
                                                            class="d-block fs-14">{{ @__($review->ride->driver->fullname) }}</span>
                                                        <small class="fs-12">@lang('driver')</small>
                                                    </div>
                                                </div>
                                            @endif
                                        </td>
                                        <td>
                                            <a href="{{ route('admin.rides.detail', $review->ride_id) }}">
                                                {{ $review->ride->uid }}
                                            </a>
                                        </td>
                                        <td>
                                            <span class="rating badge badge--warning">{{ $review->rating }}</span>
                                        </td>
                                        <td>
                                            <div>
                                                <span class=" d-block">
                                                    {{ showDateTime($review->created_at) }}
                                                </span>
                                                <span class="fs-12 text--info">
                                                    {{ diffForHumans($review->created_at) }}
                                                </span>
                                            </div>
                                        </td>
                                        <td>
                                            <x-admin.ui.btn.details text="Show Review" tag="btn" :data-review="$review" />
                                        </td>
                                    </tr>
                                @empty
                                    <x-admin.ui.table.empty_message />
                                @endforelse
                            </x-admin.ui.table.body>
                        </x-admin.ui.table>
                        @if ($reviews->hasPages())
                            <x-admin.ui.table.footer>
                                {{ paginateLinks($reviews) }}
                            </x-admin.ui.table.footer>
                        @endif
                    </x-admin.ui.table.layout>
                </x-admin.ui.card.body>
            </x-admin.ui.card>
        </div>
    </div>

    <x-admin.ui.modal id="modal">
        <x-admin.ui.modal.header>
            <h4 class="modal-title">@lang('View Review')</h4>
            <button type="button" class="btn-close close" data-bs-dismiss="modal" aria-label="Close">
                <i class="las la-times"></i>
            </button>
        </x-admin.ui.modal.header>
        <x-admin.ui.modal.body>
            <ul class=" list-group list-group-flush">
                <li class=" list-group-item d-flex flex-wrap justify-content-between gap-1 ps-0">
                    <span>@lang('Rating')</span>
                    <span class="rating badge badge--info"></span>
                </li>
                <li class=" list-group-item d-flex flex-wrap justify-content-between gap-1 ps-0">
                    <span>@lang('Review')</span>
                    <span class="review"></span>
                </li>
            </ul>
        </x-admin.ui.modal.body>
    </x-admin.ui.modal>
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
                const url = @json(route('admin.analysis.rider.all.chart.spent'));
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

        (function($) {
            const labels = @json($paymentQuery->pluck('payment_type')->toArray());
            const data = @json($paymentQuery->pluck('total')->toArray());
            const total = data.reduce((a, b) => a + b, 0);
            const paymentTypes = @json($paymentTypes);

            const legendLabels = labels.map((label, index) => {
                const percent = ((data[index] / total) * 100).toFixed(2);
                const labelText = paymentTypes[label] || label;
                return `
            <div class="d-flex flex-column gap-1 align-items-start mb-3 me-1">
                <span>${percent}%</span>
                <span>${labelText}</span>
            </div>`;
            });

            const options = {
                series: data,
                chart: {
                    type: 'donut',
                    height: 420,
                    width: '100%'
                },
                labels: labels.map(label => paymentTypes[label] || label),
                dataLabels: {
                    enabled: false
                },
                legend: {
                    position: 'bottom',
                    markers: {
                        show: false
                    },
                    formatter: function(seriesName, opts) {
                        return legendLabels[opts.seriesIndex];
                    }
                }
            };
            new ApexCharts(document.getElementById('paymentMethodUsedChart'), options).render();
        })(jQuery);

        (function($) {
            "use strict";
            $('.details-btn').on('click', function() {
                var $modal = $('#modal');
                var review = $(this).data('review');
                $modal.find('.rating').text(review.rating)
                $modal.find('.review').text(review.review)
                $modal.modal('show');
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
