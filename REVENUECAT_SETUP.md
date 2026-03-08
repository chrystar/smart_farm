# RevenueCat Setup Guide (SmartFarm)

This guide wires SmartFarm’s freemium/premium flow to RevenueCat using the `purchases_flutter` SDK.

## 1) Create RevenueCat Project
1. Sign in to RevenueCat and create a project.
2. Add **iOS** and/or **Android** apps to the project.
3. Copy the **Public SDK keys** for each platform.

## 2) Configure Products & Entitlements
1. Create an **Entitlement** called `premium`.
2. Create a **Subscription** product in App Store Connect / Play Console.
   - Suggested product id: `smartfarm_premium`
3. Add the subscription to a **RevenueCat Offering** (e.g. `default`).
4. Map the product to the `premium` entitlement in RevenueCat.

## 3) Add API Keys to the App
Edit `lib/core/constants/revenuecat_constants.dart`:
```dart
class RevenueCatConfig {
  static const String apiKeyAndroid = 'YOUR_ANDROID_PUBLIC_SDK_KEY';
  static const String apiKeyIos = 'YOUR_IOS_PUBLIC_SDK_KEY';
  static const String entitlementPremium = 'premium';
}
```

## 4) Android Billing Permission
Already added in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="com.android.vending.BILLING"/>
```

## 5) iOS In‑App Purchase Setup
1. In App Store Connect, create the subscription product.
2. Ensure **In‑App Purchase** capability is enabled in Xcode.
3. Use a sandbox tester to validate purchases.

## 6) Test Purchases
1. Run the app on a device/emulator.
2. Open **Subscription** from the drawer.
3. Buy the available package and confirm the UI updates.
4. Tap **Restore Purchases** to verify entitlement restoration.

## 7) Notes
- Freemium is the default (no purchase required).
- Premium unlocks gated features by checking `SubscriptionProvider.isPremium`.
- If you change the entitlement name in RevenueCat, update `entitlementPremium`.

## Troubleshooting
- If no plans show, verify the **Offering** and **Product** are active in RevenueCat.
- If purchases fail, ensure you’re signed in with a test account and the product is approved for testing.
- Check device logs for `Purchases` errors to confirm configuration.
