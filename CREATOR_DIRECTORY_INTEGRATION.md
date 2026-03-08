# Creator Directory Integration Guide

## Overview

The subscription system is now fully integrated into the Creator Directory (`creator_farmers_screen.dart`). When users browse creators, they can view available subscription plans and subscribe directly from the creator's modal.

## User Flow

### Step 1: Open Creator Directory
```
Home Screen → Creator Directory Tab
```

### Step 2: Browse Creators
- See list of all approved creators
- Search by name
- Filter by newest/oldest

### Step 3: View Creator Details
```
Tap Creator Card → Modal Opens
```

The modal shows:
- Creator profile picture
- Creator display name
- Creator bio
- Subscription plans (if any)

### Step 4: Choose Subscription Plan
For each active subscription plan:
- Plan name (e.g., "Basic")
- Plan price (e.g., "$4.99/month")
- Plan description
- "Tap to subscribe" interaction

### Step 5: Open Checkout
```
Tap Subscription Plan → SubscriptionCheckoutScreen Opens
```

Shows:
- Creator info again (confirmation)
- Full plan details
- Price with monthly billing
- Complete benefits list
- Terms and conditions
- "Subscribe" and "Not Now" buttons

### Step 6: Complete Subscription
```
Tap "Subscribe" → RevenueCat Payment Flow → Confirmation
```

## Code Changes Summary

### 1. Updated Imports (creator_farmers_screen.dart)
```dart
import 'subscription_checkout_screen.dart';
```

### 2. New Widget: _CreatorDetailsSheet
This widget is now a stateful component that:
- Loads subscription plans for the creator
- Displays plans in the modal
- Handles navigation to checkout
- Prevents modal for own creator profiles

### 3. Plan Display Component
```dart
Widget _buildPlanOption(BuildContext context, Map<String, dynamic> plan)
```
- Shows plan in a card
- Displays name, description, price
- Tappable for navigation

## Key Features

### ✅ Features Implemented

1. **Plan Loading**
   - Fetches active plans from database
   - Only shows plans where `is_active = true`
   - Sorted by price (lowest first)

2. **Modal Behavior**
   - Shows plans for other creators
   - Hides plans for own creator
   - Shows "This is Your Creator Profile" for self

3. **Navigation**
   - Tapping plan navigates to checkout
   - Passes creator ID and plan details
   - Modal closes on navigation

4. **Visual Design**
   - Plans shown as cards
   - Price highlighted in green
   - Tappable with visual feedback
   - Clean, minimal layout

### 🔄 Pending Features (RevenueCat Integration)

1. **Purchase Processing**
   - Call RevenueCat SDK
   - Handle payment sheet
   - Validate receipt
   - Save subscription

2. **Error Handling**
   - Network errors
   - User cancellation
   - Payment failures
   - Subscription conflicts

3. **User Feedback**
   - Loading states
   - Success messages
   - Error messages
   - Loading indicators

## Database Queries Used

### 1. Load Plans for Creator
```sql
SELECT * FROM creator_subscription_plans
WHERE creator_id = $1
AND is_active = true
ORDER BY price ASC
```

### 2. Check Subscription
```sql
SELECT * FROM paid_subscriptions
WHERE subscriber_id = $1
AND plan_id = $2
AND status = 'active'
```

## UI Wireflow

```
Creator Directory
    ↓
[List of Creators]
    ↓
Tap Creator Card
    ↓
┌─ Modal Opens ─┐
│ Creator Info  │
│ Bio           │
│ Plans:        │
│  - Basic      │ ← Tap to subscribe
│  - Premium    │ ← Tap to subscribe
│  - VIP        │ ← Tap to subscribe
└───────────────┘
    ↓
SubscriptionCheckoutScreen
    ↓
[RevenueCat Payment Sheet]
    ↓
Success / Failure
```

## Implementation Details

### _CreatorDetailsSheet Properties

```dart
class _CreatorDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> creator;     // Creator data
  final bool isOwnCreator;                 // Is user's own creator profile
}
```

### Plan Loading in initState
```dart
if (!widget.isOwnCreator) {
  _loadPlans();  // Only load if viewing other creator
}
```

### Plan Display Conditions
```dart
if (!widget.isOwnCreator) {
  // Show plans section
  if (_loadingPlans) {
    // Loading indicator
  } else if (_plans.isEmpty) {
    // No plans message
  } else {
    // Display plans
  }
}
```

## Error Handling

### Current Error Handling
- Silent failure if plans can't load
- Debug print for errors
- Falls back to empty plan list

### TODO: Enhanced Error Handling
- User-facing error messages
- Retry logic
- Network error detection
- Specific error types

## Performance Considerations

### Optimizations Applied
1. **Conditional Loading**
   - Plans only load for other creators
   - No unnecessary queries for own profile

2. **Single Order Query**
   - Plans fetched once per modal open
   - Sorted by price on query

3. **State Management**
   - Loading state prevents multiple requests
   - Plans cached in widget state

### Potential Optimizations
- Cache plans in Provider
- Pagination for creators with many plans
- Search filtering
- Favorite plans

