# User Journey: Subscription System

## Complete User Flows

### Journey 1: Creator Setting Up Subscription Plans

```
START: Creator has been approved
  │
  ▼
Open SmartFarm App → Creator Dashboard
  │
  ├─ Available Options:
  │  ├─ Articles
  │ │  ├─ Videos
  │  ├─ Subscribers
  │  ├─ Plans ◀────── USER TAPS HERE
  │  └─ Settings
  │
  ▼
Plans Management Screen Loads
  │
  ├─ User sees:
  │  ├─ "Your Subscription Plans" header
  │  ├─ "Create Plan" button
  │  └─ Empty state (if first time)
  │
  ▼
Creator Clicks "Create Plan"
  │
  ▼
Create Plan Dialog Opens
  │
  ├─ Form Fields:
  │  ├─ Plan Name (e.g., "Basic")
  │  ├─ Description (e.g., "Early access to articles")
  │  ├─ Monthly Price (e.g., "4.99")
  │  ├─ Benefits List:
  │  │  ├─ Add Benefit 1 (e.g., "Early access")
  │  │  ├─ Add Benefit 2 (e.g., "Exclusive content")
  │  │  └─ Add Benefit N...
  │
  ▼
Creator Fills Form & Clicks "Create"
  │
  ├─ Validation:
  │  ├─ Plan Name: Required ✓
  │  ├─ Price: Valid decimal ✓
  │  └─ Benefits: Optional ✓
  │
  ▼
Dialog Closes
  │
  ▼
Plan Saved to Database
  │
  ├─ Event: INSERT into creator_subscription_plans
  │  ├─ creator_id = current user
  │  ├─ name = "Basic"
  │  ├─ price = 4.99
  │  ├─ is_active = true
  │  └─ benefits = ["Early access", "Exclusive"]
  │
  ▼
Success Message: "Plan created successfully!"
  │
  ▼
Plans List Updates
  │
  ├─ Shows new plan in card format:
  │  ├─ Plan name: "Basic"
  │  ├─ Price: "$4.99/month"
  │  ├─ Active badge (green)
  │  ├─ Benefits listed
  │  └─ Menu (Edit, Delete)
  │
  ▼
Creator Can:
  ├─ Create more plans
  ├─ Edit plan (UI ready, backend TODO)
  ├─ Delete plan (with confirmation)
  └─ View all their plans

END: Creator has subscription plans ready
```

---

### Journey 2: User Browsing and Subscribing to Creator

