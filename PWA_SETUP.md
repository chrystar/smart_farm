# PWA Setup Guide for Smart Farm

## Overview
Smart Farm is now configured as a Progressive Web App (PWA) with offline support and Vercel deployment.

## Features
- ✅ **Responsive Design**: Sidebar navigation on desktop (>800px), bottom nav on mobile
- ✅ **Offline Support**: Batches, Sales, and Expenses cached locally with Hive
- ✅ **Auto Sync**: Data syncs automatically when back online
- ✅ **Installable**: "Add to Home Screen" on all devices
- ✅ **Fast Loading**: Service Worker caching for instant loads

## Local Development

### Prerequisites
```bash
flutter --version  # Ensure Flutter 3.10+
flutter pub global activate devtools
```

### Running Locally
```bash
# Install dependencies
flutter pub get

# Run web development server
flutter run -d chrome

# Or with hot reload on specific device
flutter run -d web-server
```

### Testing PWA Features Locally
```bash
# Build for web
flutter build web --release

# Serve locally (requires Python)
cd build/web
python3 -m http.server 8000

# Visit http://localhost:8000
# Open DevTools (F12) → Application → Manifest to verify PWA setup
```

## Offline Sync Implementation

### How It Works
1. **Save Data Offline**: When offline, batches/sales/expenses are saved to local Hive storage
2. **Pending Queue**: Changes are added to a pending sync queue
3. **Reconnection**: When device comes back online, `OfflineSyncService` automatically syncs
4. **Conflict Resolution**: Server data takes precedence on conflicts

### Using in Services
Add this to your `BatchService`, `SalesService`, and `ExpensesService`:

```dart
import 'package:smart_farm/core/services/offline_sync_service.dart';

class BatchService {
  final OfflineSyncService offlineSync = OfflineSyncService();
  
  Future<void> createBatch(Map<String, dynamic> data) async {
    try {
      // Try online first
      final result = await supabaseClient.from('batches').insert(data);
      return result;
    } catch (e) {
      if (!offlineSync.isOnline) {
        // Save offline if not connected
        await offlineSync.saveBatchOffline(data['id'], data);
        return;
      }
      rethrow;
    }
  }
  
  Future<List<Batch>> getBatches() async {
    // Try online first
    try {
      final result = await supabaseClient.from('batches').select();
      return result.map((data) => Batch.fromJson(data)).toList();
    } catch (e) {
      // Fallback to offline data
      final offlineData = await offlineSync.getAllBatchesOffline();
      return offlineData.map((data) => Batch.fromJson(data)).toList();
    }
  }
}
```

## Vercel Deployment

### Step 1: Prepare Repository
```bash
# Ensure .git is initialized
git init
git add .
git commit -m "Initial PWA setup"
git remote add origin https://github.com/YOUR_USERNAME/smart_farm.git
git push -u origin main
```

### Step 2: Deploy to Vercel
```bash
# Install Vercel CLI
npm i -g vercel

# Login to Vercel
vercel login

# Deploy from project root
vercel --prod
```

Or connect via Vercel Dashboard:
1. Go to [vercel.com](https://vercel.com)
2. Click "New Project"
3. Import your GitHub repo
4. Framework: Flutter
5. Build command: `flutter build web --release`
6. Output directory: `build/web`
7. Deploy!

### Step 3: Configure Domain (Optional)
1. In Vercel Dashboard → Project Settings → Domains
2. Add your custom domain
3. Update DNS records as shown
4. HTTPS enabled automatically

## PWA Installation

### Desktop (Chrome/Edge/Firefox)
1. Visit your Vercel URL
2. Click "Install" button in address bar (or menu → Install app)
3. App installs to Applications folder
4. Opens in standalone window

### Mobile (Android)
1. Visit URL in Chrome
2. Tap menu (⋮) → "Install app" or "Add to Home screen"
3. App icon appears on home screen
4. Taps launch full-screen app

### iOS
1. Visit URL in Safari
2. Tap Share → "Add to Home Screen"
3. Icon appears on home screen
4. Limited PWA support (no offline)

## Offline Usage

### What Works Offline
- View cached batches, sales, expenses
- Create new records locally
- Edit existing records
- View dashboard analytics (cached)

### Automatic Sync
- When connection returns, pending changes sync automatically
- Status indicator shows sync progress
- Failed syncs retry on next connection

### Manual Sync Trigger
Add a sync button to UI (optional):
```dart
ElevatedButton(
  onPressed: () async {
    await offlineSyncService.syncPendingChanges();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Synced successfully!')),
    );
  },
  child: const Text('Sync Now'),
)
```

## Performance Optimization

### Service Worker Caching Strategy
- **Assets**: Cached indefinitely (immutable hashes)
- **Manifest**: 1 hour cache
- **Service Worker**: No cache (always fresh)
- **API responses**: Handled by Supabase SDK

### Build Optimization
```bash
# Build with size analysis
flutter build web --release --analyze-size

# Optimize bundle
# - Uses WASM (WebAssembly) when enabled
# - Removes unused code (tree-shaking)
# - Minifies JavaScript
```

## Environment Variables

Set in Vercel Dashboard (Settings → Environment Variables):
```
FLUTTER_WEB_PLATFORM=web
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

Or in `.env.production`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

## Troubleshooting

### Service Worker Not Registering
- Check browser DevTools → Application → Service Workers
- Ensure HTTPS (required for PWA)
- Clear cache: DevTools → Application → Clear storage

### Offline Data Not Syncing
- Check internet connection
- Verify Supabase credentials in `.env`
- Check pending sync queue: `OfflineSyncService.getPendingSync()`

### Build Failed on Vercel
```bash
# Test build locally first
flutter clean
flutter pub get
flutter build web --release

# Check build/web output
ls -la build/web/
```

### App Not Installable
- Check manifest.json is valid: [https://manifest-validator.appspot.com/](https://manifest-validator.appspot.com/)
- Ensure HTTPS on production
- Check theme color and icons are accessible
- Open DevTools → Application → Manifest for details

## Next Steps

1. **Test Offline Features**: 
   - Run app, go offline, create records
   - Verify they sync when online

2. **Customize Branding**:
   - Replace app icons in `web/icons/`
   - Update theme colors in `manifest.json`

3. **Monitor Performance**:
   - Vercel Analytics dashboard
   - DevTools Lighthouse scores
   - Service Worker cache size

4. **Implement Analytics** (Optional):
   - Add Firebase Analytics for PWA
   - Track offline usage patterns

## Resources
- [Flutter Web Docs](https://flutter.dev/docs/get-started/web)
- [PWA Checklist](https://web.dev/pwa-checklist/)
- [Vercel Documentation](https://vercel.com/docs)
- [Service Workers](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
