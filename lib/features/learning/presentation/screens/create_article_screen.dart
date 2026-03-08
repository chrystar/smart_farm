import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({Key? key}) : super(key: key);

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedCategory = 'General';
  List<String> categories = [
    'General',
    'Farming Tips',
    'Health',
    'Technology',
    'Weather',
    'Livestock',
    'Crop Management',
  ];

  bool _isPublishing = false;
  bool _isFeatured = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickArticleImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadArticleImage(String articleId) async {
    if (_selectedImage == null) return null;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final fileName = '${articleId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'articles/${user.id}/$fileName';

      await Supabase.instance.client.storage
          .from('article-images')
          .upload(filePath, _selectedImage!);

      final imageUrl = Supabase.instance.client.storage
          .from('article-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _publishArticle() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      const uuid = Uuid();
      final articleId = uuid.v4();

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadArticleImage(articleId);
      }

      // Insert article into creator_articles table
      await Supabase.instance.client.from('creator_articles').insert({
        'id': articleId,
        'user_id': user.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'image_url': imageUrl,
        'featured': _isFeatured,
        'views': 0,
        'likes': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error publishing article: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing article: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Article'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              _buildLabel('Article Title *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 150,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: 'Enter article title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Article Image
              _buildLabel('Article Cover Image'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isPublishing ? null : _pickArticleImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedImage != null ? AppColors.primaryGreen : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _selectedImage != null ? null : Colors.grey[100],
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedImage = null);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to add cover image',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG, PNG up to 5MB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Description Field
              _buildLabel('Description (Brief Summary) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a brief description of your article',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (value.length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              _buildLabel('Category *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Main Content Field
              _buildLabel('Article Content *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 15,
                minLines: 10,
                decoration: InputDecoration(
                  hintText: 'Write your complete article here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Article content is required';
                  }
                  if (value.length < 50) {
                    return 'Article must be at least 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Featured Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isFeatured,
                    onChanged: (value) {
                      setState(() => _isFeatured = value ?? false);
                    },
                    activeColor: AppColors.primaryGreen,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isFeatured = !_isFeatured);
                      },
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mark as Featured',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This article will appear highlighted on your profile',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Character Count Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your article has ${_contentController.text.split(' ').where((word) => word.isNotEmpty).length} words',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Publish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPublishing ? null : _publishArticle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Publish Article',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isPublishing
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}
