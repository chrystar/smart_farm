# Video Upload Implementation Guide

## Overview
Complete video management system for Smart Farm creators to upload, manage, and share educational videos with farmers.

## Implementation Status: ✅ COMPLETE

### Features Implemented
- ✅ Video upload with file picker (10-minute limit)
- ✅ Thumbnail upload and preview
- ✅ Upload progress indicator (0-100%)
- ✅ File size validation (100MB limit)
- ✅ Duration validation (10 minutes max)
- ✅ Video metadata management
- ✅ Category selection (8 categories)
- ✅ Featured video toggle
- ✅ Edit existing videos
- ✅ Delete videos
- ✅ Video list management
- ✅ View/like statistics

---

## Database Schema

### Table: `creator_videos`

```sql
-- Run migration: supabase/migrations/2026-02-27_create_creator_videos.sql
```

**Columns:**
- `id` (UUID) - Primary key
- `user_id` (UUID) - Foreign key to auth.users
- `title` (TEXT) - Video title (5-100 chars)
- `description` (TEXT) - Optional description (max 500 chars)
- `video_url` (TEXT) - Supabase storage URL
- `thumbnail_url` (TEXT) - Thumbnail image URL
- `duration_seconds` (INTEGER) - Video duration
- `file_size_bytes` (BIGINT) - File size in bytes
- `category` (TEXT) - One of 8 categories
- `featured` (BOOLEAN) - Featured flag
- `views` (INTEGER) - View count (default 0)
- `likes` (INTEGER) - Like count (default 0)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

**Indexes:**
- `user_id` - Fast creator lookup
- `created_at DESC` - Recent videos first
- `featured` - Featured videos filter

**RLS Policies:**
- ✅ Creators can manage their own videos
- ✅ Public read access to all videos
- ✅ Secure video uploads

---

## Supabase Storage Setup

### Required Storage Bucket

**Bucket Name:** `creator-videos`

#### Setup Instructions:

1. **Go to Supabase Dashboard**
   - Navigate to Storage section
   - Click "Create bucket"

2. **Create Bucket**
   - Name: `creator-videos`
   - Public: ✅ **Yes** (enable public access)
   - File size limit: 100MB
   - Allowed MIME types: `video/*`, `image/*`

3. **Folder Structure**
   ```
   creator-videos/
   ├── videos/       (uploaded videos)
   └── thumbnails/   (video thumbnails)
   ```

4. **Storage Policies** (auto-configured by app)
   - Authenticated users can upload
   - Public can read/download
   - Only owner can delete

