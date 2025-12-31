# Ride Matching Algorithm Summary

## Overview
The ride matching algorithm matches riders who want to share a ride based on proximity and time compatibility. It finds the optimal route sequence that minimizes total travel time overhead while fairly splitting costs.

## Algorithm Flow

### 1. Initial Filtering
- **Search Criteria:**
  - Active shared rides (`RIDE_ACTIVE` status)
  - No second rider assigned yet (`second_user_id` is null)
  - Different from requesting user (can't match own ride)
  - Time window: ±40 minutes from requested time (defaults to now if not specified)

### 2. Proximity Check (Radius Filter)
- Uses **Haversine formula** to calculate straight-line distance
- **Radius: 5 km**
- Both pickup locations must be within 5 km of each other
- Both destination locations must be within 5 km of each other
- Only rides passing this filter proceed to overhead calculation

### 3. Overhead Calculation (Core Algorithm)

For each potential match, the algorithm:

#### 3.1 Calculate Solo Durations
- **Rider 1 (Existing Ride):** Uses stored duration from database (converted to seconds)
- **Rider 2 (New Request):** Calls Google Maps API to get solo trip duration

#### 3.2 Test Route Permutations
Tests 4 possible pickup/dropoff sequences:
1. **S1 → S2 → E1 → E2** (Pickup Rider 1, Pickup Rider 2, Dropoff Rider 1, Dropoff Rider 2)
2. **S1 → S2 → E2 → E1** (Pickup Rider 1, Pickup Rider 2, Dropoff Rider 2, Dropoff Rider 1)
3. **S2 → S1 → E1 → E2** (Pickup Rider 2, Pickup Rider 1, Dropoff Rider 1, Dropoff Rider 2)
4. **S2 → S1 → E2 → E1** (Pickup Rider 2, Pickup Rider 1, Dropoff Rider 2, Dropoff Rider 1)

Where:
- **S1** = Rider 1's pickup point
- **S2** = Rider 2's pickup point
- **E1** = Rider 1's destination
- **E2** = Rider 2's destination

#### 3.3 Calculate Segment Costs
For each permutation:
- Divides route into segments (3 segments for 4 points)
- Calculates distance/duration for each segment using:
  - Haversine distance × 120 seconds/km (assumes ~30 km/h average speed)
  - *Note: Currently uses approximation; can be enhanced with Google Maps API*
- Tracks active riders in the car for each segment
- Splits segment cost equally among active riders
- Calculates total trip duration

#### 3.4 Calculate Overhead
- **Individual Overhead:** `shared_duration - solo_duration` for each rider
- **Total Overhead:** Sum of both riders' overhead
- Selects permutation with **minimum total duration** (most efficient route)

#### 3.5 Fare Calculation
- **Base Fare:** $5.00 per rider
- **Price per km:** $2.00
- **Shared Fare:** Base + (distance portion shared with others)
- **Solo Fare:** Base + (total solo distance × price per km)
- Cost is split proportionally based on who's in the car during each segment

### 4. Result Sorting
- Matches are sorted by **total overhead** (ascending)
- Lower overhead = better match (less detour time)

## Key Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `radius` | 5.0 km | Maximum distance between pickups/destinations |
| `timeWindowMinutes` | ±40 minutes | Time window for matching scheduled rides |
| `baseFare` | $5.00 | Fixed base fare per rider |
| `pricePerKm` | $2.00 | Variable fare per kilometer |
| `speedConstant` | 120 sec/km | Used for duration approximation (~30 km/h) |

## Output Format

Each match returns:
```php
[
    'ride' => [Ride object],
    'sequence' => ['S1', 'S2', 'E1', 'E2'],  // Best route sequence
    'r1_overhead' => 5.2,  // Minutes
    'r2_overhead' => 3.1,  // Minutes
    'total_overhead' => 8.3,  // Minutes
    'r1_fare' => 15.50,  // Dollars
    'r2_fare' => 18.20,  // Dollars
    'r1_solo_fare' => 25.00,  // Dollars (for savings comparison)
    'r2_solo_fare' => 22.00,  // Dollars (for savings comparison)
    'r1_solo' => 1200,  // Seconds
    'r2_solo' => 900,   // Seconds
    'r1_shared' => 1512,  // Seconds
    'r2_shared' => 1086,  // Seconds
    'estimated_pickup_time' => '2024-01-15T10:30:00Z',  // ISO8601
    'estimated_pickup_time_readable' => '10:30',
    'ride_scheduled_time' => '2024-01-15T10:00:00Z',
    'ride_scheduled_time_readable' => 'Jan 15, 2024 10:00'
]
```

## Algorithm Complexity

- **Time Complexity:** O(n × p × s)
  - n = number of potential rides
  - p = permutations (4)
  - s = segments per permutation (3)
  - Currently uses approximation, but could be O(n × p × s × API_calls) if using real API

- **Space Complexity:** O(n) for storing matches

## Limitations & Future Enhancements

1. **Duration Calculation:** Currently uses Haversine approximation; could use Google Maps Distance Matrix API for accuracy
2. **API Calls:** Rider 2 solo duration requires API call; could be optimized with caching
3. **Segment Calculation:** Uses speed constant instead of real-time traffic data
4. **Waypoints API:** Could use Google Maps Waypoints API to optimize route with multiple stops
5. **Multiple Riders:** Currently supports 2 riders; algorithm could be extended for 3+

## Notes

- The algorithm prioritizes **time efficiency** (minimum overhead) over cost
- Cost splitting is **fair** (equal share when both riders are in car)
- Sequence selection ensures **pickups always occur before dropoffs**
- Supports both **immediate** and **scheduled** rides






