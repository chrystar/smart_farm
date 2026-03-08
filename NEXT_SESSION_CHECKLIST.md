# Next Session: Immediate Action Items

## Overview
This document lists the exact steps to continue the subscription system implementation in the next session. The UI layer is complete; the next session should focus on RevenueCat integration.

## Pre-Session Setup (Do This First)

### 1. Read Previous Documentation (15 minutes)
- [ ] Read `SUBSCRIPTION_QUICK_REFERENCE.md` - Quick overview
- [ ] Review `SESSION_COMPLETION_SUMMARY.md` - What was done
- [ ] Skim `REVENUECAT_SETUP_DETAILED.md` - Know what's ahead

### 2. Verify Current State (5 minutes)
- [ ] Run `flutter pub get` to ensure all packages are updated
- [ ] Run `flutter analyze` to check for any lint issues
- [ ] Open app and verify Creator Tools screen shows 5 tabs
  - [ ] Articles
  - [ ] Videos
  - [ ] Subscribers
  - [ ] Plans ← New
  - [ ] Settings

### 3. Test Current UI (10 minutes)
- [ ] Create test creator account if needed
- [ ] Navigate to Creator Tools → Plans tab
- [ ] Click "Create Plan" button
- [ ] Verify dialog opens
- [ ] Cancel dialog (don't save yet)
- [ ] Navigate to Creator Directory
- [ ] Tap a creator
- [ ] Verify modal shows subscription plans section
- [ ] Tap a plan
- [ ] Verify checkout screen opens with correct details

---

## Session 1: RevenueCat Account Setup (60-90 minutes)

### Part A: Create RevenueCat Account (10 minutes)
- [ ] Go to https://www.revenuecat.com/
- [ ] Click "Sign up for free"
- [ ] Create account with email
- [ ] Verify email
- [ ] Complete onboarding questions

### Part B: Create Project (10 minutes)
- [ ] In RevenueCat dashboard, click "New Project"
- [ ] Name it: "SmartFarm"
- [ ] Select "Mobile App"
- [ ] Continue

### Part C: Configure iOS (20 minutes)
Follow these exact steps:
1. [ ] In RevenueCat dashboard, go to Project Settings
2. [ ] Click "App Store"
3. [ ] Note your **App Store Key ID** (you'll enter this)
4. [ ] Go to https://appstoreconnect.apple.com/
5. [ ] Login with Apple developer account
6. [ ] Go to Users and Access → API Keys
7. [ ] Generate new key (keep it safe!)
8. [ ] Note the **Issuer ID**
9. [ ] Download the private key file
10. [ ] Return to RevenueCat and paste:
    - [ ] App Store Key ID
    - [ ] Issuer ID
    - [ ] Private Key (paste content)
11. [ ] Save

**Document:** Save these in a secure location (password manager, etc.)

### Part D: Configure Google Play (20 minutes)
Follow these exact steps:
1. [ ] In RevenueCat dashboard, go to Project Settings
2. [ ] Click "Google Play"
3. [ ] Go to https://console.cloud.google.com/
4. [ ] Create new project named "SmartFarm"
5. [ ] Enable "Google Play Android Developer API"
6. [ ] Create Service Account
7. [ ] Grant "Editor" role
8. [ ] Create JSON key and download
9. [ ] Return to RevenueCat and upload JSON file
10. [ ] Save

**Document:** Keep the JSON file safe

### Part E: Create Subscription Products (10 minutes)
In RevenueCat, go to "Products" and create:

1. **Product 1: Basic Plan**
   - [ ] Product ID: `basic_monthly`
   - [ ] Price: `4.99` (will vary by region)
   - [ ] Billing Period: `Monthly`
   - [ ] Renewal: `Repeating`

2. **Product 2: Premium Plan**
   - [ ] Product ID: `premium_monthly`
   - [ ] Price: `9.99`
   - [ ] Billing Period: `Monthly`
   - [ ] Renewal: `Repeating`

3. **Product 3: VIP Plan**
   - [ ] Product ID: `vip_monthly`
   - [ ] Price: `19.99`
   - [ ] Billing Period: `Monthly`
   - [ ] Renewal: `Repeating`

**Note:** These will be mapped to your actual app store IDs

### Part F: Map to App Stores (10 minutes)
For each product created:

**iOS (App Store):**
- [ ] Go to product settings
- [ ] Under "App Store", add identifier:
  - `com.smartfarm.basic_monthly`
  - `com.smartfarm.premium_monthly`
  - `com.smartfarm.vip_monthly`

**Android (Google Play):**
- [ ] Go to product settings
- [ ] Under "Google Play", add identifier:
  - `com.smartfarm.basic_monthly`
  - `com.smartfarm.premium_monthly`
  - `com.smartfarm.vip_monthly`

**Important:** These IDs must match exactly what you set up in App Store Connect and Google Play Console later

### Part G: Get API Key (2 minutes)
- [ ] In RevenueCat dashboard, go to "Account"
- [ ] Find "API Key" section
- [ ] Copy the **Public API Key** (NOT private key)
- [ ] **Save this value** - you'll need it in code

**Example:** `goog_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefg`

---

## Session 2: Flutter SDK Integration (45-60 minutes)

### Part A: Add Package (5 minutes)
1. [ ] Open terminal in project root
2. [ ] Run:
```bash
cd /Users/ram/Development/projects/smart_farm
flutter pub add purchases_flutter
flutter pub get
```
3. [ ] Verify it's added to `pubspec.yaml`
4. [ ] Run `flutter analyze` - should have no new errors

### Part B: Initialize RevenueCat in main.dart (15 minutes)

1. [ ] Open `lib/main.dart`
2. [ ] Add import at top:
```dart
import 'package:purchases_flutter/purchases_flutter.dart';
```

3. [ ] Find `main()` function
4. [ ] Add initialization before `runApp()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (existing code)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_ANON_KEY',
  );
  
  // NEW: Initialize RevenueCat
  await _initializeRevenueCat();
  
  runApp(const MyApp());
}

Future<void> _initializeRevenueCat() async {
  // Set debug logging
  await Purchases.setLogLevel(PurchasesLogLevel.debug);
  
  // Configure with your API key from RevenueCat dashboard
  PurchasesConfiguration configuration = PurchasesConfiguration(
    'YOUR_REVENUECAT_PUBLIC_KEY' // Replace with actual key
  );
  
  await Purchases.configure(configuration);
}
```

5. [ ] Replace `'YOUR_REVENUECAT_PUBLIC_KEY'` with actual key from Part G above
6. [ ] Save file
7. [ ] Run `flutter analyze` - verify no errors

### Part C: Verify Installation (10 minutes)
1. [ ] Run app:
```bash
flutter run
```
2. [ ] Watch console logs for RevenueCat initialization
3. [ ] Look for: "[PurchasesRevenueCat] Purchases configured successfully"
4. [ ] If error appears, check:
   - [ ] API key is correct (no extra spaces)
   - [ ] purchases_flutter is in pubspec.yaml
   - [ ] No syntax errors in main.dart

### Part D: iOS Specific Setup (15 minutes)
1. [ ] Open `ios/Runner.xcworkspace` in Xcode
2. [ ] Select "Runner" project
3. [ ] Select "Build Settings"
4. [ ] Search for "IPHONEOS_DEPLOYMENT_TARGET"
5. [ ] Verify it's set to **iOS 12.0 or higher**
6. [ ] If not, update it
7. [ ] In Podfile, verify this post-install block exists:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```
8. [ ] Run in simulator:
```bash
flutter run -d iPhone
```
9. [ ] Verify app starts without crashes

### Part E: Android Specific Setup (15 minutes)
1. [ ] Open `android/app/build.gradle`
2. [ ] Verify compileSdkVersion is **34 or higher**:
```gradle
android {
    compileSdkVersion 34
    ...
}
```
3. [ ] Update if needed, then:
```bash
flutter pub get
flutter run -d android
```
4. [ ] Verify app starts on Android emulator/device

---

## Session 3: Purchase Flow Implementation (90-120 minutes)

### Part A: Update SubscriptionCheckoutScreen (30 minutes)
1. [ ] Open `lib/features/learning/presentation/screens/subscription_checkout_screen.dart`
2. [ ] Add import at top:
```dart
import 'package:purchases_flutter/purchases_flutter.dart';
```

3. [ ] Update `_handleSubscription()` method with:
```dart
Future<void> _handleSubscription() async {
  setState(() => _processing = true);
  
  try {
    final plan = widget.plan;
    final productId = plan['revenuecat_product_id'];
    
    // TODO: Check if plan has RevenueCat product ID
    if (productId == null || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not available for purchase yet'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _processing = false);
      return;
    }
    
    // TODO: Get offerings from RevenueCat
    final offerings = await Purchases.getOfferings();
    
    if (offerings.current == null) {
      throw Exception('No offerings found');
    }
    
    // TODO: Find the specific package
    final package = offerings.current!.getPackage(productId);
    
    if (package == null) {
      throw Exception('Product not found: $productId');
    }
    
    // TODO: Initiate purchase
    final customerInfo = await Purchases.purchasePackage(package);
    
    // TODO: Verify purchase was successful
    if (customerInfo.entitlements.active.isNotEmpty) {
      // TODO: Save subscription to database
      await _saveSubscriptionToDB(customerInfo, plan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  } on PurchasesErrorCode catch (e) {
    debugPrint('Purchase error: ${e.error.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.error.message}'),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    debugPrint('Unexpected error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _processing = false);
  }
}

Future<void> _saveSubscriptionToDB(
  CustomerInfo customerInfo,
  Map<String, dynamic> plan,
) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  
  try {
    const uuid = Uuid();
    
    // TODO: Extract subscription info from customerInfo
    final entitlements = customerInfo.entitlements.active;
    final subscription = entitlements.values.first;
    
    await Supabase.instance.client
        .from('paid_subscriptions')
        .insert({
          'id': uuid.v4(),
          'subscriber_id': user.id,
          'plan_id': plan['id'],
          'status': 'active',
          'revenuecat_subscription_id': subscription.identifier,
          'period_start': DateTime.now(),
          'period_end': subscription.expirationDate,
          'auto_renew': subscription.isActive,
        });
  } catch (e) {
    debugPrint('Error saving subscription: $e');
    rethrow;
  }
}
```

4. [ ] Add import for uuid at top:
```dart
import 'package:uuid/uuid.dart';
```

5. [ ] Add _saveSubscriptionToDB method (see code above)

### Part B: Update RevenueCatService (20 minutes)
1. [ ] Open `lib/services/revenuecat_service.dart`
2. [ ] Implement `hasSubscriptionToCreator()`:
```dart
Future<bool> hasSubscriptionToCreator(String creatorId) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  
  try {
    final response = await Supabase.instance.client
        .from('paid_subscriptions')
        .select()
        .eq('subscriber_id', user.id)
        .eq('status', 'active');
    
    if (response.isEmpty) return false;
    
    // Check if any subscription is to this creator
    for (final sub in response) {
      final planResponse = await Supabase.instance.client
          .from('creator_subscription_plans')
          .select('creator_id')
          .eq('id', sub['plan_id'])
          .maybeSingle();
      
      if (planResponse != null && planResponse['creator_id'] == creatorId) {
        return true;
      }
    }
    return false;
  } catch (e) {
    debugPrint('Error checking subscription: $e');
    return false;
  }
}
```

3. [ ] Implement other methods following similar patterns
4. [ ] Add proper error handling and debug logging

### Part C: Test Purchase Flow (40 minutes)
1. [ ] Build and run on iOS simulator
2. [ ] Navigate to Creator Directory
3. [ ] Tap a creator
4. [ ] Tap a subscription plan
5. [ ] Verify checkout screen shows correct plan
6. [ ] Click "Subscribe" button
7. [ ] Watch for:
   - [ ] Loading indicator appears
   - [ ] RevenueCat SDK initializes
   - [ ] Payment sheet would appear (but in sandbox, might show test interface)
   - [ ] Success message appears
8. [ ] Check database:
   - [ ] Open Supabase dashboard
   - [ ] Check `paid_subscriptions` table
   - [ ] Verify row was inserted with correct data

9. [ ] Repeat for Android:
```bash
flutter run -d android
```

### Part D: Error Handling Testing (10 minutes)
Test error scenarios:
- [ ] Cancel payment mid-checkout
- [ ] Invalid payment method
- [ ] Network disconnection
- [ ] Verify error messages display clearly
- [ ] Verify user can retry

---

## Session 4: Article Access Control (60-90 minutes)

### Part A: Update articles_screen.dart (20 minutes)
1. [ ] Open `lib/features/learning/presentation/screens/articles_screen.dart`
2. [ ] Add method to check if article requires subscription:
```dart
Future<bool> _articleRequiresSubscription(String creatorId) async {
  final user = Supabase.instance.client.auth.currentUser;
  
  // Free articles don't require subscription
  // TODO: Add "subscription_required" field to articles table
  // For now, assume all articles are free
  
  return false;
}
```

3. [ ] Update article card tap to check subscription:
```dart
GestureDetector(
  onTap: () async {
    final requiresSubscription = 
        await _articleRequiresSubscription(article['user_id']);
    
    if (requiresSubscription) {
      final hasAccess = await RevenueCatService()
          .hasSubscriptionToCreator(article['user_id']);
      
      if (!hasAccess) {
        // Show paywall
        _showPaywall(article);
        return;
      }
    }
    
    // Navigate to article detail
    Navigator.push(...);
  },
  child: // article card
)
```

4. [ ] Create `_showPaywall()` method with subscribe button

### Part B: Update article_detail_screen.dart (20 minutes)
1. [ ] Open `lib/features/learning/presentation/screens/article_detail_screen.dart`
2. [ ] Check subscription access in initState:
```dart
Future<void> _checkAccess() async {
  final subscription = await RevenueCatService()
      .hasSubscriptionToCreator(article['user_id']);
  
  setState(() {
    _hasAccess = subscription || 
        article['subscription_required'] != true;
  });
}
```

3. [ ] Blur content if no access:
```dart
if (!_hasAccess) {
  return _buildPaywallWidget();
}
```

4. [ ] Show "Subscribe to Read" CTA

### Part C: Test Article Access (20 minutes)
1. [ ] Create article as creator
2. [ ] Login as different user
3. [ ] Try to view article:
   - [ ] Should show paywall
4. [ ] Click "Subscribe" on paywall
5. [ ] Complete purchase
6. [ ] Article should now display fully

---

## Session 5: Webhooks & Earnings Dashboard (TBD)

Once purchase flow is working, next session should:
- [ ] Set up webhook handling
- [ ] Create earnings dashboard
- [ ] Add subscription analytics
- [ ] Implement user subscription management

---

## Testing Checklist Before Each Session

```
Before starting:
  ├─ [ ] flutter pub get
  ├─ [ ] flutter analyze
  ├─ [ ] flutter clean && flutter pub get
  ├─ [ ] Run on iOS simulator
  └─ [ ] Run on Android emulator

After each feature:
  ├─ [ ] No new lint errors
  ├─ [ ] No runtime crashes
  ├─ [ ] Feature works as expected
  ├─ [ ] Error messages are clear
  ├─ [ ] Database shows expected data
  └─ [ ] UI is responsive

Before moving to next session:
  ├─ [ ] All features from current session working
  ├─ [ ] No critical TODOs left
  ├─ [ ] Code is documented
  ├─ [ ] Ready for next phase
  └─ [ ] Success criteria met
```

---

## Quick Reference: File Locations

**Screens to modify:**
- `lib/features/learning/presentation/screens/subscription_checkout_screen.dart`
- `lib/features/learning/presentation/screens/subscription_plans_screen.dart`
- `lib/features/learning/presentation/screens/articles_screen.dart`
- `lib/features/learning/presentation/screens/article_detail_screen.dart`

**Services to modify:**
- `lib/services/revenuecat_service.dart`
- `lib/main.dart` (add RevenueCat init)

**Config files:**
- `pubspec.yaml` (add packages_flutter)
- `ios/Podfile` (verify iOS config)
- `android/app/build.gradle` (verify Android config)

**Database:**
- `supabase/migrations/2026-02-27_create_paid_subscriptions.sql` (already created)

---

## Important Notes

1. **RevenueCat API Key**
   - Get from RevenueCat dashboard
   - Keep it secret (not in git)
   - Use environment variables in production

2. **App Store IDs**
   - Must match exactly between RevenueCat, App Store Connect, and Google Play
   - Example: `com.smartfarm.basic_monthly`
   - Used for product mapping

3. **Testing**
   - Use RevenueCat Sandbox mode for testing
   - Don't use real credit cards
   - Test accounts are free in sandbox

4. **Deployment**
   - Get apps on App Store / Google Play first
   - Then enable payments
   - Test end-to-end in sandbox
   - Go live when ready

---

## Questions to Answer During Implementation

- [ ] How do we handle subscription-required articles?
- [ ] Should free accounts see paywall immediately?
- [ ] How do we show subscription status in article list?
- [ ] Should creators be able to make articles subscription-only?
- [ ] How do we handle regional pricing?
- [ ] What happens during refunds?
- [ ] How long do free trials last (if any)?

---

This checklist should guide the next 2-3 sessions to get RevenueCat fully integrated and working!
