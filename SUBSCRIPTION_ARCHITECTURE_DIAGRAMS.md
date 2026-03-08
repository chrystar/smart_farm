# Subscription System Architecture Diagram

## Complete System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE LAYER                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐│
│  │ Creator Tools    │   │ Creator Farmers  │   │ Articles Screen  ││
│  │ Screen           │   │ Screen           │   │ (Paywall Logic)  ││
│  │                  │   │                  │   │                  ││
│  │ ┌──────────────┐ │   │ ┌──────────────┐ │   │ [Free Article]  ││
│  │ │1. Articles   │ │   │ │ Creator List │ │   │ [Locked Article]││
│  │ │2. Videos     │ │   │ │              │ │   │ with "Subscribe" ││
│  │ │3. Subscribers│ │   │ │ Tap Creator  │ │   │ CTA              ││
│  │ │4. Plans ◀────┼─┼───┼─┤ ↓ Modal      │ │   │                  ││
│  │ │5. Settings   │ │   │ │   Shows Plans│ │   │                  ││
│  │ └──────────────┘ │   │ └──────────────┘ │   │                  ││
│  └────────┬─────────┘   └────────┬─────────┘   └──────────────────┘│
│           │                      │                                  │
│           ▼                      ▼                                  │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ SubscriptionPlansScreen    SubscriptionCheckoutScreen       │  │
│  │                                                             │  │
│  │ Create/Edit/Delete Plans   Creator Info + Plan Details    │  │
│  │ List all plans             Price Display                  │  │
│  │ Show benefits              Benefits List                  │  │
│  │ Active/Inactive status     Terms & Conditions             │  │
│  │                            Subscribe Button               │  │
│  └──────────────────────────────┬──────────────────────────────┘  │
│                                 │                                 │
└─────────────────────────────────┼─────────────────────────────────┘
                                  │
                ┌─────────────────┴──────────────────┐
                │ Purchase Initiation                │
                ▼                                    │
┌───────────────────────────────────────────────────────────────┐   │
│                    REVENUECAT SERVICE LAYER                   │   │
├───────────────────────────────────────────────────────────────┤   │
│                                                               │   │
│  RevenueCatService (Scaffolded)                            │   │
│  ├─ getCreatorPlans()                                      │   │
│  ├─ getUserSubscriptions()                                 │   │
│  ├─ hasSubscriptionToCreator()                            │   │
│  ├─ purchaseSubscription() ◀──────────────────────────────┼───┘
│  ├─ restorePurchases()                                   │
│  └─ cancelSubscription()                                 │
│                                                           │
│  [TODO: Implement with RevenueCat SDK]                 │
└──────────────────┬────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────┐
│            REVENUECAT PAYMENT PROCESSING                    │
│                                                             │
│  ┌──────────────────────┐      ┌──────────────────────┐   │
│  │   Apple App Store    │      │   Google Play Store  │   │
│  │                      │      │                      │   │
│  │  In-App Purchase     │      │  Billing Library     │   │
│  │  Sandbox Testing     │      │  Test Accounts       │   │
│  │  Receipt Validation  │      │  Real Billing        │   │
│  └──────────┬───────────┘      └──────────┬───────────┘   │
│             │                             │                │
│             └─────────────┬────────────────┘                │
│                           ▼                                │
│                  RevenueCat Servers                        │
│                  - Receipt Validation                      │
│                  - Subscription Management                 │
│                  - Webhook Events                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                    SUPABASE DATABASE LAYER                  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │ creator_subscription_plans                         │     │
│  ├────────────────────────────────────────────────────┤     │
│  │ id (PK)                                            │     │
│  │ creator_id (FK) ────────────────────────┐          │     │
│  │ name                                     │          │     │
│  │ description                              │          │     │
│  │ price                                    │          │     │
│  │ currency                                 │          │     │
│  │ benefits (array)                         │          │     │
│  │ is_active                                │          │     │
│  │ revenuecat_product_id ◀─────────────┐   │          │     │
│  │ stripe_price_id                      │   │          │     │
│  │ created_at / updated_at              │   │          │     │
│  └────────────────────────────────────────┴──┤          │     │
│                                              │          │     │
│  ┌────────────────────────────────────────────┼──┐      │     │
│  │ paid_subscriptions                         │  │      │     │
│  ├────────────────────────────────────────────┼──┤      │     │
│  │ id (PK)                                    │  │      │     │
│  │ subscriber_id (FK) ─ auth.users            │  │      │     │
│  │ plan_id (FK) ────────────────────────────────┤      │     │
│  │ status (active|canceled|expired|on_hold)  │  │      │     │
│  │ revenuecat_subscription_id                 │  │      │     │
│  │ stripe_subscription_id                     │  │      │     │
│  │ period_start / period_end                  │  │      │     │
│  │ auto_renew                                 │  │      │     │
│  │ canceled_at                                │  │      │     │
│  │ created_at / updated_at                    │  │      │     │
│  └────────────────────────────────────────────────┘      │     │
│                       │                                 │     │
│                       ▼                                 ▼     │
│  ┌──────────────────────────┐  ┌──────────────────────────┐  │
│  │ RLS Policies             │  │ creator_profiles         │  │
│  ├──────────────────────────┤  ├──────────────────────────┤  │
│  │ Plans:                   │  │ user_id (PK)            │  │
│  │ - Public read            │  │ display_name            │  │
│  │ - Creator create/update/ │  │ bio                     │  │
│  │   delete own             │  │ profile_picture_url     │  │
│  │                          │  │ approved                │  │
│  │ Subscriptions:           │  │ created_at              │  │
│  │ - User manages own       │  └──────────────────────────┘  │
│  │ - Creator views own subs │                               │
│  └──────────────────────────┘                               │
│                                                              │
│  Storage Buckets:                                          │
│  ├─ profile-pictures/                                     │
│  └─ article-images/                                       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

