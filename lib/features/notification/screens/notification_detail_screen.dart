
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String responseId;
  final String notificationId;

  const NotificationDetailScreen({
    Key? key,
    required this.responseId,
    required this.notificationId,
  }) : super(key: key);

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _response;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResponse();
    _markNotificationAsRead();
  }

  Future<void> _markNotificationAsRead() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', widget.notificationId);
    } catch (e) {
      // Silent fail - not critical
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  Future<void> _loadResponse() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      debugPrint('Current user ID: ${currentUser.id}');
      debugPrint('Loading response with ID: ${widget.responseId}');

      // Fetch notification to verify ownership
      final notification = await _supabase
          .from('notifications')
          .select()
          .eq('id', widget.notificationId)
          .maybeSingle();
      
      debugPrint('Notification: $notification');

      // Verify the notification belongs to the current user
      if (notification == null || notification['user_id'] != currentUser.id) {
        setState(() {
          _error = 'You do not have permission to view this response.';
          _isLoading = false;
        });
        return;
      }

      // Fetch the response (RLS policy should allow this)
      final response = await _supabase
          .from('droppings_reports_responses')
          .select()
          .eq('id', widget.responseId)
          .maybeSingle();

      debugPrint('Response: $response');

      if (response == null) {
        debugPrint('Response not found - checking if it exists in database');
        setState(() {
          _error = 'Response not found. Make sure your Supabase RLS policy for droppings_reports_responses is correctly configured.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet Response'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load response',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _loadResponse();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _response == null
                  ? const Center(child: Text('Response not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child:  Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.medical_services,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Veterinary Response',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM d, yyyy • HH:mm').format(
                                            DateTime.parse(_response!['created_at']).toLocal(),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title
                          _buildSectionTitle('Diagnosis'),
                          const SizedBox(height: 8),
                          _buildContentCard(
                            _response!['title'],
                            Icons.title,
                            Colors.blue,
                          ),
                          const SizedBox(height: 20),

                          // Description
                          _buildSectionTitle('Detailed Description'),
                          const SizedBox(height: 8),
                          _buildContentCard(
                            _response!['description'],
                            Icons.description,
                            Colors.purple,
                          ),
                          const SizedBox(height: 20),

                          // Cause
                          _buildSectionTitle('Likely Cause'),
                          const SizedBox(height: 8),
                          _buildContentCard(
                            _response!['cause'],
                            Icons.warning_amber,
                            Colors.orange,
                          ),
                          const SizedBox(height: 20),

                          // Medications
                          _buildSectionTitle('Recommended Medications'),
                          const SizedBox(height: 8),
                          _buildContentCard(
                            _response!['medications'],
                            Icons.medication,
                            Colors.red,
                          ),
                          const SizedBox(height: 20),

                          // Medication Image (if available)
                          if (_response!['medication_image_url'] != null) ...[
                            _buildSectionTitle('Medication Image'),
                            const SizedBox(height: 8),
                            Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  // Show full-screen image
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        backgroundColor: Colors.black,
                                        appBar: AppBar(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          title: const Text('Medication Image'),
                                        ),
                                        body: Center(
                                          child: InteractiveViewer(
                                            child: Image.network(
                                              _response!['medication_image_url'],
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Image.network(
                                      _response!['medication_image_url'],
                                      height: 250,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 250,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                              SizedBox(height: 8),
                                              Text('Failed to load image'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      color: Colors.grey[100],
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.zoom_in, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            'Tap to view full size',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContentCard(String content, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