#### Manual SQL (if needed):
```sql
-- Create storage bucket if not exists
insert into storage.buckets (id, name, public)
values ('creator-videos', 'creator-videos', true)
on conflict (id) do nothing;

-- Allow authenticated uploads
create policy "Authenticated users can upload videos"
on storage.objects for insert
to authenticated
with check (bucket_id = 'creator-videos');

-- Allow public reads
create policy "Anyone can view videos"
on storage.objects for select
to public
using (bucket_id = 'creator-videos');

-- Allow owners to delete
create policy "Users can delete own videos"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'creator-videos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

---

## File Structure

### New Files Created

1. **`supabase/migrations/2026-02-27_create_creator_videos.sql`**
   - Database schema for videos table
   - RLS policies
   - Indexes
   - Status: ✅ Ready to run

2. **`lib/features/learning/presentation/screens/video_upload_screen.dart`**
   - Video upload and edit screen
   - File picker integration
   - Progress tracking
   - Form validation
   - Lines: 590
   - Status: ✅ Complete

3. **`lib/features/learning/presentation/screens/my_videos_screen.dart`**
   - Video list management
   - Edit/delete actions
   - Stats display (views, likes, size)
   - Pull-to-refresh
   - Empty state with CTA
   - Lines: 560
   - Status: ✅ Complete

### Modified Files

1. **`lib/features/learning/presentation/screens/creator_tools_screen.dart`**
   - Added import for `my_videos_screen.dart`
   - Updated `_buildVideosView()` method
   - Changed button from "Upload Video" to "Manage Videos"
   - Navigation to MyVideosScreen
   - Status: ✅ Updated

---

## Features Deep Dive

### 1. Video Upload Screen

**Location:** `lib/features/learning/presentation/screens/video_upload_screen.dart`

#### Features:
- **Video Picker**
  - Uses `image_picker` package
  - Supports video selection from gallery/camera
  - 10-minute maximum duration
  - Shows selected video name and size

- **Thumbnail Picker**
  - Optional thumbnail selection
  - Image preview before upload
  - Accepts JPEG/PNG formats
  - Default thumbnail if not provided

- **Form Validation**
  - Title: 5-100 characters required
  - Description: Optional, max 500 characters
  - Category: Required selection
  - File size: Max 100MB
  - Duration: Max 10 minutes

- **Categories (8 options):**
  1. General
  2. Poultry Management
  3. Feeding & Nutrition
  4. Disease Prevention & Healthcare
  5. Business & Marketing
  6. Housing & Equipment
  7. Tips & Tricks
  8. Success Stories

- **Upload Progress**
  - Real-time progress bar (0-100%)
  - File size display
  - Loading states
  - Error handling

- **Featured Toggle**
  - Mark videos as featured
  - Featured videos get priority display
  - Orange star badge on featured videos

#### Methods:
```dart
_pickVideo()              // Select video file
_pickThumbnail()          // Select thumbnail image
_uploadFile()             // Upload to Supabase storage
_saveVideo()              // Save metadata to database
_formatFileSize()         // Format bytes to KB/MB
```

---

### 2. My Videos Screen

**Location:** `lib/features/learning/presentation/screens/my_videos_screen.dart`

#### Features:
- **Video List**
  - Grid view with thumbnails
  - Play button overlay
  - Duration badge on thumbnails
  - Category and featured badges

- **Video Cards Display:**
  - Thumbnail with play icon
  - Title (max 2 lines)
  - Description (max 2 lines)
  - Category badge
  - Featured star (if featured)
  - View count
  - Like count
  - File size
  - Upload date (relative time)

- **Actions**
  - Edit video (navigates to VideoUploadScreen)
  - Delete video (with confirmation dialog)
  - View statistics

- **Empty State**
  - Icon and message
  - "Upload Video" CTA button
  - Helpful guidance text

- **Pull-to-Refresh**
  - Swipe down to reload videos
  - Automatic data refresh

#### Methods:
```dart
_loadMyVideos()           // Load creator's videos
_deleteVideo()            // Delete video by ID
_showDeleteConfirmation() // Confirm before delete
_formatFileSize()         // Format bytes display
_formatDate()             // Relative time formatting
_formatDuration()         // MM:SS format
```

---

### 3. Creator Tools Integration

**Location:** `lib/features/learning/presentation/screens/creator_tools_screen.dart`

#### Changes:
- Added import for `MyVideosScreen`
- Updated "Videos" tab button
- Changed from placeholder to navigation
- Button label: "Manage Videos"
- Opens MyVideosScreen on tap

#### Navigation Flow:
```
Creator Tools → Videos Tab → Manage Videos → My Videos Screen
                                          → Upload Video Button → Video Upload Screen
