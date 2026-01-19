# Currency Feature Update

## Overview
Added currency selection feature to the batch creation screen, allowing users to specify the currency for purchase costs.

## Changes Made

### 1. Database Schema (`supabase_setup.sql`)
- Added `currency TEXT` column to the `batches` table

### 2. Domain Layer
- **`batch.dart`**: Added `currency` field to the `Batch` entity
- **`batch_repository.dart`**: Added `currency` parameter to `createBatch` method
- **`create_batch_usecase.dart`**: Added `currency` parameter to the use case

### 3. Data Layer
- **`batch_model.dart`**: Added `currency` field to JSON serialization
- **`batch_repository_impl.dart`**: Added `currency` to the batch creation data map

### 4. Presentation Layer
- **`batch_provider.dart`**: Added `currency` parameter to `createBatch` method
- **`create_batch_screen.dart`**: 
  - Added currency dropdown selector next to the cost input field
  - Default currency: USD
  - Supported currencies: USD, EUR, GBP, JPY, CNY, INR, KES, NGN, ZAR, GHS
  - Layout: Cost input (flex: 3) + Currency dropdown (flex: 2)
- **`batch_list_screen.dart`**: Updated to display currency symbol with purchase cost
- **`batch_detail_screen.dart`**: Updated to display currency symbol with purchase cost

## UI Changes
- The purchase cost field is now split into two parts:
  - Left (larger): Cost amount input field
  - Right (smaller): Currency dropdown selector
- Currency is only saved when a purchase cost is provided
- Display format: `{currency}{amount}` (e.g., "USD500", "EUR750")

## Database Migration
If you already have the `batches` table created, run this migration:

```sql
ALTER TABLE batches ADD COLUMN IF NOT EXISTS currency TEXT;
```

## Supported Currencies
- USD - US Dollar
- EUR - Euro
- GBP - British Pound
- JPY - Japanese Yen
- CNY - Chinese Yuan
- INR - Indian Rupee
- KES - Kenyan Shilling
- NGN - Nigerian Naira
- ZAR - South African Rand
- GHS - Ghanaian Cedi

## Testing
1. Create a new batch with a purchase cost
2. Select a currency from the dropdown
3. Verify the currency is displayed correctly on the batch list and detail screens
4. Verify the currency is saved to the database
