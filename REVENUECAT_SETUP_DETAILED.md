# RevenueCat Integration Guide

This guide explains how to integrate RevenueCat for handling paid subscriptions in the SmartFarm app.

## Overview

RevenueCat is a platform that simplifies in-app purchase implementation across iOS and Android. It handles:
- Purchase processing
- Subscription management
- Cross-platform consistency
- Receipt validation
- Webhook handling

## Setup Steps

### 1. Create a RevenueCat Account

1. Go to https://www.revenuecat.com/
2. Sign up for a free account
3. Create a new project for SmartFarm
4. Note your **API Key** (you'll need this)

### 2. Configure App Store and Google Play

#### For iOS (App Store):
1. In RevenueCat dashboard, go to Project Settings → App Store
2. Add your Bundle ID (com.smartfarm.app or similar)
3. Upload App Store Connect credentials:
   - App Store Connect Key ID
   - Issuer ID
   - Private Key (from App Store Connect)
4. This allows RevenueCat to validate receipts

#### For Android (Google Play):
1. In RevenueCat dashboard, go to Project Settings → Google Play
2. Add your Google Play Package Name
3. Upload Google Play JSON Key:
   - Go to Google Cloud Console
   - Create a Service Account
   - Generate and download JSON key
   - Upload to RevenueCat
4. Link Google Play Billing Library account

### 3. Create Subscription Products

1. In RevenueCat, go to **Products**
2. Create products matching your subscription plans:
   - Basic Plan: `basic_monthly` (e.g., $4.99/month)
   - Premium Plan: `premium_monthly` (e.g., $9.99/month)
   - VIP Plan: `vip_monthly` (e.g., $19.99/month)

3. Note the **Product IDs** - you'll reference these when creating plans in your app

4. Map products to App Store and Google Play:
   - For each product, add App Store ID and Google Play ID
   - Example:
     - RevenueCat Product: `basic_monthly`
     - App Store ID: `com.smartfarm.basic_monthly`
     - Google Play ID: `com.smartfarm.basic_monthly`

### 4. Update pubspec.yaml

Add RevenueCat package:

```yaml
dependencies:
  purchases_flutter: ^8.0.0
```

Run:
```bash
flutter pub get
```

### 5. Configure in main.dart

Update your main.dart initialization:

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'your_supabase_url',
    anonKey: 'your_anon_key',
  );
  
  // Initialize RevenueCat
  await _initializeRevenueCat();
  
  runApp(const MyApp());
}

Future<void> _initializeRevenueCat() async {
  await Purchases.setLogLevel(PurchasesLogLevel.debug);
  
  PurchasesConfiguration configuration = PurchasesConfiguration(
    "YOUR_REVENUECAT_API_KEY_HERE"
  );
  
  await Purchases.configure(configuration);
}
```

### 6. iOS-Specific Setup (Xcode)

1. Open iOS project: `ios/Runner.xcworkspace`
2. In Xcode, select Runner → Build Settings
3. Search for "IPHONEOS_DEPLOYMENT_TARGET"
4. Set to **iOS 12.0 or higher**
5. In Podfile, add:
   ```
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
       target.build_configurations.each do |config|
         config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
           '$(inherited)',
           'PERMISSION_LOCATION=1',
           'PERMISSION_NOTIFICATIONS=1',
        ]
       end
     end
   end
   ```

### 7. Android-Specific Setup

1. In `android/app/build.gradle`, ensure compileSdk is 34+:
   ```gradle
   android {
       compileSdkVersion 34
       ...
   }
   ```

2. In `android/build.gradle`, add Google Play Billing Library:
   ```gradle
   dependencies {
       classpath 'com.google.android.gms:google-services:4.3.15'
   }
   ```

3. In `android/app/build.gradle`:
   ```gradle
   dependencies {
       implementation 'com.android.billingclient:billing:6.0.0'
   }
   ```

### 8. Create Subscription Plans in SmartFarm

Once RevenueCat is configured, creators can create subscription plans:

1. Creators go to Creator Tools → Plans tab
2. Click "Create Plan"
3. Fill in:
   - Plan Name (Basic, Premium, etc.)
   - Description
   - Monthly Price
   - Benefits list
4. Plan is saved with an empty `revenuecat_product_id` initially

### 9. Connect RevenueCat Products to Plans

Update your `subscription_plans_screen.dart` to save the RevenueCat Product ID:

```dart
// After creating plan in Supabase, update with RevenueCat ID:
await Supabase.instance.client
    .from('creator_subscription_plans')
    .update({
      'revenuecat_product_id': 'basic_monthly',
    })
    .eq('id', planId);