```

---

## Video Categories

8 predefined categories matching farm education topics:

| Category | Description |
|----------|-------------|
| **General** | General farming topics and overviews |
| **Poultry Management** | Chicken, duck, and bird care |
| **Feeding & Nutrition** | Diet, feed formulation, supplements |
| **Disease Prevention** | Health, vaccination, biosecurity |
| **Business & Marketing** | Sales, branding, customer relations |
| **Housing & Equipment** | Coops, pens, tools, infrastructure |
| **Tips & Tricks** | Quick hacks, best practices |
| **Success Stories** | Case studies, testimonials |

---

## Validation Rules

### Video File
- ✅ Format: Any video format supported by device
- ✅ Size: Maximum 100MB (104,857,600 bytes)
- ✅ Duration: Maximum 10 minutes (600 seconds)
- ❌ Rejected if over limits

### Thumbnail
- ✅ Format: JPEG, PNG, or other image formats
- ✅ Recommended: 16:9 aspect ratio (1280x720 or 1920x1080)
- ⚠️ Optional (but highly recommended)

### Metadata
- **Title**
  - Required: ✅
  - Min length: 5 characters
  - Max length: 100 characters
  - Validation: Non-empty, trimmed

- **Description**
  - Required: ❌ (optional)
  - Max length: 500 characters

- **Category**
  - Required: ✅
  - Must be one of 8 predefined categories

- **Featured**
  - Type: Boolean
  - Default: false
  - Editable: ✅

---

## User Experience Flow

### Upload New Video

1. **Navigate to Videos**
   - Creator Tools → Videos tab
   - Click "Manage Videos"

2. **Start Upload**
   - Click "Upload Video" FAB
   - Or click button if no videos

3. **Select Video**
   - Choose from gallery/camera
   - Validation runs automatically
   - See file name and size

4. **Add Thumbnail** (optional)
   - Click "Select Thumbnail"
   - Choose image
   - Preview appears

5. **Fill Form**
   - Enter title (required)
   - Add description (optional)
   - Select category (required)
   - Toggle featured (optional)

6. **Upload**
   - Click "Upload Video"
   - Progress bar shows upload
   - Success message on completion
   - Returns to My Videos screen

### Edit Existing Video

1. **Open My Videos**
   - View list of uploaded videos

2. **Click Edit Icon**
   - Opens VideoUploadScreen
   - Pre-filled with existing data

3. **Make Changes**
   - Update title/description
   - Change category
   - Toggle featured
   - Change thumbnail

4. **Save Changes**
   - Click "Update Video"
   - Changes saved to database
   - Returns to list

### Delete Video

1. **Click Delete Icon**
   - Red trash icon on video card

2. **Confirm Deletion**
   - Dialog asks for confirmation
   - Shows video title

3. **Delete**
   - Click "Delete" to confirm
   - Video removed from database
   - List refreshes automatically

---

## Technical Details

### Dependencies Used

From `pubspec.yaml`:
```yaml
image_picker: ^1.0.7  # Video and image selection
supabase_flutter: ^latest  # Database and storage
```

### Storage Paths

**Video uploads:**
```
creator-videos/videos/{uuid}.mp4
```

**Thumbnail uploads:**
```
creator-videos/thumbnails/{uuid}.jpg
```

### Database Queries

**Load videos:**
```dart
Supabase.instance.client
  .from('creator_videos')
  .select()
  .eq('user_id', currentUserId)
  .order('created_at', ascending: false);
```

**Insert video:**
```dart
Supabase.instance.client
  .from('creator_videos')
  .insert({
    'user_id': userId,
    'title': title,
    'video_url': videoUrl,
    'thumbnail_url': thumbnailUrl,
    // ... more fields
  });
```

**Update video:**
```dart
Supabase.instance.client
  .from('creator_videos')
  .update({...})
  .eq('id', videoId);
```

**Delete video:**
```dart
Supabase.instance.client
  .from('creator_videos')
  .delete()
  .eq('id', videoId);
