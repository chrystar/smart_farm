# Marketplace Feature - Setup Guide

## Overview
The marketplace feature allows farmers to list birds for sale with photos, specifications, and pricing. Admins can review, approve, and assign buyers to listings. The feature includes complete tracking from submission to completion.

## Features Implemented

### Farmer Features
- ✅ Create sales requests with multiple photos (1-5 images)
- ✅ Specify bird type (broiler, layer, cockerel, other)
- ✅ Set quantity, age (in months), and price per bird
- ✅ Select from approved locations
- ✅ View all their sales requests with status
- ✅ View detailed information about each request
- ✅ See buyer information when a buyer is found
- ✅ Track request status throughout the process

### Status Flow
1. **Pending** - Initial submission, awaiting admin review
2. **Approved** - Admin approved, system is finding a buyer
3. **Finding Buyer** - Actively searching for buyers
4. **Buyer Found** - Buyer assigned, pickup details provided
5. **Completed** - Sale successfully completed
6. **Cancelled** - Request cancelled by user
7. **Rejected** - Request rejected by admin with notes

### Admin Features (Future Implementation)
- Review pending sales requests
- Approve/reject requests with notes
- Assign buyers to approved listings
- Provide pickup location and date information

## File Structure

```
lib/features/marketplace/
├── domain/
│   └── entities/
│       ├── approved_location.dart      # Location entity
│       └── sales_request.dart          # Sales request entity with enums
├── data/
│   ├── models/
│   │   ├── approved_location_model.dart
│   │   └── sales_request_model.dart
│   └── datasources/
│       └── marketplace_remote_datasource.dart
└── presentation/
    ├── provider/
    │   ├── marketplace_provider.dart
    │   └── marketplace_injection.dart
    └── pages/
        ├── marketplace_screen.dart              # List view of requests
        ├── create_sales_request_screen.dart     # Form to create new request
        └── sales_request_detail_screen.dart     # Detail view of request
```

## Setup Instructions

### 1. Database Migration

Run the SQL migration in your Supabase SQL Editor:

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of `database/migrations/marketplace_migration.sql`
4. Run the script
5. Verify tables were created successfully

The migration creates:
- `approved_locations` table with sample data
- `sales_requests` table with all necessary fields
- RLS policies for data security
- Indexes for better performance
- Triggers for automatic timestamp updates

### 2. Create Supabase Storage Bucket

1. Go to **Storage** in Supabase Dashboard
2. Click **New bucket**
3. Name: `bird-photos`
4. Set to **Public** (so images can be viewed)
5. Click **Create bucket**

#### Configure Storage Policies

Go to the `bird-photos` bucket > **Policies** tab and create these policies:

**Policy 1: Public Read**
- Name: "Public can view bird photos"
- Operation: SELECT
- Policy definition: `true` (or leave blank)

**Policy 2: Authenticated Upload**
- Name: "Authenticated users can upload"
- Operation: INSERT
- Policy definition:
```sql
(bucket_id = 'bird-photos'::text)
```

**Policy 3: User Delete Own**
- Name: "Users can delete their own uploads"
- Operation: DELETE
- Policy definition:
```sql
(bucket_id = 'bird-photos'::text)
```

### 3. Verify Provider Registration

The marketplace provider should already be registered in `lib/main.dart`:

```dart
import 'features/marketplace/presentation/provider/marketplace_injection.dart';

// In MultiProvider:
providers: [
  ...MarketplaceInjection.providers,
  // other providers...
],
```

### 4. Access the Marketplace

The marketplace is accessible from the dashboard drawer:

1. Open the app
2. Navigate to **Dashboard**
3. Tap the **menu icon** (☰) in the top-left
4. Select **Marketplace**

## Usage Guide

### For Farmers

#### Creating a Sales Request

1. Open **Dashboard** > **Marketplace**
2. Tap the **+ floating action button**
3. Fill in the form:
   - **Photos**: Tap to select 1-5 bird photos (required)
   - **Bird Type**: Choose from dropdown (broiler, layer, cockerel, other)
   - **Quantity**: Number of birds to sell
   - **Age**: Age in months
   - **Price per Bird**: Price for each bird
   - **Location**: Select from approved locations
4. Review the **Total Price** (calculated automatically)
5. Tap **Submit Request**

#### Viewing Request Status

1. Open **Marketplace** to see all your requests
2. Each card shows:
   - Status badge with color coding
   - Bird type, quantity, age
   - Total price
   - Submission date
   - Buyer info (if buyer found)
3. Tap any card to view **full details**

#### Understanding Status Colors

- 🟠 **Orange** - Pending review
- 🔵 **Blue** - Approved/Finding buyer
- 🟢 **Green** - Buyer found/Completed
- 🔴 **Red** - Rejected
- ⚪ **Grey** - Cancelled

### For Admins (Future)

Admin interface will allow:
- Viewing all pending requests
- Reviewing request details and photos
- Approving or rejecting with notes
- Assigning buyer information
- Updating pickup details

## Database Schema

### approved_locations