### Create Subscription Plan Flow
```
Creator → Creator Tools Screen
    ↓
Tap "Plans" Tab
    ↓
SubscriptionPlansScreen Loads
    ↓
Click "Create Plan"
    ↓
_CreatePlanDialog Opens
    ↓
Fill: Name, Price, Benefits
    ↓
Click "Create"
    ↓
Save to creator_subscription_plans
    ↓
Plan Added to List
```

### Subscribe to Plan Flow
```
User → Creator Directory
    ↓
Tap Creator Card
    ↓
_CreatorDetailsSheet Opens
    ↓
Load Plans for Creator
    ↓
Display Plans in Modal
    ↓
Tap Plan
    ↓
SubscriptionCheckoutScreen Opens
    ↓
Fill Plan Details
    ↓
Tap "Subscribe"
    ↓
[RevenueCat SDK - Payment Processing]
    ↓
Receipt Validation
    ↓
Save to paid_subscriptions Table
    ↓
User Gets Access
```

## Component Interaction Diagram

```
                    ┌─ creator_farmers_screen.dart
                    │
                    ├─ _showCreatorDetails()
                    │  └─ _CreatorDetailsSheet
                    │     ├─ _loadPlans()
                    │     │  └─ Supabase Query
                    │     │
                    │     └─ _buildPlanOption()
                    │        └─ Navigate to SubscriptionCheckoutScreen
                    │
                    └─ SubscriptionCheckoutScreen
                       ├─ _loadCreatorProfile()
                       │  └─ Supabase Query
                       │
                       └─ _handleSubscription()
                          ├─ Call RevenueCatService.purchaseSubscription()
                          ├─ Get Offerings from RevenueCat
                          ├─ Initiate Purchase
                          └─ Save to Database


                    ┌─ creator_tools_screen.dart
                    │
                    ├─ _buildContent() → case 3:
                    │  └─ _buildPlansView()
                    │     └─ SubscriptionPlansScreen()
                    │
                    └─ SubscriptionPlansScreen
                       ├─ _loadPlans()
                       │  └─ Supabase Query
                       │
                       ├─ _addPlan()
                       │  └─ _CreatePlanDialog
                       │
                       ├─ _savePlan()
                       │  └─ Supabase Insert
                       │
                       ├─ _deletePlan()
                       │  └─ Supabase Delete
                       │
                       └─ _buildPlanCard()
                          └─ Display Plan Details
```

## State Management Flow

```
⊕ = State Variable
→ = State Update

CreatorFarmersScreen
├─ _creators ⊕
├─ _currentUserId ⊕
├─ _searchQuery ⊕
└─ _showCreatorDetails()
   └─ _CreatorDetailsSheet
      ├─ _plans ⊕
      │  → Updated by _loadPlans()
      │  → Cleared on modal close
      │
      └─ _loadingPlans ⊕
         → true at start
         → false after load/error


CreatorToolsScreen
├─ _selectedIndex ⊕
│  → Updated by bottom nav tap
│  → case 3 shows SubscriptionPlansScreen
│
└─ SubscriptionPlansScreen
   ├─ _plans ⊕
   │  → Loaded in initState
   │  → Updated on create/delete
   │
   └─ _loading ⊕
      → Updated by _loadPlans()
      → Rebuilds UI on change
```

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                      RLS POLICIES                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ creator_subscription_plans:                                 │
│ ├─ ANYONE CAN: SELECT (public read)                        │
│ ├─ CREATOR: INSERT own plans                               │
│ ├─ CREATOR: UPDATE own plans                               │
│ └─ CREATOR: DELETE own plans                               │
│                                                              │
│ paid_subscriptions:                                          │
│ ├─ SUBSCRIBER: SELECT own subscriptions                    │
│ ├─ SUBSCRIBER: INSERT (purchase)                           │
│ ├─ SUBSCRIBER: UPDATE own subscriptions                    │
│ ├─ SUBSCRIBER: DELETE (cancel) own                         │
│ └─ CREATOR: SELECT own subscriptions                       │
│                                                              │
│ creator_profiles:                                            │
│ ├─ ANYONE CAN: SELECT approved creators                    │
│ ├─ ANYONE CAN: VIEW profile_picture_url                    │
│ └─ CREATOR: UPDATE own profile                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  AUTHENTICATION FLOW                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  User Action → Check Auth Token → RLS Policy → DB Query   │
│      │              │                    │                  │
│      │              └─ Attached to every request            │
│      │                                                      │
│      └─ Only creator can see/edit own plans               │
│         Only user can see own subscriptions               │
│         Public can see active plans                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Webhook Event Flow

