@extends('admin.layouts.app')
@section('panel')
    @php
        $pusherConfig = gs('pusher_config');
    @endphp

    <div class="row responsive-row">
        <div class="col-12">
            <div class="alert alert--info d-flex" role="alert">
                <div class="alert__icon">
                    <i class="las la-info"></i>
                </div>
                <div class="alert__content">
                    <p>
                        @lang('Pusher enables real-time updates or broadcasting in this applications, such as ride status, real time bid placement and more. Please configure it correctly with your API credentials. Follow our documentation for detailed setup instructions')
                    </p>
                </div>
            </div>
        </div>
        <div class="col-12">
            <form method="POST">
                <x-admin.ui.card>
                    <x-admin.ui.card.body>
                        @csrf
                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label>@lang('Pusher App ID') </label>
                                    <input type="text" class="form-control" placeholder="@lang('App ID')"
                                        name="pusher_app_id" value="{{ @$pusherConfig->app_id }}" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label>@lang('Pusher App Key') </label>
                                    <input type="text" class="form-control" placeholder="@lang('App Key')"
                                        name="pusher_app_key" value="{{ @$pusherConfig->app_key }}" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label>@lang('Pusher App Secret') </label>
                                    <input type="text" class="form-control" placeholder="@lang('App Secret')"
                                        name="pusher_app_secret" value="{{ @$pusherConfig->app_secret }}" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label>@lang('Pusher Cluster') </label>
                                    <input type="text" class="form-control" placeholder="@lang('Cluster')"
                                        name="pusher_cluster" value="{{ @$pusherConfig->cluster }}" required>
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

@push('breadcrumb-plugins')
    <a href="https://preview.ovosolution.com/ovoride/documentation/index.html#pusher-setting"
        class="btn btn-outline--success configuration" target="_blank">
        <i class="las la-info"></i> @lang('Documentations')
    </a>
@endpush
