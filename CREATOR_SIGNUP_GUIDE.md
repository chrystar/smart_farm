# Creator Signup Screen - Implementation Guide

## Overview
A comprehensive creator signup form that allows farmers to apply to become Creator Farmers on the SmartFarm platform. The form includes validation, multi-select specializations, and a professional application flow.

---

## File Location
`lib/features/learning/presentation/screens/creator_signup_screen.dart`

---

## Features

### 1. **Profile Information Section**
- **Display Name** - How farmers will see them (required, min 3 chars)
- **Professional Bio** - Background and experience description (required, min 20 chars)
- **Years of Experience** - Number of years farming (required, min 2 years)

### 2. **Specializations Selection**
Multi-select chip-based UI with 10 specialization options:
- Layer Farming
- Broiler Production
- Disease Management
- Nutrition & Feeding
- Housing & Infrastructure
- Breeding & Genetics
- Vaccination Protocols
- Farm Management
- Market & Sales
- Sustainability

**Requirement:** At least 1 specialization must be selected

### 3. **Contact Information**
- **Phone Number** - For communication (required, min 10 chars)
- **Website** - Optional personal/business website

### 4. **Terms & Conditions**
- Checkbox agreement required
- Highlights commitment to providing accurate, helpful content
- Links to Terms & Conditions and Creator Guidelines

### 5. **Visual Elements**
- Header banner with benefits highlight
- Benefits displayed with icons:
  - 💰 Earn 70% from subscriptions
  - 👥 Build your farming community
  - ✓ Get verified creator badge
- Professional form styling with consistent colors
- Loading state during submission

---

## Form Validation

| Field | Validation |
|-------|-----------|
| Display Name | Required, 3+ characters |
| Bio | Required, 20+ characters |
| Years of Experience | Required, 2+ years (integer) |
| Phone Number | Required, 10+ characters |
| Website | Optional (URL format) |
| Specializations | At least 1 required |
| Terms Agreement | Must be checked |

---

## User Flow

```
1. User opens drawer
2. Taps "Become a Creator" button
3. Sees signup form with:
   - Header banner showing benefits
   - Profile information fields
   - Specialization multi-select
   - Contact information
   - Terms & conditions checkbox
4. Fills out form
5. Validates all fields
6. Submits application
7. Sees success dialog
8. Returns to main app
```

---

## Integration with App

### In `app.dart`:
```dart
// Added to drawer
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: ElevatedButton.icon(
    onPressed: () => _navigateTo(const CreatorSignupScreen()),
    icon: const Icon(Icons.star),
    label: const Text('Become a Creator'),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 48),
    ),
  ),
),
```

---

## Success Flow

After successful submission:
1. Shows success dialog with checkmark icon
2. Displays message: "Application Submitted!"
3. Explains review timeline (24-48 hours)
4. User taps "Done" to close dialog
5. Returns to previous screen

---

## Backend Integration (To-Do)

### API Endpoint:
```dart
Future<void> _submitApplication() async {
  try {
    final response = await Supabase.instance.client
        .from('creator_applications')
        .insert({
          'user_id': currentUserId,
          'display_name': _displayNameController.text,
          'bio': _bioController.text,
          'years_experience': int.parse(_yearsExperienceController.text),
          'specializations': _selectedSpecializations.toList(),
          'phone': _phoneController.text,
          'website': _websiteController.text,
          'status': 'pending_review',
          'created_at': DateTime.now().toIso8601String(),
        });
    
    // Show success dialog
    _showSuccessDialog();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### Database Schema:
```sql
CREATE TABLE creator_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  display_name TEXT NOT NULL,
  bio TEXT NOT NULL,
  years_experience INTEGER NOT NULL CHECK (years_experience >= 2),
  specializations TEXT[] NOT NULL,
  phone TEXT NOT NULL,
  website TEXT,
  status TEXT DEFAULT 'pending_review', -- pending_review, approved, rejected
  rejection_reason TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Admin can view pending applications
