@extends('admin.layouts.app')
@section('panel')
    <form action="{{ route('admin.setting.notification.template.update', ['whatsapp', $template->id]) }}" method="post">
        @csrf
        <x-admin.ui.card>
            <x-admin.ui.card.header class="py-3 d-flex justify-content-between">
                <h4 class="card-title">@lang('WhatsApp Template')</h4>
                <div class="form-check form-switch form--switch pl-0 form-switch-success">
                    <input class="form-check-input" name="whatsapp_status" type="checkbox" role="switch"
                        @checked($template->whatsapp_status)>
                </div>
            </x-admin.ui.card.header>
            <x-admin.ui.card.body>
                <div class="row gy-4">
                    @include('admin.notification.template.nav')
                    @include('admin.notification.template.shortcodes')
                    <div class="col-12">
                        <div class="row">
                            <div class="col-md-12">
                                <div class="form-group">
                                    <label>@lang('Message')</label>
                                    <textarea name="whatsapp_body" rows="10" class="form-control" placeholder="@lang('Your message using short-codes')" required>{{ $template->whatsapp_body }}</textarea>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <x-admin.ui.btn.submit />
            </x-admin.ui.card.body>
        </x-admin.ui.card>
    </form>
@endsection

@push('breadcrumb-plugins')
    <x-back_btn route="{{ route('admin.setting.notification.templates') }}" />
@endpush
