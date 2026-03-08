import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'video_upload_screen.dart';

class MyVideosScreen extends StatefulWidget {
  const MyVideosScreen({Key? key}) : super(key: key);

  @override
  State<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends State<MyVideosScreen> {
  List<Map<String, dynamic>> _videos = [];
  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadMyVideos();
  }

  Future<void> _loadMyVideos() async {
    if (_currentUserId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('creator_videos')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _videos = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading videos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo(String videoId) async {
    try {
      await Supabase.instance.client
          .from('creator_videos')
          .delete()
          .eq('id', videoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video deleted successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadMyVideos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(String videoId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVideo(videoId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToUpload({Map<String, dynamic>? video}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoUploadScreen(video: video),
      ),
    );

    if (result == true) {
      _loadMyVideos();
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Videos'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No videos yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your first video to share\nknowledge with other farmers',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToUpload(),
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyVideos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      final createdAt = DateTime.tryParse(
                        video['created_at']?.toString() ?? '',
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: video['thumbnail_url'] != null
                                      ? Image.network(
                                          video['thumbnail_url'],
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 180,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.video_library,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          height: 180,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(
                                              Icons.video_library,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                ),
                                // Play button overlay
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black26,
                                    child: const Icon(
                                      Icons.play_circle_outline,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Duration badge
                                if (video['duration_seconds'] != null)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _formatDuration(
                                            video['duration_seconds']),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category badge & Featured badge
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          video['category'] ?? 'General',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (video['featured'] == true) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.orange.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 12,
                                                color: Colors.orange,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Featured',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Title
                                  Text(
                                    video['title'] ?? 'Untitled',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (video['description'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      video['description'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 12),

                                  // Stats & Actions
                                  Row(
                                    children: [
                                      Icon(Icons.visibility,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${video['views'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.favorite,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${video['likes'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.storage,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatFileSize(
                                            video['file_size_bytes']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (createdAt != null)
                                        Text(
                                          _formatDate(createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      const Spacer(),
                                      // Edit button
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        color: AppColors.primaryGreen,
                                        onPressed: () => _navigateToUpload(
                                          video: video,
                                        ),
                                      ),
                                      // Delete button
                                      IconButton(
                                        icon:
                                            const Icon(Icons.delete, size: 20),
                                        color: Colors.red,
                                        onPressed: () =>
                                            _showDeleteConfirmation(
                                          video['id'],
                                          video['title'] ?? 'this video',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _videos.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _navigateToUpload(),
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.upload),
              label: const Text('Upload Video'),
            ),
    );
  }
}
