@extends('admin.layouts.app')
@section('panel')
    @php
        $whatsappConfig = gs('whatsapp_config');
    @endphp
    <div class="row">
        <div class="col-md-12">
            <x-admin.ui.card>
                <x-admin.ui.card.body>
                    <form method="POST">
                        @csrf
                        <div class="row">
                            <div class="col-md-12">
                                <h6 class="mb-2">@lang('Twilio Configuration')</h6>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label>@lang('Account SID') </label>
                                    <input type="text" class="form-control" placeholder="@lang('Account SID')"
                                        name="account_sid" value="{{ @$whatsappConfig->account_sid }}">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label>@lang('Auth Token') </label>
                                    <input type="text" class="form-control" placeholder="@lang('Auth Token')"
                                        name="auth_token" value="{{ @$whatsappConfig->auth_token }}">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label>@lang('From Number') </label>
                                    <input type="text" class="form-control" placeholder="@lang('From Number')"
                                        name="from_number" value="{{ @$whatsappConfig->from_number }}">
                                </div>
                            </div>
                        </div>
                        <x-admin.ui.btn.submit />
                    </form>
                </x-admin.ui.card.body>
            </x-admin.ui.card>
        </div>
    </div>

    <x-admin.ui.modal id="testWhatsAppModal">
        <x-admin.ui.modal.header>
            <h1 class="modal-title">@lang('Test WhatsApp Setup')</h1>
            <button type="button" class="btn-close close" data-bs-dismiss="modal" aria-label="Close">
                <i class="las la-times"></i>
            </button>
        </x-admin.ui.modal.header>
        <x-admin.ui.modal.body>
            <form action="{{ route('admin.setting.notification.whatsapp.test') }}" method="POST">
                @csrf
                <div class="form-group">
                    <label>@lang('Sent to') </label>
                    <input type="text" name="mobile" class="form-control" placeholder="@lang('Mobile')">
                </div>
                <input type="hidden" name="id">
                <div class="form-group">
                    <x-admin.ui.btn.modal />
                </div>
            </form>
        </x-admin.ui.modal.body>
    </x-admin.ui.modal>
@endsection
@push('breadcrumb-plugins')
    <button type="button" data-bs-target="#testWhatsAppModal" data-bs-toggle="modal" class="btn btn--primary "> <i
            class="fa-regular fa-paper-plane"></i> @lang('Send Test WhatsApp')</button>
@endpush
