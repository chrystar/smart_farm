import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class VideoUploadScreen extends StatefulWidget {
  final Map<String, dynamic>? video; // Null for new video, populated for edit

  const VideoUploadScreen({
    Key? key,
    this.video,
  }) : super(key: key);

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isFeatured = false;
  bool _uploading = false;
  double _uploadProgress = 0.0;

  File? _selectedVideoFile;
  File? _selectedThumbnailFile;
  String? _existingVideoUrl;
  String? _existingThumbnailUrl;

  final List<String> _categories = [
    'General',
    'Poultry Management',
    'Feeding & Nutrition',
    'Disease Prevention',
    'Business & Marketing',
    'Housing & Equipment',
    'Tips & Tricks',
    'Success Stories',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.video != null) {
      // Editing existing video
      _titleController.text = widget.video!['title'] ?? '';
      _descriptionController.text = widget.video!['description'] ?? '';
      _selectedCategory = widget.video!['category'] ?? 'General';
      _isFeatured = widget.video!['featured'] ?? false;
      _existingVideoUrl = widget.video!['video_url'];
      _existingThumbnailUrl = widget.video!['thumbnail_url'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // 10 minute limit
      );

      if (video != null) {
        final file = File(video.path);
        final fileSize = await file.length();

        // Check file size (100MB limit)
        if (fileSize > 100 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Video file is too large. Maximum size is 100MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedVideoFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedThumbnailFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking thumbnail: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadFile(File file, String bucket, String folder) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = '$folder/$fileName';

      // Upload with progress tracking
      await Supabase.instance.client.storage.from(bucket).upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl =
          Supabase.instance.client.storage.from(bucket).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if video is selected for new uploads
    if (widget.video == null && _selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String? videoUrl = _existingVideoUrl;
      String? thumbnailUrl = _existingThumbnailUrl;
      int? fileSizeBytes;

      // Upload new video if selected
      if (_selectedVideoFile != null) {
        setState(() => _uploadProgress = 0.2);
        videoUrl =
            await _uploadFile(_selectedVideoFile!, 'creator-videos', 'videos');
        fileSizeBytes = await _selectedVideoFile!.length();
        setState(() => _uploadProgress = 0.6);
      }

      // Upload new thumbnail if selected
      if (_selectedThumbnailFile != null) {
        setState(() => _uploadProgress = 0.7);
        thumbnailUrl = await _uploadFile(
            _selectedThumbnailFile!, 'creator-videos', 'thumbnails');
        setState(() => _uploadProgress = 0.9);
      }

      final videoData = {
        'user_id': userId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'file_size_bytes': fileSizeBytes,
        'category': _selectedCategory,
        'featured': _isFeatured,
      };

      if (widget.video != null) {
        // Update existing video
        await Supabase.instance.client
            .from('creator_videos')
            .update(videoData)
            .eq('id', widget.video!['id']);
      } else {
        // Create new video
        await Supabase.instance.client.from('creator_videos').insert(videoData);
      }

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.video != null
                  ? 'Video updated successfully!'
                  : 'Video uploaded successfully!',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.video != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Video' : 'Upload Video'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Video Selection
            if (!isEditing || _selectedVideoFile != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _uploading ? null : _pickVideo,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          _selectedVideoFile != null
                              ? Icons.video_library
                              : Icons.video_call,
                          size: 64,
                          color: _selectedVideoFile != null
                              ? AppColors.primaryGreen
                              : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedVideoFile != null
                              ? 'Video Selected'
                              : 'Tap to Select Video',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedVideoFile != null) ...[
                          const SizedBox(height: 8),
                          FutureBuilder<int>(
                            future: _selectedVideoFile!.length(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  _formatFileSize(snapshot.data!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            'Max 100MB • Max 10 minutes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Thumbnail Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: _uploading ? null : _pickThumbnail,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedThumbnailFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedThumbnailFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _existingThumbnailUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _existingThumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.image,
                                            size: 40);
                                      },
                                    ),
                                  )
                                : const Icon(Icons.image, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thumbnail',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedThumbnailFile != null ||
                                      _existingThumbnailUrl != null
                                  ? 'Tap to change'
                                  : 'Tap to add thumbnail',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Video Title *',
                hintText: 'Enter a descriptive title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _categories.map((category) {
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
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add details about the video',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Featured toggle
            SwitchListTile(
              title: const Text('Mark as Featured'),
              subtitle: const Text('Featured videos appear at the top'),
              value: _isFeatured,
              onChanged: _uploading
                  ? null
                  : (value) {
                      setState(() => _isFeatured = value);
                    },
              activeColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Progress
            if (_uploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Upload button
            ElevatedButton.icon(
              onPressed: _uploading ? null : _saveVideo,
              icon:
                  Icon(_uploading ? Icons.hourglass_empty : Icons.cloud_upload),
              label: Text(
                _uploading
                    ? 'Uploading...'
                    : isEditing
                        ? 'Update Video'
                        : 'Upload Video',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Video Guidelines',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Maximum file size: 100MB\n'
                    '• Maximum duration: 10 minutes\n'
                    '• Supported formats: MP4, MOV\n'
                    '• Add a clear thumbnail for better engagement\n'
                    '• Write descriptive titles and descriptions',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