## Testing Scenarios

### Scenario 1: Viewing Own Creator Profile
1. Open creator directory
2. Find own creator profile
3. Expected: Modal shows "This is Your Creator Profile"
4. Expected: No subscription plans shown
5. Expected: Owner button disabled

### Scenario 2: Viewing Other Creator with Plans
1. Open creator directory
2. Tap other creator
3. Expected: Modal opens
4. Expected: Plans load and display
5. Expected: Each plan shows name, price, description
6. Expected: Plans sorted by price

### Scenario 3: Viewing Creator with No Plans
1. Open creator directory
2. Tap creator without plans
3. Expected: Modal opens
4. Expected: "No subscription plans available yet" message
5. Expected: No subscribe button

### Scenario 4: Subscribe to Plan
1. Tap subscription plan in modal
2. Expected: Modal closes
3. Expected: SubscriptionCheckoutScreen opens
4. Expected: Correct creator and plan data passed
5. Expected: Checkout displays plan details

## Integration Checklist

- [x] Import SubscriptionCheckoutScreen
- [x] Create _CreatorDetailsSheet widget
- [x] Add plan loading logic
- [x] Build plan option UI
- [x] Handle navigation to checkout
- [x] Prevent modal for own creator
- [x] Show loading state
- [x] Handle empty plans
- [ ] Test all scenarios
- [ ] Add error messages
- [ ] Add loading indicators

## Code Location Reference

### Files Modified
- `/lib/features/learning/presentation/screens/creator_farmers_screen.dart`
  - Added import for SubscriptionCheckoutScreen
  - Refactored _showCreatorDetails method
  - Added _CreatorDetailsSheet widget (160 lines)
  - Added _buildPlanOption method

### Files Created
- `/lib/features/learning/presentation/screens/subscription_checkout_screen.dart`
- `/lib/features/learning/presentation/screens/subscription_plans_screen.dart`
- `/lib/services/revenuecat_service.dart`

### Database
- `supabase/migrations/2026-02-27_create_paid_subscriptions.sql`

### Documentation
- `REVENUECAT_SETUP_DETAILED.md`
- `SUBSCRIPTION_IMPLEMENTATION_CHECKLIST.md`
- `SUBSCRIPTION_QUICK_REFERENCE.md`
- `CREATOR_DIRECTORY_INTEGRATION.md` (this file)

## Next Steps

1. **Test Current Integration**
   - [x] Run app and verify UI renders
   - [ ] Check modal opens correctly
   - [ ] Verify plans load
   - [ ] Test plan navigation

2. **Implement RevenueCat**
   - [ ] Set up RevenueCat account
   - [ ] Add SDK to pubspec.yaml
   - [ ] Initialize in main.dart
   - [ ] Implement purchase flow

3. **Add Access Control**
   - [ ] Check subscription before showing articles
   - [ ] Show paywall for non-subscribed
   - [ ] Allow creators to view own articles

4. **Add Analytics**
   - [ ] Track subscription views
   - [ ] Track subscription attempts
   - [ ] Track successful purchases

## Troubleshooting

### Issue: Plans Not Loading
**Cause:** No plans created for this creator
**Solution:** Create plans in Creator Tools → Plans

**Cause:** Plans have `is_active = false`
**Solution:** Edit plan and set `is_active = true`

### Issue: Modal Not Showing
**Cause:** Creator profile not in database
**Solution:** Creator must complete onboarding first

**Cause:** Not approved as creator
**Solution:** Admin must approve in admin app

### Issue: Navigation Not Working
**Cause:** SubscriptionCheckoutScreen not imported
**Solution:** Add import at top of file ✅ (already done)

**Cause:** Creator data not passed correctly
**Solution:** Check creator.id vs creator.user_id field names

## Future Enhancements

1. **Favorites System**
   - Save favorite creators
   - View favorite subscriptions
   - Quick resubscribe

2. **Recommendations**
   - Recommend plans based on interests
   - Show trending subscriptions
   - Similar creator suggestions

3. **Bulk Actions**
   - Subscribe to multiple creators
   - Manage subscriptions from directory
   - View subscription status

4. **Social Features**
   - Follow without subscribing
   - Share favorite creators
   - Social proof (subscriber count)

5. **Advanced Filtering**
   - Filter by price range
   - Filter by category
   - Filter by rating

## Questions & Answers

**Q: Can users view other users' subscription status?**
A: No, subscription data is private via RLS policies

**Q: Can creators change plan prices after creation?**
A: Not yet, need to implement edit functionality

**Q: What happens to existing subscriptions if plan is deleted?**
A: Subscriptions remain active, plan just can't be purchased again

**Q: Can users subscribe to multiple plans from same creator?**
A: Currently no restriction, but should add per RLS update

## Support

For questions about:
- **RevenueCat Setup:** See REVENUECAT_SETUP_DETAILED.md
- **Database Schema:** See SUBSCRIPTION_IMPLEMENTATION_CHECKLIST.md
- **Overall Progress:** See SUBSCRIPTION_QUICK_REFERENCE.md
- **Code Details:** Check inline comments in source files
