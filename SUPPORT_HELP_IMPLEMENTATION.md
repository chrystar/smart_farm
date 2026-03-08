# Support/Help Screen Implementation Guide

## Overview
Complete help and support system for Smart Farm creators with comprehensive FAQ, contact form, and email integration for direct communication with support team.

## Implementation Status: ✅ COMPLETE

### Features Implemented
- ✅ FAQ display with 8 expandable questions
- ✅ Contact form with validation
- ✅ Email integration via mailto
- ✅ Alternative contact methods (email, website)
- ✅ Tab navigation (FAQ/Contact)
- ✅ Form validation (name, email, subject, message)
- ✅ Loading states during submission
- ✅ Integration with Creator Tools

---

## Architecture

### Location
`lib/features/learning/presentation/screens/support_help_screen.dart`

### State Management
- StatefulWidget with local form state
- Form validation with GlobalKey<FormState>
- TextEditingController for form fields

### Data Structure
```dart
List<Map<String, String>> _faqs = [
  {
    'question': 'FAQ Question',
    'answer': 'FAQ Answer'
  },
  // ... more FAQs
]
```

---

## Features Deep Dive

### 1. FAQ Section

**Display**: 8 expandable cards with Q&A

**Topics Covered**:
1. **Video Upload** - Format, size, duration limits
2. **Earnings Tracking** - How to view and filter earnings
3. **Subscription Plans** - Plan editing and management
4. **Notifications** - Preference management and types
5. **Video Formats** - Supported formats and recommendations
6. **Content Upload Frequency** - Best practices
7. **Account Deletion** - How to delete account
8. **Contact Support** - How to reach support team

**UI Component**:
```dart
_buildFAQItem(question, answer)
  - ExpansionTile for expand/collapse
  - Bold question text
  - Gray answer text with proper spacing
  - Proper indentation and padding
```

### 2. Contact Form

**Fields**:

1. **Full Name**
   - Required: ✅
   - Min length: 2 characters
   - Validation: Non-empty, length check

2. **Email Address**
   - Required: ✅
   - Format: Valid email regex
   - Validation: Format and empty check

3. **Subject**
   - Required: ✅
   - Min length: 5 characters
   - Validation: Non-empty, length check

4. **Message**
   - Required: ✅
   - Min length: 10 characters
   - Min lines: 5 (expandable)
   - Validation: Non-empty, length check

**Form Actions**:
- **Send Message** button
  - Validates all fields
  - Shows loading spinner during send
  - Launches email client with pre-filled data
  - Clears form on success
  - Shows feedback message

### 3. Email Integration

**Method**: Native `mailto:` URI

**Flow**:
1. User fills form and clicks Send
2. Form validation runs
3. Mailto URI constructed with:
   - Recipient: support@smartfarm.app
   - Subject: User's subject
   - Body: Name, email, and message
4. Native email client opens
5. User reviews and sends manually
6. Form clears

**Implementation**:
```dart
Future<void> _sendEmail() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'support@smartfarm.app',
    queryParameters: {
      'subject': subject,
      'body': 'From: name (email)\n\nmessage',
    },
  );
  
  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  }
}
```

### 4. Tab Navigation

**Tabs**:
- FAQ (default)
- Contact Us

**Indicator**: Green underline on active tab

**Content**: Switches between FAQ list and contact form

---

## UI Components

### Tab Button
```dart
_buildTabButton(label, isActive, onTap)
  - Green underline when active
  - Gray text when inactive
  - Clickable full width
```

### FAQ Item
```dart
_buildFAQItem(question, answer)
  - Card with ExpansionTile
  - Bold question
  - Detailed answer on expand
  - Proper spacing
```

### Contact Method
```dart
_buildContactMethod(icon, label, value, onTap)
  - Icon + label + value layout
  - Clickable to launch email/URL
  - Chevron indicator
```

---

## Form Validation

**Validation Rules**:
```
Name:
  - Required ✅
  - Min 2 characters ✅
  - Error: "Name is required" or "Name must be at least 2 characters"

Email:
  - Required ✅
  - Valid email format ✅
  - Regex: ^\w-\.]+@([\w-]+\.)+[\w-]{2,4}$
  - Error: "Email is required" or "Please enter a valid email"

Subject:
  - Required ✅
  - Min 5 characters ✅
  - Error: "Subject is required" or "Subject must be at least 5 characters"

Message:
  - Required ✅
  - Min 10 characters ✅
  - Error: "Message is required" or "Please provide more details (at least 10 characters)"
```

