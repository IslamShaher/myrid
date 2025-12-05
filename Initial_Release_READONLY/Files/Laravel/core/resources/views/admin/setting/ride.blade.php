@extends('admin.layouts.app')
@section('panel')
    <form method="POST" enctype="multipart/form-data">
        <x-admin.ui.card>
            <x-admin.ui.card.body>
                @csrf
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>@lang('Minimum Distance for Ride')</label>
                            <div class=" input--group input-group">
                                <input class="form-control" name="min_distance" type="number" step="any" min="0.1"
                                    value="{{ getAmount(gs('min_distance')) }}" required min="1">
                                <span class=" input-group-text">
                                    {{ gs()->distanceUnitName }}
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>@lang('Minimum Fare for The Ride')</label>
                            <div class=" input--group input-group">
                                <input class="form-control" name="min_fare" type="number" step="any"
                                    value="{{ getAmount(gs('min_fare')) }}" required min="1">
                                <span class=" input-group-text"> {{ gs('cur_text') }}</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>
                                @lang('Free Ride Cancellation for Riders')
                                <span data-bs-toggle="tooltip" data-bs-placement="top" type="button"
                                    title="Ride cancellation is not permitted once the free cancellation limit has been exceeded.">
                                    <i class="las la-exclamation-circle"></i>
                                </span>
                            </label>
                            <div class="input--group input-group">
                                <input class="form-control" name="user_cancellation_limit" type="number"
                                    value="{{ gs('user_cancellation_limit') }}" required min="0">
                                <span class="input-group-text">
                                    @lang('times')
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>
                                @lang('Ride Cancellation Penalty Amount for Riders')
                                <span data-bs-toggle="tooltip" data-bs-placement="top" type="button"
                                    title="Ride cancellation will be charged once the free cancellation limit has been exceeded.">
                                    <i class="las la-exclamation-circle"></i>
                                </span>
                            </label>
                            <div class="input--group input-group">
                                <input class="form-control" name="user_cancellation_penalty" type="number"
                                    value="{{ getAmount(gs('user_cancellation_penalty')) }}" required min="0"
                                    step="0.01">
                                <span class="input-group-text">
                                    {{ __(gs('cur_text')) }}
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>
                                @lang('Free Ride Cancellation for Drivers')
                                <span data-bs-toggle="tooltip" data-bs-placement="top" type="button"
                                    title="Ride cancellation is not permitted once the free cancellation limit has been exceeded.">
                                    <i class="las la-exclamation-circle"></i>
                                </span>
                            </label>
                            <div class="input--group input-group">
                                <input class="form-control" name="driver_cancellation_limit" type="number"
                                    value="{{ gs('driver_cancellation_limit') }}" required min="0">
                                <span class="input-group-text">
                                    @lang('times')
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>
                                @lang('Ride Cancellation Penalty for Drivers')
                                <span data-bs-toggle="tooltip" data-bs-placement="top" type="button"
                                    title="Ride cancellation will be charged once the free cancellation limit has been exceeded.">
                                    <i class="las la-exclamation-circle"></i>
                                </span>
                            </label>
                            <div class="input--group input-group">
                                <input class="form-control" name="driver_cancellation_penalty" type="number"
                                    value="{{ getAmount(gs('driver_cancellation_penalty')) }}" required min="0"
                                    step="any">
                                <span class="input-group-text">
                                    {{ __(gs('cur_text')) }}
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>
                                @lang('Maximum Negative Balance of Drivers')
                                <span data-bs-toggle="tooltip" data-bs-placement="top" type="button"
                                    title="If a driver reaches a negative balance, they can no longer join any trips.">
                                    <i class="las la-exclamation-circle"></i>
                                </span>
                            </label>
                            <div class="input--group input-group">
                                <input class="form-control" name="negative_balance_driver" type="number"
                                    value="{{ getAmount(gs('negative_balance_driver')) }}" required max="0">
                                <span class="input-group-text">
                                    {{ __(gs('cur_text')) }}
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>
                                @lang('Ride Automatically Cancel After')
                                <span data-bs-toggle="tooltip" data-bs-placement="top" title="@lang('If no bid is placed during this time, the ride will be automatically canceled.')">
                                    <i class="las la-info-circle"></i>
                                </span>
                            </label>
                            <div class="input-group">
                                <input class="form-control" name="ride_cancel_time" type="number"
                                    value="{{ gs('ride_cancel_time') }}">
                                <span class="input-group-text">@lang('MINUTE')</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>@lang('Tips Suggest Amount')</label>
                            <select name="tips_suggest_amount[]"
                                class="form-control select2-auto-tokenize select2-js-input" multiple required>
                                @foreach (gs('tips_suggest_amount') ?? [] as $k => $tipsAmount)
                                    <option value="{{ $tipsAmount }}" selected>
                                        {{ gs('cur_sym') . getAmount($tipsAmount) }}
                                    </option>
                                @endforeach
                            </select>
                        </div>
                    </div>
                    <div class="form-group col-sm-6">
                        <label> @lang('Ride Distance Unit')</label>
                        <select class="select2 form-control" name="distance_unit" data-minimum-results-for-search="-1">
                            <option value="1" @selected(gs('distance_unit') == Status::KM_UNIT)>@lang('Kilometers')</option>
                            <option value="2" @selected(gs('distance_unit') == Status::MILE_UNIT)>@lang('Miles')</option>
                        </select>
                    </div>
                    <div class="col-12">
                        <x-admin.ui.btn.submit />
                    </div>
                </div>
            </x-admin.ui.card.body>
        </x-admin.ui.card>
    </form>
@endsection
