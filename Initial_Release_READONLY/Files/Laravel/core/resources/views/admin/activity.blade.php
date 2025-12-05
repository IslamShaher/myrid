@extends('admin.layouts.app')
@section('panel')
    <div class="row gy-3">
        <div class="col-12">
            <ul class="notification-list">
                @forelse ($activities->groupBy('date') as $date => $items)
                    <li class="notification-count mb-3">
                        {{ $date }}
                        <span class="badge badge--danger ms-2">{{ $items->count() }}</span>
                    </li>
                    @foreach ($items as $activity)
                        <li class="notification-item mb-3">
                            <div class="notification-item__thumb">
                                @if ($activity->admin)
                                    @if ($activity->admin->image)
                                        <img class="fit-image rounded-circle" src="{{ $activity->admin->image_src }}"
                                            alt="Admin Image">
                                    @else
                                        <span class="name-short-form">
                                            @lang('N/A')
                                        </span>
                                    @endif
                                @endif
                            </div>
                            <div class="notification-item__info">
                                <span class="notification-title me-2 fw-600">
                                    {{ __($activity->activity) }}<br>
                                    <span class="time fs-12">
                                        {{ showDateTime($activity->created_at, gs('time_format')) }},
                                        {{ diffForHumans($activity->created_at) }}
                                    </span>
                                </span>
                                <small>
                                    {{ __($activity->remark) }}
                                </small>
                            </div>
                        </li>
                    @endforeach
                @empty
                    <li class="notification-empty">
                        <x-admin.other.card_empty_message />
                    </li>
                @endforelse
            </ul>
        </div>
        @if ($activities->hasPages())
            <div class="col-12">
                {{ paginateLinks($activities) }}
            </div>
        @endif
    </div>
@endsection


@push('style')
    <style>
        .user-thumb {
            width: 40px;
            height: 40px;
        }

        .user-thumb img {
            width: 100%;
            height: 100%;
            border-radius: 50%;
            object-fit: cover;
        }
    </style>
@endpush