---

## Error Handling

### Network/Launch Errors
- Graceful fallback if email client unavailable
- User-friendly error messages
- Snackbar feedback
- No app crash

### Form Errors
- Field-level validation on submit
- Error messages appear below field
- Submit button disabled during send
- User can correct and resubmit

---

## Alternative Contact Methods

**Displayed in contact form**:

1. **Direct Email**
   - Label: support@smartfarm.app
   - Action: Launches email client
   - Icon: Email icon

2. **Website**
   - Label: www.smartfarm.app
   - Action: Launches web browser
   - Icon: Globe icon

**Purpose**: Give users multiple ways to reach support

---

## User Experience

### FAQ User Flow
1. User opens Support/Help
2. FAQ tab is default
3. User sees list of 8 expandable questions
4. User taps question to expand answer
5. Answer displays with formatting
6. User can collapse or read another

### Contact Form User Flow
1. User opens Support/Help
2. User clicks "Contact Us" tab
3. User sees contact form
4. User fills in name, email, subject, message
5. User clicks "Send Message"
6. Form validates
7. Email client opens with pre-filled data
8. User reviews and sends
9. Success message shows
10. Form clears

---

## Styling & Appearance

### Color Scheme
- Primary: AppColors.primaryGreen (tabs, buttons, icons)
- Secondary: Gray (inactive text, borders)
- Background: White (cards, input fields)
- Info: Light green background (info card)

### Typography
- Tab labels: 16px bold
- FAQ question: 14px bold
- FAQ answer: 13px gray
- Form labels: 14px bold
- Form hints: 13px gray
- Buttons: 16px bold

### Layout
- Padding: 16px screen edges
- Spacing: 12-24px between sections
- Card elevation: 1
- Border radius: 8px

---

## File Structure

### New Files
```
lib/features/learning/presentation/screens/
  └── support_help_screen.dart (680 lines)
```

### Modified Files
```
lib/features/learning/presentation/screens/
  └── creator_tools_screen.dart
      - Added import for SupportHelpScreen
      - Updated Help & Support button navigation
```

### Dependencies
- `flutter/material.dart` - UI framework
- `url_launcher` - Email and URL launching
- `app_color.dart` - Color constants

---

## FAQ Content

### Question 1: Video Upload
**Q**: How do I upload videos as a creator?
**A**: Go to Creator Tools > Videos tab > Manage Videos. Click the Upload Video button and select your video file. Add a title, optional description, and select a category. Videos are limited to 10 minutes and 100MB.

### Question 2: Earnings
**Q**: How do I track my earnings?
**A**: Visit Creator Tools > Settings > Earnings to view your total earnings, monthly earnings, active subscribers, and earnings by subscription plan. You can also filter by date range to see earnings for specific periods.

### Question 3: Subscription Plans
**Q**: Can I edit my subscription plans?
**A**: Yes, go to Creator Tools > Subscription Plans to edit your existing plans. You can update the price, description, and features. Changes apply to new subscriptions immediately.

### Question 4: Notifications
**Q**: How do I manage notification preferences?
**A**: Visit Creator Tools > Settings > Notifications to toggle different notification types. You can control alerts for vaccinations, mortality, batch events, subscriptions, and news updates. Email notifications are optional.

### Question 5: Video Formats
**Q**: What video formats are supported?
**A**: Smart Farm supports most common video formats including MP4, MOV, AVI, and MKV. For best compatibility, we recommend MP4 with H.264 video codec. Maximum file size is 100MB and duration is 10 minutes.

### Question 6: Upload Frequency
**Q**: How often should I upload content?
**A**: We recommend uploading at least 1-2 videos per month to keep your subscribers engaged. Consistent, quality content helps attract and retain subscribers for your creator business.

### Question 7: Account Deletion
**Q**: Can I delete my account?
**A**: Yes, you can request account deletion from Settings. Go to Settings > Account and click "Delete Account". Your data will be securely removed within 30 days.

### Question 8: Contacting Support
**Q**: How do I contact support?
**A**: Use the Contact Form tab on this screen to send us a message. We typically respond within 24 hours. For urgent issues, you can also email support@smartfarm.app directly.

---

## Testing Checklist

### FAQ Section
- [ ] 8 FAQ questions display
- [ ] Questions expand on tap
- [ ] Answers display with formatting
- [ ] Questions collapse on tap
- [ ] No horizontal scroll needed

