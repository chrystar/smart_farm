# SmartFarm Creator Farmers Feature - Implementation Plan

## Overview
Added a drawer-based navigation system to the SmartFarm app with two new learning features: **Articles** and **Creator Farmers**. This enables farmers to discover educational content and monetize their farming knowledge.

---

## Files Created

### 1. `lib/features/learning/presentation/screens/articles_screen.dart`
**Purpose**: Display farming articles from creator farmers
**Features**:
- Browse articles by category (Feeding, Disease Management, Housing, Breeding)
- Filter articles by category
- View article metadata: author, read time, rating, subscriber count
- Tap to read full articles (future implementation)

**UI Components**:
- AppBar with category filters
- Card-based article list
- Article cards showing:
  - Article title
  - Author name
  - Category badge
  - Star rating
  - Read time estimate
  - Number of subscribers

### 2. `lib/features/learning/presentation/screens/creator_farmers_screen.dart`
**Purpose**: Discover and subscribe to creator farmers
**Features**:
- Browse all creator farmers
- Search creators by name or specialization
- Sort by: Followers, Rating, or Newest
- View creator profile with stats
- Subscribe to creators
- Creator details modal view

**UI Components**:
- Search bar for filtering creators
- Sort dropdown (followers, rating, newest)
- Creator cards showing:
  - Avatar/emoji
  - Name with verified badge
  - Specialization
  - Bio/description
  - Statistics: followers, rating, articles, videos count
  - Subscribe button
- Modal bottom sheet for creator details

---

## Modified Files

### 1. `lib/app.dart`
**Changes**:
1. Added imports for new screens
2. Added `_currentScreen` state variable to handle custom navigation
3. Added `_navigateTo()` method for drawer navigation
4. Added `AppBar` with hamburger menu icon
5. Added `drawer` property with `_buildDrawer()` method
6. Modified body to show `_currentScreen` or default screens
7. Updated `onTap` in BottomNavigationBar to reset custom screen

**New Drawer Structure**:
```
SmartFarm (Header)
├─ LEARNING Section
│  ├─ Articles
│  └─ Creator Farmers
├─ MAIN Section
│  ├─ Home
│  ├─ Batches
│  ├─ Expenses
│  ├─ Sales
│  └─ Settings
```

---

## Feature Overview

### Articles Screen
- **Purpose**: Educational hub for farming knowledge
- **Content Types**: How-to guides, tips, disease management, breeding, etc.
- **Navigation**: Accessible from drawer menu
- **Sample Data**: 4 sample articles with categories
- **Future Integration**:
  - Connect to Supabase `creator_articles` table
  - Implement article detail view with full content
  - Add comments and ratings
  - Implement premium article access

### Creator Farmers Screen
- **Purpose**: Discover and follow farming experts
- **Features**:
  - Search creators by name or specialization
  - Sort by followers, rating, or newest
  - View creator profiles with statistics
  - Subscribe to creators
- **Navigation**: Accessible from drawer menu
- **Sample Data**: 4 sample creators
- **Future Integration**:
  - Connect to Supabase `creator_profiles` table
  - Implement subscription system with payments
  - Show creator's articles and videos
  - Implement following/unsubscribe logic
  - Add creator ratings and reviews

---

## Database Schema (Future Implementation)

```sql
-- Creator profiles
CREATE TABLE creator_profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  display_name TEXT,
  bio TEXT,
  profile_image_url TEXT,
  years_experience INT,
  specializations TEXT[],
  verified_by_admin BOOLEAN,
  rating DECIMAL(3,2),
  follower_count INT,
  created_at TIMESTAMP
);

-- Creator articles
CREATE TABLE creator_articles (
  id UUID PRIMARY KEY,
  creator_id UUID REFERENCES creator_profiles,
  title TEXT,
  cover_image_url TEXT,
  content TEXT,
  category TEXT,
  is_free BOOLEAN,
  subscription_tier TEXT,
  read_time_minutes INT,
  views_count INT,
  published_at TIMESTAMP
);

-- Creator videos
CREATE TABLE creator_videos (
  id UUID PRIMARY KEY,
  creator_id UUID REFERENCES creator_profiles,
  title TEXT,
  description TEXT,
  thumbnail_url TEXT,
  video_url TEXT,
  category TEXT,
  is_free BOOLEAN,
  subscription_tier TEXT,
  views_count INT,
  published_at TIMESTAMP
);

-- Creator subscriptions
CREATE TABLE creator_subscriptions (
  id UUID PRIMARY KEY,
  subscriber_user_id UUID REFERENCES auth.users,
  creator_id UUID REFERENCES creator_profiles,
  subscription_tier TEXT,
  status TEXT,
  started_at TIMESTAMP,
  expires_at TIMESTAMP
);

-- Creator earnings
CREATE TABLE creator_earnings (
  id UUID PRIMARY KEY,
  creator_id UUID REFERENCES creator_profiles,
  month DATE,
  subscription_revenue DECIMAL,
  platform_commission DECIMAL,
  creator_payout DECIMAL,
  paid_at TIMESTAMP
);
```

---

## Navigation Flow

```
Bottom Navigation (Home, Batches, Expenses, Sales, Settings)
        ↓
Drawer Menu (Hamburger Icon in AppBar)
        ├─ Articles (Replaces bottom nav)
        ├─ Creator Farmers (Replaces bottom nav)
        └─ Main Menu Items (Restore bottom nav)
```

---

## Next Steps

### Phase 1: Backend Integration (Week 1)
- [ ] Set up Supabase tables for creators and articles
- [ ] Implement creator verification system
- [ ] Create API endpoints for fetching creators/articles

### Phase 2: Core Features (Week 2-3)
- [ ] Integrate real data from Supabase
- [ ] Implement article detail view with rich text
- [ ] Implement creator profile detail view
- [ ] Add subscription system (UI only)

### Phase 3: Monetization (Week 4-5)
- [ ] Implement payment integration (Stripe, M-Pesa)
- [ ] Add creator earnings dashboard
- [ ] Implement subscription payment flow
- [ ] Add transaction history

### Phase 4: Enhancement (Week 6+)
- [ ] Creator verification/badge system
- [ ] Video content support
- [ ] Live Q&A sessions
- [ ] Creator mentorship programs
- [ ] Analytics and insights for creators

---

## Testing Checklist

- [ ] Drawer opens/closes correctly
- [ ] Navigation between screens works
- [ ] Article filtering by category works
- [ ] Creator search and sort works
- [ ] Subscribe button shows confirmation
- [ ] Modal displays creator details
- [ ] Back navigation works properly
- [ ] Screen state persists when navigating back

---

## User Journey

### For Farmers (Learners)
1. Open SmartFarm app
2. Tap hamburger menu
3. Select "Articles" or "Creator Farmers"
4. Browse content
5. Subscribe to creator (optional)
6. View creator's articles and videos

### For Creator Farmers (Content Creators)
1. Apply to become creator farmer
2. Get verified by admin
3. Create articles and videos
4. Set subscription tiers
5. Monitor earnings
6. Interact with subscribers

---

## Notes

- Sample data is hardcoded for demo purposes
- All future interactions show toast messages
- Drawer closes automatically after navigation
- AppBar is consistent across all screens
- Color scheme uses existing AppColor.primaryGreen
- Responsive design supports mobile-first approach

