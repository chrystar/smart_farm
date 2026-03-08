# Batch Quantity Flow - BEFORE vs AFTER FIX

## BEFORE (BROKEN) 🔴

```
Batch Creation
├── expectedQuantity = 100
└── actualQuantity = NULL

        ↓

Batch Start (Activated)
├── expectedQuantity = 100 (unchanged)
└── actualQuantity = 102 ✓

        ↓

Recording Mortality (Day 1)
├── expectedQuantity = 100 (unchanged)
├── actualQuantity = 102 (unchanged) ✓
├── totalMortality = 4
└── Remaining = 102 - 4 = 98 ✓

        ↓

Recording First Sale (50 birds)
├── expectedQuantity = 100 (unchanged)
├── actualQuantity = 102 - 50 = 52 ❌ WRONG!
├── totalMortality = 4
└── Remaining = 52 - 4 = 48 ❌ WRONG!

        ↓

Cost Per Bird Calculation
├── Cost per bird = $2,550 / 52 = $49.04 ❌ WRONG!
├── Should be = $2,550 / 102 = $25.00 ✓
└── ERROR: Divisor keeps changing! ❌

        ↓

Recording Second Sale (30 birds)
├── expectedQuantity = 100 (unchanged)
├── actualQuantity = 52 - 30 = 22 ❌ WRONG!
├── totalMortality = 4
└── Remaining = 22 - 4 = 18 ❌ WRONG!

        ↓

Cost Per Bird Calculation (NOW)
├── Cost per bird = $2,550 / 22 = $115.91 ❌ COMPLETELY WRONG!
└── Divisor changed again! ❌

❌ RESULT: All metrics broken, calculations are meaningless!
```

## AFTER (FIXED) ✅

```
Batch Creation
├── expectedQuantity = 100
└── actualQuantity = NULL

        ↓

Batch Start (Activated)
├── expectedQuantity = 100 (unchanged)
└── actualQuantity = 102 ✓ LOCKED

        ↓

Recording Mortality (Day 1)
├── expectedQuantity = 100 (unchanged)
├── actualQuantity = 102 ✓ LOCKED (never changes)
├── totalMortality = 4
└── Remaining = 102 - 4 = 98 ✓

        ↓

Recording First Sale (50 birds)
├── expectedQuantity = 100 (unchanged)
├── actualQuantity = 102 ✓ LOCKED (not modified!)
├── totalMortality = 4
├── Remaining = 102 - 4 = 98 ✓
└── Sales = 50 (tracked separately) ✓

        ↓

Cost Per Bird Calculation
├── Cost per bird = $2,550 / 102 = $25.00 ✓ CORRECT!
└── Divisor LOCKED - will not change! ✓

        ↓

Recording Second Sale (30 birds)
├── expectedQuantity = 100 (unchanged)
├── actualQuantity = 102 ✓ LOCKED (still not modified!)
├── totalMortality = 4
├── Remaining = 102 - 4 = 98 ✓
└── Sales = 50 + 30 = 80 (tracked separately) ✓

        ↓

Cost Per Bird Calculation (NOW)
├── Cost per bird = $2,550 / 102 = $25.00 ✓ SAME!
└── Divisor remains constant! ✓

✅ RESULT: All metrics consistent and correct!
```

---

## Data Model Relationships

### BEFORE (CONFUSED)

```
Batch Table
┌─────────────────────┬──────┐
│ id: batch-001       │      │
│ expectedQuantity: 100│     │
│ actualQuantity: 102→ → → → 🔄 CHANGES
│ status: active      │      │
└─────────────────────┴──────┘
                          ↓
                    Every Sale
                   Modifies This
                       ❌
```

### AFTER (CORRECT)

```
Batch Table
┌─────────────────────┬──────┐
│ id: batch-001       │      │
│ expectedQuantity: 100│ ✓   │
│ actualQuantity: 102 │ 🔒   │ LOCKED
│ status: active      │      │
└─────────────────────┴──────┘
         ↓         ↓         ↓
      Immutable  Immutable  Immutable
      (FIXED)    (FIXED)    (FIXED)

Daily Records Table        Sales Table
┌───────────────────┐    ┌──────────────┐
│ date: 2026-03-01  │    │ id: sale-001 │
│ mortality: 4      │    │ quantity: 50 │
└───────────────────┘    │ amount: $2500│
                         └──────────────┘
         ↓                       ↓
    Updates totalMortality  Independent of Batch
    (CORRECT)               (CORRECT)
```

---

## Calculation Flow

### Cost Per Unit Calculation