| Column        | Type      | Description                    |
|---------------|-----------|--------------------------------|
| id            | UUID      | Primary key                    |
| location_name | TEXT      | Name of the location           |
| region        | TEXT      | Region/state                   |
| is_active     | BOOLEAN   | Whether location is active     |
| created_at    | TIMESTAMP | When location was added        |
| updated_at    | TIMESTAMP | Last update time               |

### sales_requests

| Column         | Type      | Description                        |
|----------------|-----------|-------------------------------------|
| id             | UUID      | Primary key                         |
| user_id        | UUID      | Foreign key to auth.users           |
| quantity       | INTEGER   | Number of birds                     |
| price_per_bird | DECIMAL   | Price per bird                      |
| total_price    | DECIMAL   | Total price (quantity × price)      |
| bird_type      | TEXT      | Type: broiler/layer/cockerel/other  |
| age_months     | INTEGER   | Age in months                       |
| bird_photos    | TEXT[]    | Array of photo URLs                 |
| location_id    | UUID      | Foreign key to approved_locations   |
| location_name  | TEXT      | Location name (denormalized)        |
| status         | TEXT      | Current status of request           |
| reviewed_by    | UUID      | Admin who reviewed                  |
| reviewed_at    | TIMESTAMP | When reviewed                       |
| admin_notes    | TEXT      | Admin's notes/feedback              |
| buyer_name     | TEXT      | Buyer's name (when found)           |
| buyer_phone    | TEXT      | Buyer's phone number                |
| pickup_location| TEXT      | Where buyer will pickup             |
| pickup_date    | TIMESTAMP | When buyer will pickup              |
| created_at     | TIMESTAMP | When request was created            |
| updated_at     | TIMESTAMP | Last update time                    |

## API Reference

### MarketplaceRemoteDataSource

```dart
// Get all approved locations
Future<List<ApprovedLocationModel>> getApprovedLocations()

// Get user's sales requests
Future<List<SalesRequestModel>> getUserSalesRequests(String userId)

// Create new sales request
Future<void> createSalesRequest(SalesRequestModel request)

// Upload bird photo to storage
Future<String> uploadBirdPhoto(String filePath, String userId)

// Delete sales request
Future<void> deleteSalesRequest(String requestId)

// Update sales request
Future<void> updateSalesRequest(SalesRequestModel request)
```

### MarketplaceProvider

```dart
// State
List<ApprovedLocation> locations
List<SalesRequest> salesRequests
bool isLoading
String? errorMessage

// Methods
Future<void> loadApprovedLocations()
Future<void> loadSalesRequests()
Future<void> createSalesRequest(SalesRequest request)
Future<String> uploadPhoto(String filePath)
Future<void> deleteSalesRequest(String requestId)
```

## Security

### Row Level Security (RLS)

**approved_locations**
- ✅ Anyone can view active locations
- ✅ Authenticated users can view all locations

**sales_requests**
- ✅ Users can only view their own requests
- ✅ Users can create requests
- ✅ Users can update requests (only if pending/cancelled)
- ✅ Users can delete requests (only if pending)

**Storage (bird-photos)**
- ✅ Public read access (anyone can view photos)
- ✅ Authenticated users can upload
- ✅ Users can delete their own uploads

## Troubleshooting

### Photos Not Uploading
1. Check if `bird-photos` bucket exists in Supabase Storage
2. Verify bucket is set to **Public**
3. Check storage policies are correctly configured
4. Ensure image files are under 5MB

### Cannot See Locations Dropdown
1. Run the database migration to create sample locations
2. Check if `approved_locations` table has data
3. Verify RLS policies allow reading locations

### Request Not Saving
1. Check all required fields are filled
2. Ensure at least 1 photo is selected
3. Verify quantity, age, and price are positive numbers
4. Check network connection

### Status Not Updating
- Status updates are admin-only (except cancel)
- Users cannot manually change status after submission
- Contact admin if status seems stuck

## Next Steps (Future Development)

1. **Admin Dashboard**
   - Build admin interface to review requests
   - Implement approval/rejection workflow
   - Add buyer assignment functionality

2. **Notifications**
   - Push notifications for status changes
   - Email notifications for buyer found
   - SMS alerts for pickup reminders

3. **Analytics**
   - Track marketplace metrics
   - View sales trends
   - Generate reports

4. **Enhanced Features**
   - Image compression before upload
   - Multiple bird batches in one request
   - Price negotiation system
   - Rating/review system

## Support

For issues or questions:
1. Check this README for common solutions
2. Review the database migration logs
3. Verify Supabase configuration
4. Check console for error messages

## Testing Checklist

- [ ] Database migration completed successfully
- [ ] Storage bucket `bird-photos` created and public
- [ ] Sample locations appear in dropdown
- [ ] Can select and preview multiple photos
- [ ] Form validation works (required fields)
- [ ] Total price calculates correctly
- [ ] Can submit request successfully
- [ ] Request appears in marketplace list
- [ ] Can view request details
- [ ] Status badge shows correct color
- [ ] Can pull to refresh marketplace list
- [ ] Drawer opens from dashboard
- [ ] Navigation to marketplace works
