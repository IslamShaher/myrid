@extends('admin.layouts.app')
@section('panel')
    <div class="row">
        <div class="col-12">
            <x-admin.ui.card>
                <x-admin.ui.card.header>
                    <div class="d-flex justify-content-between gap-2 flex-wrap align-items-center">
                        <h5 class="mb-0 card-title">@lang('Ride Location')</h5>
                        <div class="text-end">
                            <span class="d-block"> @lang('Pickup Location') : {{ __(@$ride->pickup_location) }} </span>
                            <span> @lang('Destination') : {{ __(@$ride->destination) }} </span>
                        </div>
                    </div>
                </x-admin.ui.card.header>
                <x-admin.ui.card.body>
                    <div class="form-group">
                        <div id="map" style="height: 70vh;"></div>
                    </div>
                </x-admin.ui.card.body>
            </x-admin.ui.card>
        </div>
    </div>
@endsection


@push('breadcrumb-plugins')
    <x-back_btn route="{{ route('admin.rides.detail', $ride->id) }}" />
@endpush



@push('script')
    <script async defer src="https://maps.googleapis.com/maps/api/js?key={{ gs('google_maps_api') }}&callback=initMap">
    </script>
    <script>
        // Your ride data from backend
        const pickup = {
            lat: parseFloat("{{ $ride->pickup_latitude }}"),
            lng: parseFloat("{{ $ride->pickup_longitude }}"),
        };
        const dropoff = {
            lat: parseFloat("{{ $ride->destination_latitude }}"),
            lng: parseFloat("{{ $ride->destination_longitude }}"),
        };

        const rideLocations = @json($rideLocations);
        let map, carMarker, pathPolyline, completedPath;

        function initMap() {
            map = new google.maps.Map(document.getElementById("map"), {
                center: pickup,
                zoom: 10,
            });

            // --- Markers ---
            new google.maps.Marker({
                position: pickup,
                map,
                label: "P",
                icon: {
                    url: "https://maps.google.com/mapfiles/ms/icons/green-dot.png"
                }
            });
            new google.maps.Marker({
                position: dropoff,
                map,
                label: "D",
                icon: {
                    url: "https://maps.google.com/mapfiles/ms/icons/red-dot.png"
                }
            });

            // --- Full route line (gray) ---
            pathPolyline = new google.maps.Polyline({
                path: [pickup, dropoff],
                geodesic: true,
                strokeColor: "#999",
                strokeOpacity: 0.7,
                strokeWeight: 5,
                map,
            });

            // --- Completed path (blue) ---
            completedPath = new google.maps.Polyline({
                path: [],
                geodesic: true,
                strokeColor: "#1e90ff",
                strokeOpacity: 0.9,
                strokeWeight: 6,
                map,
            });

            // --- Car marker ---
            carMarker = new google.maps.Marker({
                position: pickup,
                map,
                icon: {
                    url: "https://maps.google.com/mapfiles/kml/shapes/cabs.png",
                    scaledSize: new google.maps.Size(40, 40)
                }
            });

            // --- Draw live data ---
            updateRidePath(rideLocations);

            @if($ride->status == Status::RIDE_RUNNING || $ride->status == Status::RIDE_ACTIVE)
            setInterval(fetchLiveRideLocation, 2000);
            @endif
        }

        // Update car & path
        function updateRidePath(locations) {
            if (!locations || locations.length === 0) return;

            const pathCoords = locations.map((loc) => ({
                lat: parseFloat(loc.latitude),
                lng: parseFloat(loc.longitude),
            }));

            // Update completed path
            completedPath.setPath(pathCoords);

            // Move car to last location
            const last = pathCoords[pathCoords.length - 1];
            carMarker.setPosition(last);

            // Center map on car
            map.panTo(last);
        }

        // Fetch new ride locations from backend (Laravel route)
        async function fetchLiveRideLocation() {
            try {
                const response = await fetch(`{{ route('admin.rides.live.location', $ride->id) }}`);
                const data = await response.json();
                updateRidePath(data.data.rideLocation);
            } catch (err) {
                console.error("Error fetching ride locations:", err);
            }
        }
        window.initMap = initMap;
    </script>
@endpush
