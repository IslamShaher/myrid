@extends('errors.app')
@section('content')
    <div class="error-content__footer">
        <p class="error-content__message">
            <span class="title">@lang('Forbidden')</span>
            <span class="text">
                @lang("You don't have the required permissions to access this resource. Please check your access rights.")
            </span>
        </p>
        <a href="{{ route('home') }}" class="btn btn-outline--primary error-btn">
            <span class="btn--icon"><i class="fa-solid fa-house"></i></span>
            <span class="text">@lang('Back to Home')</span>
        </a>
    </div>
@endsection
