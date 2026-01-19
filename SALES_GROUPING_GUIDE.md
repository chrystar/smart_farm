# 📁 Sales Grouping Feature

## Overview
Group multiple sales together for better organization and tracking. Perfect for grouping sales by week, month, customer, or any custom category.

---

## How to Use

### Step 1: Enter Selection Mode
**Long press** on any sale card in the Sales List Screen

✅ The screen enters **Selection Mode**:
- Close button (×) appears in app bar
- Checkboxes appear on all sale cards
- Select All and Create Group icons appear in app bar

### Step 2: Select Sales to Group
**Tap** on sale cards to select/deselect them

- Selected cards have a light blue background
- Checkboxes show which sales are selected
- App bar shows count: "3 selected"

**Quick Actions:**
- Tap **Select All** icon to select/deselect all sales
- Tap the **×** button to exit selection mode

### Step 3: Create the Group
Tap the **Folder icon** in the app bar

A dialog appears asking for:
- **Group Title**: e.g., "Week 1 Sales", "January Batch", "Customer ABC"
- Shows how many sales you selected

Tap **Create** to group the sales

✅ Success notification appears
✅ Selection mode exits automatically
✅ Sales list refreshes with new group

---

## Grouped Display

### Group Headers
Groups display with a distinct header:
```
┌─────────────────────────────────┐
│ 📁 Week 1 Sales                 │
│ 5 sales · USD 2,500.00          │
└─────────────────────────────────┘
```

**Header shows:**
- 📁 Folder icon
- Group title
- Number of sales in group
- Total amount across all sales

### Group Members
Sales in a group are indented below the header:
- All sales from the same group stay together
- Sorted by sale date within the group

### Ungrouped Sales
Sales not in any group appear under "Ungrouped Sales" heading (if groups exist)

---

## Technical Details

### Database Schema
Added to `sales` table:
```sql
group_id TEXT,
group_title TEXT,
```

### New Index
```sql
CREATE INDEX idx_sales_group_id ON sales(group_id);
```

### Provider Methods
```dart
// Create a group
await provider.createSaleGroup(groupTitle, saleIds);

// Get sales organized by groups
Map<String?, List<Sale>> grouped = provider.getSalesGrouped();
```

---

## Use Cases

### 1. Weekly/Monthly Grouping
Group sales by time periods:
- "Week 1 - Jan 2026"
- "December Sales"
- "Q1 2026"

### 2. Customer Grouping
Group sales by buyer:
- "Acme Corp Orders"
- "John's Purchases"
- "Bulk Order #123"

### 3. Batch Grouping
Organize sales from same production cycle:
- "Batch A Sales"
- "Spring 2026 Batch"

### 4. Campaign Grouping
Track sales from marketing campaigns:
- "Promo Week Sales"
- "Black Friday"

---

## Benefits

✅ **Better Organization** - Find related sales quickly
✅ **Quick Totals** - See group revenue at a glance
✅ **Flexible** - Create groups for any purpose
✅ **Visual Clarity** - Groups stand out with headers and indentation
✅ **Easy Selection** - Long press to activate, tap to select multiple

---

## Tips

💡 **Select Multiple at Once**: Use "Select All" then deselect unwanted sales

💡 **Group Later**: Sales can be added to groups anytime after creation

💡 **Meaningful Names**: Use descriptive group titles for easy identification

💡 **Regular Grouping**: Group sales weekly/monthly for better tracking

---

## Migration Note

If you already have the sales table created, run this to add group support:

```sql
-- Add group columns to existing sales table
ALTER TABLE sales ADD COLUMN group_id TEXT;
ALTER TABLE sales ADD COLUMN group_title TEXT;

-- Add index for better query performance
CREATE INDEX idx_sales_group_id ON sales(group_id);
```

---

**Status**: ✅ Feature Complete & Tested
**Files Updated**: 10+ files across domain/data/presentation layers