```
┌──────────────────────────────────┐
│    RevenueCat Event Occurs       │
│    ├─ INITIAL_PURCHASE          │
│    ├─ RENEWAL                   │
│    ├─ CANCELLATION              │
│    └─ EXPIRATION                │
└────────────────────┬─────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  RevenueCat Webhook    │
        │  POST to /webhook      │
        └────────────┬───────────┘
                     │
                     ▼
    ┌─────────────────────────────────┐
    │  Supabase Edge Function         │
    │  revenuecat-webhook             │
    │  ├─ Validate signature          │
    │  ├─ Extract subscription info   │
    │  ├─ Update paid_subscriptions   │
    │  │  ├─ Set status = 'active'   │
    │  │  ├─ Update period_end       │
    │  │  └─ Clear canceled_at       │
    │  └─ Return success             │
    └─────────────────┬───────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  Database Updated      │
        │  Subscription Status   │
        │  Reflects in App       │
        └────────────────────────┘
```

## File Structure with Dependencies

```
smart_farm/
│
├── lib/
│   ├── main.dart
│   │   └─ Initialize RevenueCat ⓘ
│   │
│   ├── features/
│   │   └── learning/
│   │       └── presentation/
│   │           └── screens/
│   │               ├── creator_tools_screen.dart ✓
│   │               │   └─ imports SubscriptionPlansScreen
│   │               │
│   │               ├── creator_farmers_screen.dart ✓
│   │               │   └─ imports SubscriptionCheckoutScreen
│   │               │
│   │               ├── subscription_plans_screen.dart ✓
│   │               │   ├─ Manages plans
│   │               │   └─ Uses Supabase
│   │               │
│   │               ├── subscription_checkout_screen.dart ✓
│   │               │   ├─ Checkout UI
│   │               │   └─ Calls RevenueCatService
│   │               │
│   │               └── article_detail_screen.dart
│   │                   └─ TODO: Check subscription access
│   │
│   └── services/
│       ├── revenuecat_service.dart ✓
│       │   ├─ purchaseSubscription() [TODO]
│       │   ├─ getUserSubscriptions() [TODO]
│       │   └─ hasSubscriptionToCreator() [TODO]
│       │
│       └── supabase_service.dart
│           └─ Database queries
│
├── supabase/
│   └── migrations/
│       └── 2026-02-27_create_paid_subscriptions.sql ✓
│
├── pubspec.yaml
│   └─ TODO: Add purchases_flutter
│
└── docs/
    ├── REVENUECAT_SETUP_DETAILED.md ✓
    ├── SUBSCRIPTION_IMPLEMENTATION_CHECKLIST.md ✓
    ├── SUBSCRIPTION_QUICK_REFERENCE.md ✓
    └── CREATOR_DIRECTORY_INTEGRATION.md ✓

Legend:
✓ = Completed
ⓘ = Pending
[TODO] = Not yet implemented
```

## Database Relationship Diagram

```
        ┌─ creator_subscription_plans ─────────────┐
        │                                          │
        │  Columns:                               │
        │  ├─ id (UUID) ◄─────────────┐          │
        │  ├─ creator_id (FK)          │          │
        │  │   ↓                        │          │
        │  │  creator_profiles          │ paid_subscriptions
        │  │    user_id ────────────────┼─────┤ plan_id
        │  ├─ name                     │          │
        │  ├─ price                    │          │ Columns:
        │  ├─ benefits[]               │          │ ├─ id (UUID)
        │  ├─ revenuecat_product_id    │          │ ├─ plan_id (FK) ───┘
        │  └─ is_active                │          │ ├─ subscriber_id
        │                              │          │ │   ↓
        └──────────────────────────────┼─────────│ auth.users
                                       │          │
                                       │          ├─ status
                                       │          ├─ period_start
                                       │          ├─ period_end
                                       │          └─ auto_renew
                                       │
                                       └─ Many-to-Many Through Table
```

## Summary

The subscription system is architected as:

1. **UI Layer** (4 screens) - User interactions
2. **Service Layer** (RevenueCatService) - Business logic
3. **Payment Layer** (RevenueCat) - Secure payment processing
4. **Data Layer** (Supabase) - Persistent data storage
5. **Security Layer** (RLS) - Access control

All components are integrated with clear data flows and proper separation of concerns.