### Contact Form
- [ ] Form appears on Contact Us tab
- [ ] All 4 fields visible and functional
- [ ] Form validation works
- [ ] Name validation triggers
- [ ] Email validation triggers
- [ ] Subject validation triggers
- [ ] Message validation triggers

### Email Integration
- [ ] Email client opens on submit
- [ ] Pre-filled with form data
- [ ] Subject correct
- [ ] Body formatted correctly
- [ ] Form clears after success
- [ ] Success message shows

### Tab Navigation
- [ ] FAQ tab default on open
- [ ] Contact Us tab clickable
- [ ] Green indicator on active tab
- [ ] Content switches correctly
- [ ] No state loss on tab switch

### Alternative Methods
- [ ] Direct email link works
- [ ] Website link opens browser
- [ ] Both show in contact form
- [ ] Proper icons displayed

### Edge Cases
- [ ] Very long question answered
- [ ] Special characters in form
- [ ] Unicode in form fields
- [ ] Network error handled
- [ ] No email client available

---

## Future Enhancements

### Phase 2 (Ticketing System)
- [ ] Backend ticket creation
- [ ] Ticket tracking/history
- [ ] Automated responses
- [ ] Support category selection
- [ ] Attachment support

### Phase 3 (Chat Support)
- [ ] Live chat widget
- [ ] Chat history
- [ ] Support agent assignment
- [ ] Real-time messaging
- [ ] Typing indicators

### Phase 4 (Knowledge Base)
- [ ] Searchable KB articles
- [ ] Video tutorials
- [ ] Step-by-step guides
- [ ] Troubleshooting guides
- [ ] Community Q&A

---

## Integration with Creator Tools

### Location in Navigation
Creator Tools Screen → Settings Tab → Help & Support Button

### Navigation Flow
```
Creator Tools (Settings tab)
  → _buildSettingItem("Help & Support")
    → SupportHelpScreen
      → FAQ Tab / Contact Form Tab
```

### Implementation
```dart
_buildSettingItem(
  icon: Icons.help,
  title: 'Help & Support',
  subtitle: 'Get help with creator tools',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportHelpScreen(),
      ),
    );
  },
)
```

---

## Security & Privacy

### Email Privacy
- User email visible in mailto but not stored by app
- Backend should validate sender
- Email content unencrypted in transit (user responsibility)
- Consider adding GDPR/privacy notice if needed

### Form Data
- No data persisted locally
- Form clears after send
- User's email client handles data
- No analytics tracking

### Recommendations
- Add server-side rate limiting on support emails
- Validate sender email on backend
- Consider authentication tokens for security
- Archive support emails for compliance

---

## Troubleshooting

### Email Not Opening
**Issue**: "Could not launch email" message

**Solutions**:
1. Check device has email client configured
2. Try alternative contact methods
3. Ensure mailto: URI correctly formatted
4. Check url_launcher permissions

### Form Validation Fails
**Issue**: Form won't submit

**Solutions**:
1. Check all required fields filled
2. Verify email format (user@domain.com)
3. Ensure message is 10+ characters
4. Check for special characters

### FAQ Not Displaying
**Issue**: FAQ section empty

**Solutions**:
1. Verify _faqs list initialized
2. Check ListView.builder itemCount
3. Clear app cache
4. Restart app

---

## Migration Instructions

### Step 1: Deploy Code
Files are ready to use - no database changes needed.

```bash
flutter clean
flutter pub get
```

### Step 2: Test
1. Login as creator
2. Go to Creator Tools → Settings
3. Click "Help & Support"
4. View FAQ (should see 8 questions)
5. Click Contact Us tab
6. Fill form and send (will open email)

---

## Summary

✅ **Complete support/help system implemented**

**What was built:**
- Professional FAQ with 8 comprehensive questions ✓
- Validated contact form with 4 fields ✓
- Email integration via mailto ✓
- Tab navigation between FAQ and contact ✓
- Alternative contact methods (email, website) ✓
- Error handling and user feedback ✓
- Integration with Creator Tools ✓

**Key Metrics:**
- 8 FAQ items covering major features
- Form validation with helpful error messages
- Email client launch for direct communication
- Professional Material Design UI
- No database changes needed
- Ready for immediate use

**Ready to Use:** Creators can immediately access FAQs and contact support via the integrated form.

**Priority 1 Task Status:** ✅ **COMPLETE** - Support/Help Screen fully implemented with FAQ, contact form, and email integration.

---

*Last Updated: 2026-02-27*
*Implementation Status: Complete*
*Developer: GitHub Copilot*
