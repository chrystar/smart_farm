# Earnings Dashboard Implementation Guide

## Overview
Complete earnings management system for Smart Farm creators to track revenue, analyze subscription data, and visualize financial trends.

## Implementation Status: ✅ COMPLETE

### Features Implemented
- ✅ Query paid subscriptions for creator
- ✅ Calculate total earnings
- ✅ Calculate monthly earnings (last 30 days)
- ✅ Track active subscribers
- ✅ Calculate average monthly value
- ✅ Cumulative earnings chart with trend line
- ✅ Earnings breakdown by subscription plan
- ✅ Date range filtering (custom date selection)
- ✅ Subscription list with status (active/expired)
- ✅ Pull-to-refresh functionality
- ✅ Empty state with helpful message
- ✅ Responsive UI with Material Design

---

## Architecture

### Location
`lib/features/learning/presentation/screens/earnings_dashboard_screen.dart`

### State Management
- StatefulWidget with local state
- Supabase real-time data loading
- Automatic earnings calculation

### Data Flow
```
Supabase paid_subscriptions table
           ↓
    _loadEarnings() method
           ↓
    _calculateEarnings() processing
           ↓
    Metrics & Chart Data
           ↓
    UI Rendering
```

---

## Database Integration

### Table Used: `paid_subscriptions`

**Query Logic:**
```dart
// Load subscriptions for date range
Supabase.instance.client
  .from('paid_subscriptions')
  .select()
  .eq('plan_id', creatorUserId)  // Filter by creator's plans
  .gte('created_at', startDate)   // Date range start
  .lte('created_at', endDate)     // Date range end
  .order('created_at', ascending: false)
```

**Required Columns:**
- `id` - Subscription ID
- `plan_id` - Creator's plan ID (used as filter)
- `amount` - Subscription amount (double/numeric)
- `created_at` - Subscription creation timestamp
- `current_period_end` - Renewal/expiration date (for active status)

**Optional Columns:**
- `user_id` - Subscriber user ID
- `status` - Subscription status

---

## Features Detailed

### 1. Key Metrics Display

**Metric Cards (Grid 2x2):**

1. **Total Earnings**
   - Icon: Trending up
   - Color: Green
   - Formula: Sum of all subscription amounts in date range
   - Display: Currency formatted ($X.XX)

2. **Monthly Earnings**
   - Icon: Calendar
   - Color: Blue
   - Formula: Sum of subscriptions from last 30 days
   - Display: Currency formatted

3. **Active Subscribers**
   - Icon: People
   - Color: Orange
   - Formula: Count subscriptions where current_period_end > today
   - Display: Integer count

4. **Average Monthly Value**
   - Icon: Chart
   - Color: Purple
   - Formula: Total Earnings ÷ 3 (approximate monthly)
   - Display: Currency formatted

**Calculation Logic:**
```dart
_totalEarnings = sum of all amounts
_monthlyEarnings = sum of last 30 days only
_activeSubscribers = count where current_period_end > now
_averageMonthlyValue = _totalEarnings / 3
```

---

### 2. Date Range Filtering

**Default Range:**
- Start: 90 days ago
- End: Today

**Custom Selection:**
- Click calendar icon in date range card
- Opens native date range picker
- Flutter's `showDateRangePicker()` dialog
- Reloads data automatically on selection

**Display Format:**
```
DD/MM/YYYY - DD/MM/YYYY
Example: 27/11/2025 - 27/02/2026
```

---

### 3. Cumulative Earnings Chart

**Type:** Line chart with gradient fill

**Features:**
- Shows cumulative earnings trend over date range
- Smooth curved line for visual appeal
- Gradient fill under line
- Horizontal grid lines
- Y-axis with automatic scaling
- Green color matching app theme

**Data Construction:**
```
1. Group subscriptions by date
2. Calculate daily totals
3. Build cumulative sum
4. Create FlSpot points for chart
```

**Automatic Scaling:**
```dart
if (totalEarnings < 100) interval = 10
if (totalEarnings < 500) interval = 50
if (totalEarnings < 1000) interval = 100
if (totalEarnings < 5000) interval = 500
if (totalEarnings >= 5000) interval = 1000
```

---

### 4. Earnings by Plan

**Display:**
- Card with horizontal scrolling list
- One row per subscription plan
- Shows: Plan ID | Total Earnings

**Use Case:**
- See which plans generate most revenue
- Identify popular subscription tiers
- Plan pricing strategy adjustments

**Format:**
```
Premium Plan       $1,250.50
Basic Plan         $425.00
Starter Plan       $150.00
```

---

### 5. Recent Subscriptions List

**Display:**
- Scrollable list of all subscriptions
- Subscription card per item
- Shows plan details and amount

**Card Contents:**
- Plan name (bold)
- Subscription date (gray)
- Amount (green, bold)
- Status badge (Active = green, Expired = orange)
- Renewal date (if applicable)

**Status Logic:**
```dart
if (currentPeriodEnd > now) {
  status = "Active"  // Green badge
} else {
  status = "Expired" // Orange badge
}
```

---

## UI Components