```

### 10. Implement Purchase Flow

In `subscription_checkout_screen.dart`:

```dart
Future<void> _handleSubscription() async {
  final plan = widget.plan;
  final productId = plan['revenuecat_product_id'];
  
  if (productId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product not available'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  try {
    // Get offerings from RevenueCat
    final offerings = await Purchases.getOfferings();
    
    if (offerings.current != null) {
      final package = offerings.current!.getPackage(productId);
      
      if (package != null) {
        // Initiate purchase
        final customerInfo = await Purchases.purchasePackage(package);
        
        // Save subscription to database
        await _saveSubscriptionToDB(customerInfo);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### 11. Handle Subscription Validation

Before showing articles, check if user has valid subscription:

```dart
Future<bool> hasAccessToArticle(String creatorId) async {
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user?.id == creatorId) {
    return true; // Own articles
  }
  
  try {
    final customerInfo = await Purchases.getCustomerInfo();
    
    // Check if user has active subscription to this creator
    final subscriptions = await Supabase.instance.client
        .from('paid_subscriptions')
        .select()
        .eq('subscriber_id', user!.id)
        .eq('plan:creator_id', creatorId)
        .eq('status', 'active');
    
    return subscriptions.isNotEmpty;
  } catch (e) {
    debugPrint('Error checking access: $e');
    return false;
  }
}
```

### 12. Webhook Setup (Backend)

Set up webhooks in RevenueCat to sync subscription data:

1. In RevenueCat dashboard, go to **Integrations**
2. Add webhook for your backend:
   ```
   https://your-supabase-project.functions.supabase.co/update-subscription
   ```
3. Select events:
   - INITIAL_PURCHASE
   - RENEWAL
   - CANCELLATION
   - EXPIRATION

This requires a Supabase Edge Function to handle webhook payloads.

## Testing

### iOS Testing:
- Use Sandbox Account on Test Flight
- RevenueCat provides test user credentials
- Purchases use sandbox receipts

### Android Testing:
- Use Google Play Console's internal test track
- Create test users in Play Console
- Purchases are free in test mode

## Troubleshooting

### Issue: "No offerings found"
- Solution: Make sure products are created in RevenueCat and mapped to app stores

### Issue: "Purchase fails after successful payment"
- Solution: Check that Supabase insert permissions are correct for paid_subscriptions table

### Issue: "Can't access articles after subscribing"
- Solution: Verify RLS policies on articles table check paid_subscriptions correctly

## Next Steps

1. ✅ Database migration created (`2026-02-27_create_paid_subscriptions.sql`)
2. ✅ Subscription plans UI implemented (`subscription_plans_screen.dart`)
3. ✅ Checkout screen created (`subscription_checkout_screen.dart`)
4. ⏳ RevenueCat SDK integration (this guide)
5. ⏳ Purchase flow implementation in checkout screen
6. ⏳ Subscription access checking in articles screen
7. ⏳ Earnings dashboard for creators

## Useful Links

- RevenueCat Docs: https://docs.revenuecat.com/
- RevenueCat Flutter SDK: https://docs.revenuecat.com/docs/flutter
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Google Play Billing Library: https://developer.android.com/google/play/billing

## Additional Resources

- Creator subscription plans schema already in database
- RLS policies configured for secure access
- Payment status tracking built-in
- Multiple subscription tier support ready
