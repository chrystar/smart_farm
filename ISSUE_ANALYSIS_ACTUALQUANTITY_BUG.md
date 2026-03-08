# CRITICAL ISSUE: actualQuantity Being Incorrectly Reduced on Sales

## Problem Summary

The `actualQuantity` field is being incorrectly decremented when sales are recorded. This breaks all profit calculations and analysis.

### What's Happening

```
Scenario:
- Create batch: expectedQuantity = 100
- Start batch: actualQuantity = 102 (birds actually received)
- Record 4 mortality (daily records)
- Live birds = 102 - 4 = 98

Sale 1: Sell 51 birds
- WRONG: actualQuantity becomes 102 - 51 = 51  ❌
- RIGHT: actualQuantity should stay 102           ✅

After sale:
- WRONG calculation: cost/bird = totalCost / 51 (uses actualQuantity after sales)
- RIGHT calculation: cost/bird = totalCost / 102 (uses birds actually raised)
```

## Root Cause

**In `batch_provider.dart` line 266-276:**

```dart
Future<bool> reduceBatchQuantity(String batchId, int quantitySold) async {
  final batch = _batches.firstWhere((b) => b.id == batchId);
  final currentQuantity = batch.actualQuantity ?? 0;  // Gets current actualQuantity
  final newQuantity = (currentQuantity - quantitySold).clamp(0, currentQuantity);
  
  // ❌ WRONG: This updates actualQuantity in the batch
  final result = await startBatchUseCase(
    batchId: batchId,
    actualQuantity: newQuantity,  // Reduces actualQuantity!
    startDate: batch.startDate ?? DateTime.now(),
  );
}
```

This is called from `sales_list_screen.dart` line 144 when recording a sale.

## Why This Is Wrong

**Purpose of fields:**
- `expectedQuantity`: Planned number (never changes) - used for comparison
- `actualQuantity`: Birds ACTUALLY RECEIVED when batch starts (never changes after that)
- `totalMortality`: Sum of all daily mortality records (changes as mortality is recorded)
- Sales: Tracked separately in `sales` table (birds sold over time)

**What should NOT happen:**
- ❌ actualQuantity changes when mortality is recorded
- ❌ actualQuantity changes when sales are recorded
- ❌ actualQuantity is used to track remaining birds

**What SHOULD happen:**
- ✅ actualQuantity remains fixed = birds received on start date
- ✅ Daily records track mortality (separate from batch quantities)
- ✅ Sales tracked separately (don't modify batch)
- ✅ Remaining birds = actualQuantity - totalMortality - (optional: in-batch inventory tracking)

## Impact on Calculations

### Profit Margin Service (BROKEN)

**Current code (line 122-126):**
```dart
final costPerUnit =
    (batch.expectedQuantity > 0 ? totalCost / batch.expectedQuantity : 0.0)
```

**Problem:** 
1. Uses `expectedQuantity` (100) instead of `actualQuantity` (102)
2. After sales are made, actualQuantity becomes 51, completely wrong divisor

**Should be:**
```dart
final costPerUnit =
    (batch.actualQuantity ?? batch.expectedQuantity > 0 
      ? totalCost / (batch.actualQuantity ?? batch.expectedQuantity) 
      : 0.0)
```

### Profit Analysis Screen (CONFUSED)

**Current logic in `profit_margin_analysis_screen.dart` lines 794-804:**
```dart
int totalBirdsRaised = 0;
if (selectedBatch.status == BatchStatus.active) {
    totalBirdsRaised = selectedBatch.expectedQuantity;  // Wrong!
} else {
    totalBirdsRaised = 0;
}
```

**Should be:**
```dart
int totalBirdsRaised = selectedBatch.actualQuantity ?? selectedBatch.expectedQuantity;
```

### Dashboard Calculations

Any metric based on cost/unit will be completely off because:
- totalBirdsRaised keeps changing
- costs are divided by the wrong number
- all percentages and breakdowns are incorrect

## The Fix Strategy

### Step 1: Stop Reducing actualQuantity on Sales
- Remove the `reduceBatchQuantity` call OR
- Change it to NOT update actualQuantity

### Step 2: Update All Profit Calculations
- Use `actualQuantity ?? expectedQuantity` instead of just `expectedQuantity`
- Ensure cost/unit = totalCost / actualQuantity (birds received)

### Step 3: Fix Remaining Birds Calculation
- Remaining = actualQuantity - totalMortality (not influenced by sales)
- OR track birds in batch separately if you need to know "birds still here"

### Step 4: Audit All Screens
- Batch Detail Screen: Should show birds raised, mortality, live birds
- Dashboard: Should show all analysis based on actualQuantity
- Profit Analysis: All metrics based on actualQuantity
- Sales Screen: Just records sales, doesn't modify batch

## Files to Fix

1. **batch_provider.dart** (line 266-276)
   - Remove `reduceBatchQuantity` OR make it NOT modify actualQuantity
   
2. **profit_margin_service.dart** (line 122-126)
   - Change `expectedQuantity` → `actualQuantity ?? expectedQuantity`
   
3. **profit_margin_analysis_screen.dart** (line 794-804)
   - Use `actualQuantity ?? expectedQuantity` for totalBirdsRaised
   
4. **record_sale_screen.dart** (line 144)
   - Check if `reduceBatchQuantity` is still needed
   
5. **Any dashboard calculations**
   - Audit and fix to use actualQuantity

## Database Schema Check

**batches table should have:**
- `expected_quantity`: Never modified ✓
- `actual_quantity`: Set once at startup, never modified after ✓
- `status`: Changes as batch progresses ✓

**daily_records table should have:**
- `mortality_count`: Individual daily records ✓

**sales table should have:**
- Sales data independent from batch ✓

---

## What Mortality Display Bug Actually Revealed

The user reported "4 mortality but showing no mortality" - this revealed that:
1. We added `loadDailyRecords()` call ✓
2. But actualQuantity was already being mangled by sales reductions
3. Mortality display was just one symptom of the larger problem