CREATE TABLE IF NOT EXISTS creator_applications_rls_access AS
SELECT * FROM creator_applications
WHERE status = 'pending_review';
```

---

## UI Components

### 1. **_SectionTitle Widget**
Styled section headers with green color accent

### 2. **_BenefitRow Widget**
Displays benefit icons with text in header banner

### 3. **_buildInputDecoration Method**
Consistent text field styling with:
- Green icon prefix
- Rounded corners (12px)
- Custom focus/error states
- Hint text

---

## Styling & Colors

- **Primary Color**: AppColors.primaryGreen
- **Background**: White
- **Input Fields**: Border radius 12px, green focus state
- **Chips**: Green selected state with opacity
- **Buttons**: Full-width with rounded corners
- **Text Colors**: Black87 for main text, grey for secondary

---

## State Management

### Form Controllers:
- `_displayNameController`
- `_bioController`
- `_yearsExperienceController`
- `_websiteController`
- `_phoneController`

### Form State:
- `_selectedSpecializations` (Set<String>)
- `_agreedToTerms` (bool)
- `_isLoading` (bool)

### Cleanup:
All controllers are disposed in `dispose()` method

---

## Error Handling

✅ Form validation on submit
✅ Specialization selection check
✅ Terms agreement check
✅ Loading state during submission
✅ Toast notifications for errors
✅ Success dialog for completion

---

## Future Enhancements

### Phase 1:
- [ ] Connect to Supabase `creator_applications` table
- [ ] Real phone validation
- [ ] Email verification

### Phase 2:
- [ ] Photo upload for creator profile
- [ ] CV/qualification document upload
- [ ] Video introduction upload

### Phase 3:
- [ ] Admin dashboard to review applications
- [ ] Automated email notifications
- [ ] Approval workflow
- [ ] Creator profile creation after approval

### Phase 4:
- [ ] Email verification flow
- [ ] Two-factor authentication for creators
- [ ] Creator onboarding tutorial
- [ ] Initial content guidelines video

---

## Testing Checklist

- [ ] Display Name validation (empty, < 3 chars)
- [ ] Bio validation (empty, < 20 chars)
- [ ] Years of experience validation (empty, < 2, non-integer)
- [ ] Phone number validation (empty, < 10 chars)
- [ ] Website URL validation (optional, but format check if provided)
- [ ] Specialization selection (show error if none selected)
- [ ] Terms checkbox required
- [ ] Form submission with loading state
- [ ] Success dialog display
- [ ] Navigation back to previous screen
- [ ] Form reset on cancel
- [ ] Responsive design on different screen sizes
- [ ] Keyboard handling for text fields
- [ ] Chip toggle for specializations

---

## User Experience Notes

✅ **Clear Benefits** - Header shows what creators get
✅ **Progressive Disclosure** - Fields are grouped logically
✅ **Visual Feedback** - Loading spinner during submission
✅ **Success State** - Clear confirmation with next steps
✅ **Easy Navigation** - Clear buttons for submit/cancel
✅ **Input Guidance** - Hints and labels for each field
✅ **Mobile Friendly** - SingleChildScrollView for scrolling
✅ **Accessible** - FormField with validators

---

## Code Quality

- ✅ Uses `GlobalKey<FormState>` for form validation
- ✅ Proper state management with setState
- ✅ Input decorations consistent across fields
- ✅ Custom widgets for reusability
- ✅ Comments for clarity
- ✅ Error handling and validation
- ✅ Memory management (controller disposal)
- ✅ Proper Flutter conventions

---

## Access

### From Drawer:
1. Open SmartFarm app
2. Tap hamburger menu (≡)
3. Tap "Become a Creator" button (green, with star icon)
4. Fill out application form

### Direct Navigation:
```dart
context.push('/creator-signup');
// or
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const CreatorSignupScreen(),
));
```

---

## Summary

The Creator Signup Screen provides:
✅ Professional application form
✅ Comprehensive data collection
✅ Input validation
✅ Success tracking
✅ Ready for backend integration
✅ Scalable design

Ready to integrate with Supabase and admin review system! 🚀