```
START: Regular user (farmer) is logged in
  │
  ▼
Open Creator Directory
  │
  ├─ User sees:
  │  ├─ Search bar
  │  ├─ List of approved creators
  │  ├─ Creator cards with:
  │  │  ├─ Profile picture
  │  │  ├─ Display name
  │  │  └─ Bio preview
  │  │
  │  └─ Sort options (Newest, etc.)
  │
  ▼
User Taps Creator Card
  │
  ├─ Looks for a creator with plans
  │  (e.g., "John the Farmer" who offers subscriptions)
  │
  ▼
Creator Details Modal Opens
  │
  ├─ User sees:
  │  ├─ Creator profile picture (larger)
  │  ├─ Creator name: "John the Farmer"
  │  ├─ Creator bio
  │  ├─ About section
  │  │
  │  └─ Subscription Plans Section:
  │     ├─ "Subscribe to this Creator"
  │     ├─ Plan 1: "Basic" - $4.99/month
  │     │  ├─ Description
  │     │  └─ [Tap to select]
  │     │
  │     ├─ Plan 2: "Premium" - $9.99/month
  │     │  ├─ Description
  │     │  └─ [Tap to select]
  │     │
  │     └─ Plan 3: "VIP" - $19.99/month
  │        ├─ Description
  │        └─ [Tap to select]
  │
  ▼
User Taps Plan: "Premium" ($9.99/month)
  │
  ├─ Modal closes
  ├─ Navigation triggered
  │
  ▼
Subscription Checkout Screen Opens
  │
  ├─ User sees:
  │  ├─ Creator info reminder:
  │  │  ├─ Profile picture
  │  │  ├─ Name: "John the Farmer"
  │  │  └─ "You'll subscribe to this creator"
  │  │
  │  ├─ Plan Details Card:
  │  │  ├─ Plan name: "Premium"
  │  │  ├─ Plan description
  │  │  ├─ Price: "$9.99 /month"
  │  │  │
  │  │  └─ What's included:
  │  │     ├─ ✓ Early access to articles
  │  │     ├─ ✓ Exclusive videos
  │  │     ├─ ✓ Direct messaging
  │  │     └─ ✓ Monthly newsletter
  │  │
  │  ├─ Subscription Terms:
  │  │  ├─ Renews automatically every month
  │  │  ├─ Cancel anytime
  │  │  ├─ Immediate access to benefits
  │  │  └─ Charged through app store
  │  │
  │  └─ Buttons:
  │     ├─ "Subscribe for $9.99/month" (green)
  │     └─ "Not Now" (outline)
  │
  ▼
User Reviews Information
  │
  ├─ Decides this is a good value
  │ │ (Can cancel anytime)
  │
  ▼
User Clicks "Subscribe for $9.99/month"
  │
  ├─ Loading indicator appears
  │
  ▼
[FUTURE: RevenueCat Integration]
  │
  ├─ App Calls RevenueCat SDK
  ├─ App Store/Google Play Payment Sheet Opens
  │
  ├─ User Options:
  │  ├─ Complete payment with saved method
  │  ├─ Add new payment method
  │  ├─ Cancel payment
  │  └─ Face ID / Fingerprint auth
  │
  ▼
User Completes Payment
  │
  ├─ App Store/Google Play processes charge
  ├─ Receipt generated
  ├─ RevenueCat validates receipt
  │
  ▼
Subscription Saved to Database
  │
  ├─ Event: INSERT into paid_subscriptions
  │  ├─ subscriber_id = current user
  │  ├─ plan_id = premium plan
  │  ├─ status = "active"
  │  ├─ period_start = today
  │  ├─ period_end = today + 30 days
  │  ├─ auto_renew = true
  │  └─ revenuecat_subscription_id = receipt ID
  │
  ▼
Success Message: "Subscription activated!"
  │
  ▼
Screen Closes, User Returns to Directory
  │
  ▼
User Now Has Access To:
  │
  ├─ All of "John the Farmer's" articles
  ├─ Exclusive subscriber content
  ├─ Premium features
  └─ Benefits listed in plan

END: User is now subscriber to "John the Farmer"
```

---

### Journey 3: User Viewing Subscriber Content

```
START: Subscriber is browsing articles
  │
  ▼
Open Articles Screen
  │
  ├─ User sees:
  │  ├─ Free articles (no lock)
  │  │  ├─ "How to Plant Vegetables" by Sarah
  │  │  └─ [Tap to read]
  │  │
  │  └─ Subscriber articles (lock icon)
  │     ├─ "Advanced Farming Techniques" by John
  │     │  └─ [Locked - Tap to read / Subscribe]
  │     │
  │     └─ "Seasonal Guide 2026" by Mary
  │        └─ [Locked - Tap to read / Subscribe]
  │
  ▼
User (Already Subscriber) Taps Subscriber Article
  │
  ├─ "Advanced Farming Techniques" by John
  │
  ▼
Article Detail Screen Opens
  │
  ├─ User sees:
  │  ├─ Article title
  │  ├─ Article image
  │  ├─ Creator info: "John the Farmer"
  │  ├─ Full article content (no blur)
  │  ├─ Subscribe badge removed
  │  └─ [Can read fully]
  │
  ▼
User Reads Article
  │
  ├─ Access granted because:
  │  ├─ Creator = John
  │  ├─ Subscriber check = true
  │  ├─ Status = active
  │  ├─ Period = still valid
  │  └─ Access = GRANTED ✓
  │
  ▼
User Scrolls to Bottom
  │
  ├─ Sees article stats:
  │  ├─ Views: 1,234
  │  ├─ Category: Farming
  │  └─ Published: 2 days ago
  │
  ▼
User Completes Reading

END: Subscriber enjoyed exclusive content
```