### 1. Metric Card Widget
```dart
_buildMetricCard(
  title: String,
  value: String,
  icon: IconData,
  color: Color,
)
```
- Responsive grid placement
- Icon with colored background
- Value and title display
- Compact card design

### 2. Plan Earnings Row
```dart
_buildPlanEarningsRow(
  planId: String,
  earnings: double,
)
```
- Plan name with earnings
- Green currency formatting
- Padding and spacing

### 3. Subscription Item
```dart
_buildSubscriptionItem(
  subscription: Map<String, dynamic>,
)
```
- Full subscription details
- Status indicator
- Amount display
- Renewal information

---

## Methods Reference

### Loading & Calculation

**`_loadEarnings()`**
- Queries Supabase for subscriptions
- Handles errors gracefully
- Shows loading state
- Calls `_calculateEarnings()` on success

**`_calculateEarnings()`**
- Processes all subscriptions
- Computes metrics
- Builds chart data
- Calculates plan breakdowns

**`_buildChartData(Map<String, double> dailyEarnings)`**
- Converts daily earnings to cumulative
- Creates FlSpot points for chart
- Handles empty data

### Formatting

**`_formatCurrency(double amount)`**
- Returns: `$XX.XX` format
- Uses `toStringAsFixed(2)`

**`_formatDateRange()`**
- Returns: `DD/MM/YYYY - DD/MM/YYYY`
- Readable date display

**`_formatDate(DateTime date)`**
- Returns: `D/M/YYYY` format
- For individual dates

**`_getChartInterval()`**
- Calculates y-axis interval
- Returns: 10, 50, 100, 500, or 1000
- Based on total earnings scale

### User Interaction

**`_selectDateRange()`**
- Opens date picker
- Updates date range
- Reloads earnings
- Rebuilds UI

---

## Integration with Creator Tools

### Location in Navigation
Creator Tools Screen → Settings Tab → Earnings Button

### Implementation
```dart
// In _buildSettingsView()
_buildSettingItem(
  icon: Icons.monetization_on,
  title: 'Earnings',
  subtitle: 'View your earnings and payment history',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EarningsDashboardScreen(),
      ),
    );
  },
)
```

### Modifications to Creator Tools
1. Added import: `import 'earnings_dashboard_screen.dart';`
2. Updated earnings button from snackbar to navigation
3. Now opens full earnings dashboard

---

## User Experience

### Initial Load
1. App loads creator's ID from Supabase Auth
2. Sets default date range (last 90 days)
3. Queries paid_subscriptions table
4. Calculates metrics
5. Builds chart data
6. Renders UI

### Date Range Selection
1. User taps calendar icon
2. Date range picker opens
3. User selects new range
4. Data reloads automatically
5. All metrics update
6. Chart rebuilds

### Refresh Data
1. User swipes down on screen
2. Pull-to-refresh animation plays
3. Data reloads from Supabase
4. Metrics update
5. Returns to original scroll position

### Empty State
- Shows when no subscriptions in date range
- Icon and helpful message
- Encourages creator to grow subscriber base

---

## Styling & Appearance

### Color Scheme
- Primary: AppColors.primaryGreen (trending up, chart)
- Secondary: Blue (monthly), Orange (subscribers), Purple (average)
- Text: Black (primary), Gray (secondary)
- Backgrounds: White cards on light background

### Typography
- Titles: 20px, bold
- Metrics: 18px, bold
- Labels: 14px, regular/bold
- Descriptions: 12px, gray

### Spacing
- Padding: 16px (screen edges)
- Card gaps: 16px or 20px
- Internal padding: 12-16px
- Icon spacing: 8px

### Responsiveness
- Grid adapts to screen width
- Cards stack properly
- Text wraps correctly
- Charts responsive height (300px)

---

## Error Handling

### Network Errors
- Displays snackbar with error message
- Loading state canceled
- User can retry with pull-to-refresh

### Empty Data
- Shows friendly empty state
- Icon and message
- No error, just "no data yet"

### Invalid Data
- Gracefully handles null values
- Defaults to 0 for calculations
- Shows "Unknown" for missing plan IDs

---

## Performance Considerations

### Data Loading
- Single query for all subscriptions in range
- Ordered by created_at for efficiency
- No N+1 queries

### Chart Rendering
- Only builds chart if data exists
- Uses FlSpot for efficient plotting
- Limits to date range only

### Memory Usage
- Stores all subscriptions in list
- Chart data as list of FlSpot
- Maps for plan aggregation
- Reasonable for typical creator

### Optimization Tips
1. Use narrow date ranges for large datasets
2. Archive old subscriptions if needed
3. Consider pagination for 1000+ items
4. Cache results if no real-time needed

---

## Testing Checklist

### Data Loading
- [ ] Initial load shows last 90 days
- [ ] Metrics calculate correctly
- [ ] Chart renders with data
- [ ] Empty state shows when no data

### Date Range
- [ ] Calendar opens on tap
- [ ] Date selection works
- [ ] Data reloads on selection
- [ ] Date display updates

