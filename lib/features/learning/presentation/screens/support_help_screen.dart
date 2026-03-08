import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportHelpScreen extends StatefulWidget {
  const SupportHelpScreen({Key? key}) : super(key: key);

  @override
  State<SupportHelpScreen> createState() => _SupportHelpScreenState();
}

class _SupportHelpScreenState extends State<SupportHelpScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _subjectController;
  late TextEditingController _messageController;

  bool _sending = false;
  int _selectedTab = 0; // 0: FAQ, 1: Contact Form

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I upload videos as a creator?',
      'answer':
          'Go to Creator Tools > Videos tab > Manage Videos. Click the Upload Video button and select your video file. Add a title, optional description, and select a category. Videos are limited to 10 minutes and 100MB.'
    },
    {
      'question': 'How do I track my earnings?',
      'answer':
          'Visit Creator Tools > Settings > Earnings to view your total earnings, monthly earnings, active subscribers, and earnings by subscription plan. You can also filter by date range to see earnings for specific periods.'
    },
    {
      'question': 'Can I edit my subscription plans?',
      'answer':
          'Yes, go to Creator Tools > Subscription Plans to edit your existing plans. You can update the price, description, and features. Changes apply to new subscriptions immediately.'
    },
    {
      'question': 'How do I manage notification preferences?',
      'answer':
          'Visit Creator Tools > Settings > Notifications to toggle different notification types. You can control alerts for vaccinations, mortality, batch events, subscriptions, and news updates. Email notifications are optional.'
    },
    {
      'question': 'What video formats are supported?',
      'answer':
          'Smart Farm supports most common video formats including MP4, MOV, AVI, and MKV. For best compatibility, we recommend MP4 with H.264 video codec. Maximum file size is 100MB and duration is 10 minutes.'
    },
    {
      'question': 'How often should I upload content?',
      'answer':
          'We recommend uploading at least 1-2 videos per month to keep your subscribers engaged. Consistent, quality content helps attract and retain subscribers for your creator business.'
    },
    {
      'question': 'Can I delete my account?',
      'answer':
          'Yes, you can request account deletion from Settings. Go to Settings > Account and click "Delete Account". Your data will be securely removed within 30 days.'
    },
    {
      'question': 'How do I contact support?',
      'answer':
          'Use the Contact Form tab on this screen to send us a message. We typically respond within 24 hours. For urgent issues, you can also email support@smartfarm.app directly.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _subjectController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);

    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@smartfarm.app',
        queryParameters: {
          'subject': _subjectController.text,
          'body':
              'From: ${_nameController.text} (${_emailController.text})\n\n${_messageController.text}',
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);

        // Clear form after successful launch
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email opened. Please review and send from your email client.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Tab buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    label: 'FAQ',
                    isActive: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    label: 'Contact Us',
                    isActive: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child:
                _selectedTab == 0 ? _buildFAQView() : _buildContactFormView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primaryGreen : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.primaryGreen : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildFAQView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        return _buildFAQItem(
          question: faq['question']!,
          answer: faq['answer']!,
        );
      },
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We usually respond within 24 hours. Please be as detailed as possible.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Name field
            Text(
              'Full Name',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email field
            Text(
              'Email Address',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subject field
            Text(
              'Subject',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'What is this about?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Subject is required';
                }
                if (value.length < 5) {
                  return 'Subject must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Message field
            Text(
              'Message',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tell us how we can help...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              minLines: 5,
              maxLines: 10,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Message is required';
                }
                if (value.length < 10) {
                  return 'Please provide more details (at least 10 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Alternative contact info
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Other Ways to Reach Us',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactMethod(
                      icon: Icons.email,
                      label: 'Email',
                      value: 'support@smartfarm.app',
                      onTap: () => _launchDirectEmail(),
                    ),
                    const SizedBox(height: 8),
                    _buildContactMethod(
                      icon: Icons.language,
                      label: 'Website',
                      value: 'www.smartfarm.app',
                      onTap: () => _launchURL('https://www.smartfarm.app'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Future<void> _launchDirectEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@smartfarm.app',
      queryParameters: {
        'subject': 'Support Request',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