---

### Journey 4: User Without Subscription Trying to View Content

```
START: Non-subscriber viewing articles
  │
  ▼
User Taps Locked Article
  │
  ├─ "Advanced Farming Techniques" by John
  │
  ▼
Article Detail Screen Opens (PAYWALL MODE)
  │
  ├─ User sees:
  │  ├─ Article preview (first paragraph only)
  │  ├─ Blurred content below
  │  │
  │  ├─ Paywall Message:
  │  │  ├─ "Subscribe to read this article"
  │  │  ├─ "Get full access to all of John's content"
  │  │  │
  │  │  └─ Button: "Subscribe Now" (green)
  │  │
  │  └─ Creator info card:
  │     ├─ Profile: "John the Farmer"
  │     ├─ Plan preview: "Premium - $9.99/month"
  │     └─ Benefits hint: "Get all benefits"
  │
  ▼
User Clicks "Subscribe Now"
  │
  ├─ Navigates to Creator Farmers Screen
  │ │ (Pre-selected creator: John)
  │
  ▼
Creator Modal Opens
  │
  ├─ Shows John's profile
  ├─ Shows his subscription plans
  │
  ▼
User Selects Plan & Completes Purchase
  │
  ├─ (Follows Journey 2: User Subscribing)
  │
  ▼
Returns to Article
  │
  ├─ Access check re-runs
  ├─ Subscription found and active
  │
  ▼
Article Now Fully Visible
  │
  ├─ Full content displayed
  ├─ No blur or paywall
  │ 
  ▼
User Reads Full Article

END: User gained access through subscription
```

---

### Journey 5: Subscription Lifecycle Management

```
START: User has active subscription
  │
  ▼
User's Subscription Progress
  │
  ├─ Day 1: Subscription created
  │  ├─ Status: active
  │  ├─ period_start: today
  │  ├─ period_end: today + 30 days
  │  └─ auto_renew: true
  │
  ├─ Days 2-29: Subscription continues
  │  ├─ User has full access
  │  ├─ Can read all content
  │  ├─ Gets all benefits
  │  └─ Auto-renews enabled
  │
  ├─ Day 30 (Renewal):
  │  ├─ RevenueCat webhook fires
  │  ├─ Payment processed
  │  ├─ period_end extended (+30 days)
  │  └─ Status remains: active
  │
  ├─ User Decides to Cancel:
  │  └─ Opens Subscription Management
  │     ├─ Views active subscriptions
  │     ├─ Finds "John the Farmer - Premium"
  │     ├─ Clicks "Cancel Subscription"
  │     │
  │     ▼
  │     Confirmation Dialog:
  │     ├─ "Are you sure?"
  │     ├─ "You'll lose access at end of period"
  │     ├─ "Subscribe again anytime"
  │     │
  │     ├─ Cancel button
  │     └─ Confirm Cancel button
  │
  ▼
User Confirms Cancellation
  │
  ├─ RevenueCat cancels subscription
  ├─ Database updated:
  │  ├─ status: canceled
  │  ├─ canceled_at: today
  │  └─ auto_renew: false
  │
  ▼
Access Until End of Period
  │
  ├─ User still has access until day 30
  ├─ Can read all subscriber content
  ├─ Full benefits available
  │
  ▼
Day 30: Subscription Expires
  │
  ├─ RevenueCat webhook: EXPIRATION
  ├─ Database updated:
  │  ├─ status: expired
  │  └─ period_end: today
  │
  ▼
User Loses Access
  │
  ├─ Subscriber articles now show paywall
  ├─ "Subscribe to read" appears again
  ├─ Can still resubscribe

END: Subscription lifecycle complete
```

---

## User Paths by Role

