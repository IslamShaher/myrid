@extends('admin.layouts.app')
@section('panel')
    <div class="row responsive-row">
        <div class="col-12">
            <div class="alert alert--info d-flex" role="alert">
                <div class="alert__icon">
                    <i class="las la-info"></i>
                </div>
                <div class="alert__content">
                    <p>
                        @lang('Google Maps is essential for this applications core features like live tracking and routing. Please configure it properly and ensure all required API permissions are enabled. Follow our documentation for detailed setup instructions.')
                    </p>
                </div>
            </div>
        </div>
        <div class="col-12">
            <form method="POST" enctype="multipart/form-data">
                <x-admin.ui.card>
                    <x-admin.ui.card.body>
                        @csrf
                        <div class="row">
                            <div class="col-12">
                                <div class="form-group">
                                    <label>@lang('Google Maps Api')</label>
                                    <input class="form-control" name="google_maps_api" type="text"
                                        value="{{ gs('google_maps_api') }}" required>
                                </div>
                            </div>
                            <div class="col-12">
                                <x-admin.ui.btn.submit />
                            </div>
                        </div>
                    </x-admin.ui.card.body>
                </x-admin.ui.card>
            </form>
        </div>
    </div>
@endsection