```

---

## Security

### Row-Level Security (RLS)

**Enabled on `creator_videos` table:**

1. **Creator Manage Policy**
   - Users can INSERT/UPDATE/DELETE their own videos
   - Condition: `auth.uid() = user_id`

2. **Public Read Policy**
   - Anyone can SELECT videos
   - Enables public viewing of educational content

### Storage Security

**creator-videos bucket:**
- Authenticated users can upload
- Public can download
- Only video owner can delete
- File size limits enforced

---

## Testing Checklist

### Pre-Testing Setup
- [ ] Run database migration
- [ ] Create Supabase storage bucket
- [ ] Verify RLS policies
- [ ] Check storage policies

### Upload Flow
- [ ] Select video under 100MB, under 10 min → ✅ Uploads
- [ ] Select video over 100MB → ❌ Shows error
- [ ] Select video over 10 min → ❌ Shows error
- [ ] Upload without thumbnail → ✅ Works (thumbnail optional)
- [ ] Enter title < 5 chars → ❌ Validation error
- [ ] Enter title > 100 chars → ❌ Validation error
- [ ] Skip category → ❌ Validation error
- [ ] Toggle featured → ✅ Badge appears
- [ ] Upload progress bar → ✅ Shows 0-100%
- [ ] Success message → ✅ Appears

### List View
- [ ] Empty state → ✅ Shows with CTA
- [ ] Video cards → ✅ Display correctly
- [ ] Thumbnail → ✅ Shows or placeholder
- [ ] Category badge → ✅ Displays
- [ ] Featured badge → ✅ Shows on featured
- [ ] Stats → ✅ Views, likes, size, date
- [ ] Pull-to-refresh → ✅ Reloads data

### Edit Flow
- [ ] Click edit → ✅ Opens with data
- [ ] Change title → ✅ Updates
- [ ] Change category → ✅ Updates
- [ ] Toggle featured → ✅ Updates
- [ ] Change thumbnail → ✅ Updates
- [ ] Click update → ✅ Saves changes

### Delete Flow
- [ ] Click delete → ✅ Shows confirmation
- [ ] Cancel → ✅ No deletion
- [ ] Confirm → ✅ Deletes video
- [ ] List refresh → ✅ Video removed

---

## Troubleshooting

### Video Upload Fails

**Issue:** Upload progress stalls or fails

**Solutions:**
1. Check file size (must be < 100MB)
2. Check duration (must be < 10 min)
3. Verify storage bucket exists
4. Check internet connection
5. Verify Supabase storage policies

### Thumbnails Not Showing

**Issue:** Thumbnail displays placeholder

**Solutions:**
1. Verify thumbnail was uploaded
2. Check `thumbnail_url` in database
3. Verify storage bucket is public
4. Check image URL is accessible
5. Clear app cache

### Videos Not Loading

**Issue:** My Videos screen shows empty

**Solutions:**
1. Check database migration ran
2. Verify RLS policies exist
3. Check user authentication
4. Verify `user_id` matches current user
5. Check database connection

### Edit Not Saving

**Issue:** Changes don't persist

**Solutions:**
1. Verify RLS policy allows UPDATE
2. Check `user_id` matches video owner
3. Verify form validation passes
4. Check database connection
5. Look for error messages in logs

---

## Next Steps (Optional Enhancements)

### Phase 2 (Video Viewing)
- [ ] Video player screen
- [ ] Video playback controls
- [ ] View count increment
- [ ] Like/unlike functionality
- [ ] Comments system
- [ ] Share video

### Phase 3 (Discovery)
- [ ] Featured videos section
- [ ] Category filtering
- [ ] Search videos
- [ ] Related videos
- [ ] Popular videos
- [ ] Recent uploads

### Phase 4 (Analytics)
- [ ] Video analytics dashboard
- [ ] View statistics over time
- [ ] Engagement metrics
- [ ] Audience demographics
- [ ] Watch time tracking
- [ ] Completion rates

### Phase 5 (Advanced Features)
- [ ] Video transcoding (multiple qualities)
- [ ] Subtitles/captions
- [ ] Video chapters
- [ ] Playlists
- [ ] Live streaming
- [ ] Video monetization

---

## Migration Instructions

### Step 1: Run Database Migration

```bash
# Connect to Supabase
cd /Users/ram/Development/projects/smart_farm

# Apply migration
supabase db push

# Or manually run in Supabase SQL Editor:
# Copy contents of supabase/migrations/2026-02-27_create_creator_videos.sql
# Paste and execute in SQL Editor
```

### Step 2: Create Storage Bucket

**Option A: Supabase Dashboard**
1. Go to Storage section
2. Click "Create bucket"
3. Name: `creator-videos`
4. Make public: ✅
5. Click "Create"

**Option B: SQL**
```sql
insert into storage.buckets (id, name, public)
values ('creator-videos', 'creator-videos', true);
```

### Step 3: Test the Feature

1. Run the app
2. Login as creator
3. Go to Creator Tools → Videos
4. Click "Manage Videos"
5. Upload a test video
6. Verify it appears in list
7. Test edit and delete

---

## Support

### Related Documentation
- `APP_ANALYSIS_AND_IMPLEMENTATION_ROADMAP.md` - Overall app analysis
- `CREATOR_FARMERS_IMPLEMENTATION.md` - Creator profile setup
- `SUPABASE_SETUP.md` - Database configuration

### Files to Review
- `lib/features/learning/presentation/screens/video_upload_screen.dart`
- `lib/features/learning/presentation/screens/my_videos_screen.dart`
- `lib/features/learning/presentation/screens/creator_tools_screen.dart`
- `supabase/migrations/2026-02-27_create_creator_videos.sql`

---

## Summary

✅ **Complete video management system implemented**

**What was built:**
- Full video upload with progress tracking
- Thumbnail support
- Video list management
- Edit and delete functionality
- Category organization
- Featured video system
- View/like statistics
- Database schema with RLS
- Integration with Creator Tools

**Ready to use:** After running migration and creating storage bucket, creators can immediately start uploading educational videos to share with farmers.

**Priority 1 Task Status:** ✅ **COMPLETE** - Video Upload Handler fully implemented.

---

*Last Updated: 2026-02-27*
*Implementation Status: Complete*
*Developer: GitHub Copilot*
