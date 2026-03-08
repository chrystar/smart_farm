import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:smart_farm/core/constants/theme/app_color.dart';

class CreatorSignupScreen extends StatefulWidget {
  const CreatorSignupScreen({Key? key}) : super(key: key);

  @override
  State<CreatorSignupScreen> createState() => _CreatorSignupScreenState();
}


class _CreatorSignupScreenState extends State<CreatorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _hasExistingApplication = false;
  Map<String, dynamic>? _existingApplication;

  // Form controllers
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();

  // Profile picture
  Uint8List? _profilePicBytes;
  // Removed unused _profilePicUrl

  // Multi-select for specializations
  final List<String> _allSpecializations = [
    'Layer Farming',
    'Broiler Production',
    'Disease Management',
    'Nutrition & Feeding',
    'Housing & Infrastructure',
    'Breeding & Genetics',
    'Vaccination Protocols',
    'Farm Management',
    'Market & Sales',
    'Sustainability',
  ];
  
  late Set<String> _selectedSpecializations = {};

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('creator_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (response != null) {
        setState(() {
          _hasExistingApplication = true;
          _existingApplication = response;
        });
      }
    } catch (e) {
      debugPrint('Error checking application: $e');
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _yearsExperienceController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one specialization'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms & Conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      String? picUrl;
      if (_profilePicBytes != null) {
        final fileName = 'creator_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('creator-profile-pics')
            .uploadBinary(fileName, _profilePicBytes!, fileOptions: const FileOptions(contentType: 'image/jpeg'));
        picUrl = Supabase.instance.client.storage
            .from('creator-profile-pics')
            .getPublicUrl(fileName);
      }
      await Supabase.instance.client.from('creator_profiles').upsert({
        'user_id': user.id,
        'display_name': _displayNameController.text,
        'bio': _bioController.text,
        'profile_picture_url': picUrl,
        'years_experience': int.tryParse(_yearsExperienceController.text),
        'specializations': _selectedSpecializations.toList(),
        'phone': _phoneController.text,
        'website': _websiteController.text,
      });
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _profilePicBytes = bytes;
      });
    }
  }

  Widget _buildApplicationReviewView() {
    final app = _existingApplication!;
    final isApproved = app['approved'] == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Application'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isApproved ? Colors.green[50] : Colors.blue[50],
                border: Border.all(
                  color: isApproved ? Colors.green : Colors.blue,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    isApproved ? Icons.check_circle : Icons.schedule,
                    color: isApproved ? Colors.green : Colors.blue,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isApproved ? 'Application Approved!' : 'Application Under Review',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isApproved ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isApproved
                        ? 'Your application has been approved. You can now access creator tools!'
                        : 'Your application is being reviewed by our team. We\'ll notify you shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isApproved ? Colors.green[700] : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Application Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildApplicationDetailCard('Display Name', app['display_name'] ?? 'N/A'),
            _buildApplicationDetailCard('Bio', app['bio'] ?? 'N/A'),
            _buildApplicationDetailCard('Phone', app['phone'] ?? 'N/A'),
            _buildApplicationDetailCard('Website', app['website'] ?? 'N/A'),
            _buildApplicationDetailCard('Years Experience', app['years_experience']?.toString() ?? 'N/A'),
            if (app['specializations'] != null && (app['specializations'] as List).isNotEmpty)
              _buildApplicationDetailCard(
                'Specializations',
                (app['specializations'] as List).join(', '),
              ),
            if (app['profile_picture_url'] != null) ...[
              const SizedBox(height: 16),
              const Text('Profile Picture', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(app['profile_picture_url']),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationDetailCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.primaryGreen,
          size: 64,
        ),
        title: const Text('Application Submitted!'),
        content: const Text(
          'Thank you for applying to become a Creator Farmer!\n\n'
          'Our team will review your application within 24-48 hours. '
          'You\'ll receive an email confirmation shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasExistingApplication) {
      return _buildApplicationReviewView();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Creator Farmer'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share Your Farming Knowledge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Become an expert creator and earn from your experience',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Benefits
                  _BenefitRow(
                    icon: Icons.monetization_on,
                    text: 'Earn 70% from subscriptions',
                  ),
                  _BenefitRow(
                    icon: Icons.people,
                    text: 'Build your farming community',
                  ),
                  _BenefitRow(
                    icon: Icons.verified,
                    text: 'Get verified creator badge',
                  ),
                ],
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Name
                    _SectionTitle('Profile Information'),
                    const SizedBox(height: 16),
                    // Profile Picture
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: _profilePicBytes != null
                              ? MemoryImage(_profilePicBytes!)
                              : null,
                          child: _profilePicBytes == null
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _pickProfilePicture,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Add Profile Picture'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: _buildInputDecoration(
                        label: 'Display Name',
                        hint: 'How farmers will see you',
                        icon: Icons.person,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Display name is required';
                        }
                        if (value.length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Bio
                    TextFormField(
                      controller: _bioController,
                      decoration: _buildInputDecoration(
                        label: 'Professional Bio',
                        hint: 'Tell farmers about your experience',
                        icon: Icons.description,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bio is required';
                        }
                        if (value.length < 20) {
                          return 'Bio must be at least 20 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Years of Experience
                    TextFormField(
                      controller: _yearsExperienceController,
                      decoration: _buildInputDecoration(
                        label: 'Years of Experience',
                        hint: 'How many years farming?',
                        icon: Icons.timeline,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Years of experience is required';
                        }
                        final years = int.tryParse(value);
                        if (years == null || years < 1) {
                          return 'Please enter a valid number';
                        }
                        if (years < 2) {
                          return 'Minimum 2 years of experience required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Specializations
                    _SectionTitle('Your Specializations'),
                    const SizedBox(height: 12),
                    Text(
                      'Select areas where you have expertise (at least 1)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allSpecializations.map((spec) {
                        final isSelected = _selectedSpecializations.contains(spec);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(spec),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSpecializations.add(spec);
                              } else {
                                _selectedSpecializations.remove(spec);
                              }
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Contact Information
                    _SectionTitle('Contact Information'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _buildInputDecoration(
                        label: 'Phone Number',
                        hint: '+254 7XX XXX XXX',
                        icon: Icons.phone,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Website (Optional)
                    TextFormField(
                      controller: _websiteController,
                      decoration: _buildInputDecoration(
                        label: 'Website (Optional)',
                        hint: 'https://yourwebsite.com',
                        icon: Icons.language,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    // Terms & Conditions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _agreedToTerms,
                                onChanged: (value) {
                                  setState(() => _agreedToTerms = value ?? false);
                                },
                                activeColor: AppColors.primaryGreen,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() =>
                                        _agreedToTerms = !_agreedToTerms);
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                      children: [
                                        const TextSpan(
                                            text: 'I agree to the '),
                                        TextSpan(
                                          text: 'Terms & Conditions',
                                          style: TextStyle(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const TextSpan(
                                            text: ' and '),
                                        TextSpan(
                                          text: 'Creator Guidelines',
                                          style: TextStyle(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'By becoming a Creator Farmer, you commit to providing accurate, '
                            'helpful content that follows our community guidelines.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Submit Application',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Secondary Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryGreen),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primaryGreen,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