### Creator's Path
```
Onboarded Farmer
    ↓
Apply to become Creator
    ↓
Approved by Admin
    ↓
Access Creator Tools
    ↓
├─ Write Articles
├─ Create Plans ◀── THIS SESSION
├─ View Subscribers ◀── READY
├─ See Earnings ◀── PENDING
└─ Update Settings

Benefits:
├─ Monetize content
├─ Build subscriber base
├─ Recurring revenue
└─ Analytics dashboard
```

### Subscriber's Path
```
Regular Farmer
    ↓
Browse Creator Directory
    ↓
View Subscription Plans
    ↓
Select Plan & Checkout
    ↓
Complete Payment (RevenueCat)
    ↓
Gain Subscriber Status
    ↓
├─ Access exclusive content
├─ Get all benefits
├─ Renew monthly (auto)
└─ Cancel anytime

Benefits:
├─ Expert knowledge
├─ Exclusive content
├─ Community access
└─ Quality education
```

### Free User's Path
```
Regular Farmer
    ↓
Browse Articles
    ↓
├─ Read free articles
├─ View creator profiles
├─ See subscription options
└─ Can subscribe anytime

Can See But Cannot Access:
├─ Locked articles
├─ Subscriber content
├─ Premium features
└─ Exclusive videos
```

---

## Conversion Funnel

```
Creator Directory Visits
         100%
          │
          ▼
View Creator Details
         ~80% (click through)
          │
          ▼
View Subscription Plans
         ~70% (scroll to plans)
          │
          ▼
Open Checkout Screen
         ~40% (click plan)
          │
          ▼
Complete Purchase
         ~25% (actual conversion)
          │
          ▼
Active Subscribers
```

---

## User Satisfaction Points

### Positive Experiences ✅
1. **Easy Plan Creation**
   - Few clicks to create plans
   - Clear form fields
   - Instant feedback

2. **Clear Pricing Display**
   - No hidden costs
   - Monthly price prominent
   - Full benefits listed

3. **Transparent Checkout**
   - Creator confirmed
   - All terms shown
   - Easy to cancel

4. **Immediate Access**
   - No waiting
   - Instant content unlock
   - Full experience

5. **Flexible Cancellation**
   - Anytime cancellation
   - Keep access until end of period
   - Easy re-subscription

### Potential Friction Points ⚠️
1. **Payment Processing**
   - App Store requirements
   - Regional restrictions
   - Card failures

2. **Plan Overload**
   - Too many plans confusing
   - Hard to choose
   - Analysis paralysis

3. **Subscription Fatigue**
   - Multiple subscriptions expensive
   - Hard to track renewals
   - Accidental charges

4. **Access Management**
   - Forgotten subscriptions
   - Unclear status
   - Missing cancellation path

---

## Success Metrics to Track

### Creator Metrics
1. **Plan Creation Rate**
   - How many creators create plans
   - Average plans per creator
   - Plan update frequency

2. **Plan Popularity**
   - Views per plan
   - Conversion rate per plan
   - Revenue per plan

3. **Subscriber Growth**
   - New subscribers per week
   - Subscriber churn rate
   - Lifetime subscriber value

### User Metrics
1. **Discovery**
   - Creator directory visits
   - Details modal opens
   - Plan views

2. **Conversion**
   - Checkout completion rate
   - Purchase success rate
   - Plan selection distribution

3. **Retention**
   - Active subscription count
   - Renewal rate
   - Cancellation rate
   - Churn rate

4. **Engagement**
   - Content access frequency
   - Time in subscriber content
   - Benefit utilization

---

## Timeline Expectations

### Phase 1: Launch (In Progress)
- **Week 1-2:** Basic plans and checkout UI ✅
- **Week 2-3:** RevenueCat integration
- **Week 3-4:** Payment processing live

### Phase 2: Optimization (Pending)
- **Month 2:** Paywall refinement
- **Month 2:** Analytics dashboard
- **Month 2:** Creator earnings

### Phase 3: Growth (Pending)
- **Month 3:** Premium features
- **Month 3:** Marketing tools
- **Month 3:** Advanced analytics

---

This user journey map shows the complete subscription system in action and helps understand the value proposition for both creators and users.