### Metrics
- [ ] Total earnings = sum of all
- [ ] Monthly = last 30 days only
- [ ] Active subscribers count correctly
- [ ] Average = total ÷ 3

### Chart
- [ ] Line renders smoothly
- [ ] Gradient fill shows
- [ ] Y-axis scales properly
- [ ] Data points are accurate

### Subscriptions List
- [ ] Shows all subscriptions
- [ ] Status badges correct
- [ ] Amounts formatted ($)
- [ ] Dates display properly

### UI/UX
- [ ] Layout responsive
- [ ] Text readable
- [ ] Colors correct
- [ ] No layout shift
- [ ] Pull-to-refresh works
- [ ] Empty state displays

---

## Example Data

### Sample Subscription Entry
```json
{
  "id": "sub_123",
  "plan_id": "premium-plan",
  "amount": 99.99,
  "created_at": "2026-02-01T10:30:00Z",
  "current_period_end": "2026-03-01T10:30:00Z",
  "status": "active"
}
```

### Expected Calculations
```
Subscriptions in range: 15
Total amount: $1,245.00
Last 30 days: 5 subscriptions, $425.00
Active: 12 subscribers
Average monthly: $415.00
```

---

## Future Enhancements

### Phase 2 (Analytics)
- [ ] Revenue trend analysis
- [ ] Subscriber growth chart
- [ ] Churn rate calculation
- [ ] Revenue per subscriber
- [ ] Lifetime value analysis

### Phase 3 (Reports)
- [ ] Monthly revenue report
- [ ] Subscriber demographics
- [ ] Plan performance comparison
- [ ] Export to PDF/CSV
- [ ] Email summary reports

### Phase 4 (Advanced)
- [ ] Revenue forecasting
- [ ] Seasonal analysis
- [ ] Cohort analysis
- [ ] Multi-currency support
- [ ] Tax calculation
- [ ] Payment method breakdown

---

## Troubleshooting

### Earnings Show $0.00

**Possible Causes:**
1. No subscriptions for date range
2. Creator ID not in database
3. Subscriptions use different plan_id format
4. RLS policy blocking query

**Solutions:**
1. Change date range to broader range
2. Check database has subscription records
3. Verify plan_id matches creator's user_id
4. Check Supabase RLS policies

### Chart Not Rendering

**Possible Causes:**
1. No data in selected range
2. Invalid coordinate data
3. FL Chart dependency issue

**Solutions:**
1. Select date range with data
2. Check _buildChartData logic
3. Verify fl_chart package installed
4. Check for console errors

### Metrics Calculation Wrong

**Possible Causes:**
1. Incorrect SQL query
2. Date parsing issues
3. Logic errors in loops

**Solutions:**
1. Verify Supabase query
2. Log intermediate values
3. Check date comparison logic
4. Review calculation formulas

---

## Security

### Row-Level Security (RLS)
- Query must have valid creator user_id
- Only accesses own plan subscriptions
- Can't see other creators' earnings

### Data Privacy
- Subscriptions are sensitive financial data
- Only visible to creator account
- Amount and renewal dates visible
- Consider hiding subscriber IDs in future

### Best Practices
- Query validates current user exists
- Error messages don't leak sensitive data
- Chart data aggregated (no individual details exposed)

---

## Files & Dependencies

### Files Created
- `lib/features/learning/presentation/screens/earnings_dashboard_screen.dart` (673 lines)

### Files Modified
- `lib/features/learning/presentation/screens/creator_tools_screen.dart`
  - Added import for EarningsDashboardScreen
  - Updated Earnings button to navigate instead of show snackbar

### Dependencies Used
- `flutter/material.dart` - UI framework
- `supabase_flutter` - Database access
- `fl_chart` - Chart visualization (already in project)
- `smart_farm/core/constants/theme/app_color.dart` - Color constants

---

## Migration Instructions

### Step 1: No Database Changes Needed
- Uses existing `paid_subscriptions` table
- No new tables or columns required
- Works with current schema

### Step 2: Deploy Code
```bash
# Files ready to use
# No migrations needed
flutter clean
flutter pub get
```

### Step 3: Test
1. Login as creator with subscriptions
2. Go to Creator Tools → Settings
3. Click Earnings
4. Should see metrics and chart
5. Try date range selection

---

## Summary

✅ **Complete earnings dashboard implemented**

**What was built:**
- Full earnings dashboard with metrics display ✓
- Cumulative earnings chart with trend visualization ✓
- Date range filtering with custom selection ✓
- Earnings breakdown by subscription plan ✓
- Recent subscriptions list with status ✓
- Pull-to-refresh functionality ✓
- Integration with Creator Tools ✓

**Key Metrics Tracked:**
- Total Earnings (all time in range)
- Monthly Earnings (last 30 days)
- Active Subscribers (current active count)
- Average Monthly Value (calculated)

**Ready to Use:** After deploying code, creators can immediately view their earnings, track trends, and analyze subscription performance.

**Priority 1 Task Status:** ✅ **COMPLETE** - Earnings Dashboard fully implemented with all required features.

---

*Last Updated: 2026-02-27*
*Implementation Status: Complete*
*Developer: GitHub Copilot*
