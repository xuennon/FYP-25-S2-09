# Leaderboard Metrics Display Fix

## Problem
The leaderboard was always showing "TIME" column and time values (like "11s") even when the event was configured by business users to track "distance" metrics. This happened because the code was not correctly parsing the metrics data structure from Firebase.

## Root Cause
The Firebase event data stores metrics as an array format:
```json
{
  "metrics": ["distance"]
}
```

But the code was expecting a map format:
```json
{
  "metrics": {"distance": true}
}
```

This caused the `primaryMetric` getter in the Event model to always fall back to the default "durationSeconds" instead of correctly identifying "distance" as the primary metric.

## Solution
Updated the `primaryMetric` getter in `lib/models/event.dart` to handle both array and map formats:

### Before:
```dart
List<String> availableMetrics = metrics!.keys.toList(); // Only worked for maps
```

### After:
```dart
List<String> availableMetrics = [];

if (metrics is List) {
  // Array format: ["distance", "time"]
  availableMetrics = (metrics as List).cast<String>();
} else if (metrics is Map) {
  // Map format: {"distance": true, "time": false}
  availableMetrics = (metrics as Map).keys.cast<String>().toList();
}
```

## Expected Behavior After Fix
1. **Event with `metrics: ["distance"]`** → Shows "DISTANCE" column with distance values (e.g., "10.00 km")
2. **Event with `metrics: ["elevation"]`** → Shows "ELEVATION" column with elevation values (e.g., "150 m")
3. **Event with `metrics: ["time"]`** → Shows "TIME" column with time values (e.g., "5m 30s")
4. **Event with no metrics** → Defaults to "TIME" column

## Files Modified
- `lib/models/event.dart` - Fixed `primaryMetric` getter to handle array format
- `lib/widgets/leaderboard_widget.dart` - Added debug prints to verify metric handling

## Testing
To test the fix:
1. Navigate to the "hjklnmk" event (has `metrics: ["distance"]`)
2. Verify the leaderboard shows "DISTANCE" column header
3. Verify entries show distance values like "10.00 km" instead of time values like "11s"

## Debug Output
Added debug prints to track metric processing:
- Event model logs the detected metrics and selected primary metric
- Leaderboard widget logs the metric being used for display