```
BEFORE (BROKEN):
Divisor changes after each action!

Step 1: Batch starts with 102 birds
  Cost/unit = $2,550 / 102 = $25.00 ✓

Step 2: Record 4 mortality
  Cost/unit = $2,550 / 102 = $25.00 ✓

Step 3: Sell 50 birds ❌ actualQuantity becomes 52
  Cost/unit = $2,550 / 52 = $49.04 ✗

Step 4: Sell 30 more birds ❌ actualQuantity becomes 22
  Cost/unit = $2,550 / 22 = $115.91 ✗✗✗

RESULT: Metric is meaningless!


AFTER (FIXED):
Divisor stays locked!

Step 1: Batch starts with 102 birds
  Cost/unit = $2,550 / 102 = $25.00 ✓

Step 2: Record 4 mortality
  Cost/unit = $2,550 / 102 = $25.00 ✓

Step 3: Sell 50 birds ✅ actualQuantity stays 102
  Cost/unit = $2,550 / 102 = $25.00 ✓

Step 4: Sell 30 more birds ✅ actualQuantity still 102
  Cost/unit = $2,550 / 102 = $25.00 ✓

RESULT: Metric is consistent and correct!
```

---

## Mortality Percentage Calculation

```
BEFORE (BROKEN):
Denominator changes!

Batch: 102 birds
Mortality: 4 birds

Step 1: Just recorded mortality
  Mortality % = 4 / 102 = 3.9% ✓

Step 2: After 1st sale (reduced to 52)
  Mortality % = 4 / 52 = 7.7% ✗

Step 3: After 2nd sale (reduced to 22)
  Mortality % = 4 / 22 = 18.2% ✗✗✗

RESULT: Same 4 birds, but % keeps growing! BUG!


AFTER (FIXED):
Denominator locked!

Batch: 102 birds (LOCKED)
Mortality: 4 birds

Step 1: Just recorded mortality
  Mortality % = 4 / 102 = 3.9% ✓

Step 2: After 1st sale
  Mortality % = 4 / 102 = 3.9% ✓

Step 3: After 2nd sale
  Mortality % = 4 / 102 = 3.9% ✓

RESULT: Same 4 birds, same %, metric is stable!
```

---

## Profit Analysis Timeline

```
BEFORE (BROKEN):
                Day 1           Day 5           Day 10
                |               |               |
Batch Start ────●─── Mortality ─● ─ Sale #1 ────●─ Sale #2
                102 birds       102-4=98        102→52=50
                                
Cost/unit       25.00           25.00           49.04 ✗
Profit/unit     N/A             N/A             7.96 ✗
Analysis        OK              OK              WRONG ❌


AFTER (FIXED):
                Day 1           Day 5           Day 10
                |               |               |
Batch Start ────●─── Mortality ─●─ Sale #1 ────●─ Sale #2
                102 birds       102-4=98        102 birds
                (LOCKED)
                
Cost/unit       25.00           25.00           25.00 ✓
Profit/unit     N/A             N/A             33.82 ✓
Analysis        OK              OK              CORRECT ✓
```

---

## Key Difference

### actualQuantity Is NOT:
❌ A running count of birds
❌ Updated when sales happen
❌ Updated when mortality happens
❌ A "live birds" counter

### actualQuantity IS:
✅ Birds physically received
✅ Set once at batch start
✅ Never changes after that
✅ Foundation for cost calculations

---

## Testing the Fix

```
Test Case: Basic Farm Operation
├── Create Batch
│   ├── Expected: 100 birds
│   └── Actual: 102 birds ✓
│
├── Start Batch
│   └── actualQuantity = 102 (LOCKED) 🔒
│
├── Day 3: Add Expenses
│   ├── Feed: $1,500
│   ├── Medicine: $800
│   ├── Other: $250
│   └── Total: $2,550
│
├── Day 5: Record 4 Mortality
│   ├── actualQuantity = 102 (unchanged) 🔒
│   ├── Remaining birds = 102 - 4 = 98
│   └── Cost/bird = $2,550 / 102 = $25.00 ✓
│
├── Day 8: Sell 50 Broilers for $2,500
│   ├── actualQuantity = 102 (unchanged) 🔒
│   ├── Remaining birds = 98 - 50 = 48
│   ├── Cost/bird = $2,550 / 102 = $25.00 ✓ (NO CHANGE!)
│   └── Profit = $2,500 - (50 × $25) = $1,250
│
├── Day 12: Sell 30 Eggs for $500
│   ├── actualQuantity = 102 (unchanged) 🔒
│   ├── Remaining birds = 48 (18 in batch)
│   ├── Cost/bird = $2,550 / 102 = $25.00 ✓ (SAME!)
│   └── Profit = $500 (product sale, not bird-based)
│
└── Final Analysis
    ├── Cost per bird raised = $25.00 ✓ CONSISTENT
    ├── Total revenue = $3,000 ✓
    ├── Net profit = $450 ✓
    ├── ROI = 17.6% ✓
    └── All metrics CORRECT! ✅
```

---

This shows why the fix was critical and how it makes calculations work correctly throughout the batch lifecycle.
