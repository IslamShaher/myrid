@extends('admin.layouts.app')
@section('panel')
    <div class="row">
        <div class="col-12">
            <x-admin.ui.card>
                <x-admin.ui.card.header>
                    <div class="d-flex justify-content-between gap-2 flex-wrap align-items-center">
                        <h5 class="mb-0 card-title">@lang('Driver Location')</h5>
                        <div class=" text-end">
                            <span class="d-block">
                                @lang('Last Location Fetch At')
                            </span>
                            <div>
                                <span>{{ showDateTime($driver->last_location_fetch_at) }}</span>
                                <span
                                    class="text--danger text-end">({{ diffForHumans($driver->last_location_fetch_at) }})</span>
                            </div>
                        </div>
                    </div>
                </x-admin.ui.card.header>
                <x-admin.ui.card.body>
                    <div class="form-group">
                        <div id="map" style="height: 50vh;"></div>
                    </div>
                </x-admin.ui.card.body>
            </x-admin.ui.card>
        </div>
    </div>
@endsection


@push('breadcrumb-plugins')
    <x-back_btn route="{{ route('admin.driver.detail', $driver->id) }}" />
@endpush

@push('script-lib')
    <script src="https://maps.googleapis.com/maps/api/js?key={{ gs('google_maps_api') }}&libraries=drawing,places&v=3.45.8">
    </script>
@endpush


@push('script')
    <script>
        "use strict";
        (function($) {

            const lat = parseFloat("{{ $driver->current_lat ?? '' }}");
            const lng = parseFloat("{{ $driver->current_lot ?? '' }}");


            function initMap() {
                if (isNaN(lat) || isNaN(lng)) {
                    console.warn("Driver location not available");
                    document.getElementById("map").innerHTML = `
                        <h5 class="d-flex justify-content-center align-items-center h-100 text--warning">
                            Driver location not available at the moment
                        </h5>`;
                    return;
                }

                const location = {
                    lat: lat,
                    lng: lng
                };

                const map = new google.maps.Map(document.getElementById("map"), {
                    zoom: 14,
                    center: location,
                });

                new google.maps.Marker({
                    position: location,
                    map: map,
                    title: "Driver Location",
                });
            }

            window.addEventListener("load", initMap);

        })(jQuery);
    </script>
@endpush


@push('style')
    <style>
        .google-map {
            width: 100%;
            height: 400px;
        }

        #searchBox {
            position: absolute;
            top: 0px;
            left: 334px;
            background: #fff;
            border: none;
            margin-top: 6px;
            height: 25px;
        }

        .pac-container {
            width: 320px !important;
        }
    </style>
@endpush
