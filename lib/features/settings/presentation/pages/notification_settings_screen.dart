import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/user_preferences.dart';
import '../provider/settings_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _addFeedingSchedule(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    final userId = SupabaseService().currentUserId;
    if (userId == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _FeedingScheduleDialog(),
    );

    if (result != null && context.mounted) {
      final schedule = FeedingSchedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['label'] as String,
        time: result['time'] as TimeOfDay,
        enabled: true,
      );
      await settingsProvider.addFeedingSchedule(schedule, userId);
    }
  }

  Future<void> _editFeedingSchedule(
    BuildContext context,
    FeedingSchedule schedule,
  ) async {
    final settingsProvider = context.read<SettingsProvider>();
    final userId = SupabaseService().currentUserId;
    if (userId == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _FeedingScheduleDialog(
        initialTime: schedule.time,
        initialLabel: schedule.name,
      ),
    );

    if (result != null && context.mounted) {
      // Remove old and add updated schedule
      await settingsProvider.removeFeedingSchedule(schedule.id, userId);
      final updatedSchedule = FeedingSchedule(
        id: schedule.id,
        name: result['label'] as String,
        time: result['time'] as TimeOfDay,
        enabled: schedule.enabled,
      );
      await settingsProvider.addFeedingSchedule(updatedSchedule, userId);
    }
  }

  Future<void> _setDailyReportTime(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    final userId = SupabaseService().currentUserId;
    if (userId == null) return;

    final currentTime = settingsProvider.preferences?.dailyReportReminderTime ??
        const TimeOfDay(hour: 18, minute: 0);

    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
      helpText: 'Select Daily Report Reminder Time',
    );

    if (time != null && context.mounted) {
      await settingsProvider.setDailyReportReminder(time, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          final preferences = provider.preferences;
          if (preferences == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Master Notification Toggle
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.notifications_active),
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Master switch for all notifications'),
                    value: preferences.pushNotifications,
                    onChanged: (value) {
                      final userId = SupabaseService().currentUserId;
                      if (userId != null) {
                        provider.toggleNotification('push', value, userId);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Feeding Schedules Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Feeding Schedules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addFeedingSchedule(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (preferences.feedingSchedules.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No feeding schedules',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap Add to create a feeding reminder',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...preferences.feedingSchedules.asMap().entries.map((entry) {
                    final schedule = entry.value;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.restaurant,
                          color: schedule.enabled
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        title: Text(
                          schedule.name,
                          style: TextStyle(
                            color: schedule.enabled ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          '${schedule.time.hour}:${schedule.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: schedule.enabled ? null : Colors.grey,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: schedule.enabled,
                              onChanged: (value) {
                                final userId = SupabaseService().currentUserId;
                                if (userId != null) {
                                  provider.toggleFeedingSchedule(schedule.id, value, userId);
                                }
                              },
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) async {
                                final userId = SupabaseService().currentUserId;
                                if (userId == null) return;

                                if (value == 'edit') {
                                  _editFeedingSchedule(context, schedule);
                                } else if (value == 'delete') {
                                  await provider.removeFeedingSchedule(schedule.id, userId);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // Daily Report Reminder
                const Text(
                  'Daily Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.event_note),
                        title: const Text('Daily Report Reminder'),
                        subtitle: preferences.dailyReportReminderTime != null
                            ? Text(
                                'At ${preferences.dailyReportReminderTime!.hour}:${preferences.dailyReportReminderTime!.minute.toString().padLeft(2, '0')}',
                              )
                            : const Text('Not set'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (preferences.dailyReportReminderTime != null)
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  final userId = SupabaseService().currentUserId;
                                  if (userId != null) {
                                    provider.setDailyReportReminder(null, userId);
                                  }
                                },
                              ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => _setDailyReportTime(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Alert Notifications
                const Text(
                  'Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.warning),
                        title: const Text('High Mortality Alert'),
                        subtitle: const Text('Get notified when mortality exceeds threshold'),
                        value: preferences.highMortalityAlerts,
                        onChanged: (value) {
                          final userId = SupabaseService().currentUserId;
                          if (userId != null) {
                            provider.toggleNotification('highMortality', value, userId);
                          }
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.event_busy),
                        title: const Text('Missing Record Alert'),
                        subtitle: const Text('Remind when daily record is missing'),
                        value: preferences.missingRecordAlerts,
                        onChanged: (value) {
                          final userId = SupabaseService().currentUserId;
                          if (userId != null) {
                            provider.toggleNotification('missingRecord', value, userId);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Info Card
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Notifications require permission. Make sure notifications are enabled in your device settings.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Test Notifications
                const Text(
                  'Test Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await NotificationService().showTestNotification();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test notification sent! Check your notification tray.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('Send Test Notification Now'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await NotificationService().scheduleTestNotification();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test notification scheduled for 10 seconds from now!'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: const Text('Schedule Test (10 seconds)'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            await NotificationService().debugPendingNotifications();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Check console for pending notifications.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.list),
                          label: const Text('List Pending Notifications'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeedingScheduleDialog extends StatefulWidget {
  final TimeOfDay? initialTime;
  final String? initialLabel;

  const _FeedingScheduleDialog({
    this.initialTime,
    this.initialLabel,
  });

  @override
  State<_FeedingScheduleDialog> createState() => _FeedingScheduleDialogState();
}

class _FeedingScheduleDialogState extends State<_FeedingScheduleDialog> {
  late TimeOfDay _selectedTime;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime ?? const TimeOfDay(hour: 8, minute: 0);
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTime == null ? 'Add Feeding Schedule' : 'Edit Feeding Schedule'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'e.g., Morning Feed',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectTime,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              child: Text(
                '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_labelController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a label')),
              );
              return;
            }

            Navigator.pop(context, {
              'time': _selectedTime,
              'label': _labelController.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
