import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:smart_farm/features/subscription/subscription_provider.dart';
import 'package:smart_farm/features/subscription/subscription_screen.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../provider/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay? _alarmTime;

  Future<void> _showUpgradeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text('Upgrade to Premium to export your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            child: const Text('View plans'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final preferences = context.read<SettingsProvider>().preferences;
    if (preferences != null && preferences.vaccinationAlarmTime != null) {
      _alarmTime = preferences.vaccinationAlarmTime;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      final userId = SupabaseService().currentUserId;
      if (userId != null) {
        settingsProvider.loadPreferences(userId);
      }
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        context.go('/get-started');
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _exportData() async {
    final userId = SupabaseService().currentUserId;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to export data')),
      );
      return;
    }

    try {
      final client = Supabase.instance.client;

      // Fetch all data
      final batches =
          await client.from('batches').select().eq('user_id', userId);

      final batchIds = (batches as List).map((b) => b['id'] as String).toList();

      final dailyRecords = batchIds.isEmpty
          ? <dynamic>[]
          : await client
              .from('daily_records')
              .select()
              .inFilter('batch_id', batchIds);

      final expenses =
          await client.from('expenses').select().eq('user_id', userId);

      final sales = await client.from('sales').select().eq('user_id', userId);

      // Create PDF
      final pdf = pw.Document();
      final dateFormat = DateFormat('MMM dd, yyyy');
      final currencyFormat = NumberFormat.currency(symbol: '\$');

      // Add title page
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Smart Farm Data Export',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Exported: ${dateFormat.format(DateTime.now())}'),
              pw.SizedBox(height: 20),
              pw.Divider(),
            ],
          ),
        ),
      );

      // Add Batches section
      if (batches.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Batches (${batches.length})',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: [
                    'Name',
                    'Bird Type',
                    'Quantity',
                    'Start Date',
                    'Status'
                  ],
                  data: batches
                      .map((b) => [
                            b['name'] ?? 'N/A',
                            b['bird_type'] ?? 'N/A',
                            '${b['actual_quantity'] ?? b['expected_quantity'] ?? 0}',
                            b['start_date'] != null
                                ? dateFormat
                                    .format(DateTime.parse(b['start_date']))
                                : 'N/A',
                            b['status'] ?? 'N/A',
                          ])
                      .toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
            ),
          ),
        );
      }

      // Add Daily Records section
      if (dailyRecords.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Daily Records (${dailyRecords.length})',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Feed (kg)', 'Mortality', 'Notes'],
                  data: dailyRecords
                      .take(50)
                      .map((r) => [
                            r['date'] != null
                                ? dateFormat.format(DateTime.parse(r['date']))
                                : 'N/A',
                            '${r['feed_consumed'] ?? 0}',
                            '${r['mortality'] ?? 0}',
                            (r['notes'] ?? '').toString().substring(
                                0,
                                (r['notes'] ?? '').toString().length > 30
                                    ? 30
                                    : (r['notes'] ?? '').toString().length),
                          ])
                      .toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                if (dailyRecords.length > 50)
                  pw.Text('... and ${dailyRecords.length - 50} more records'),
              ],
            ),
          ),
        );
      }

      // Add Expenses section
      if (expenses.isNotEmpty) {
        final totalExpenses = expenses.fold<double>(
          0,
          (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0),
        );

        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Expenses (${expenses.length})',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Total: ${currencyFormat.format(totalExpenses)}'),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Category', 'Description', 'Amount'],
                  data: expenses
                      .take(50)
                      .map((e) => [
                            e['expense_date'] != null
                                ? dateFormat
                                    .format(DateTime.parse(e['expense_date']))
                                : 'N/A',
                            e['category'] ?? 'N/A',
                            (e['description'] ?? 'N/A').toString().substring(
                                0,
                                (e['description'] ?? 'N/A').toString().length >
                                        30
                                    ? 30
                                    : (e['description'] ?? 'N/A')
                                        .toString()
                                        .length),
                            currencyFormat
                                .format((e['amount'] as num?)?.toDouble() ?? 0),
                          ])
                      .toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                if (expenses.length > 50)
                  pw.Text('... and ${expenses.length - 50} more expenses'),
              ],
            ),
          ),
        );
      }

      // Add Sales section
      if (sales.isNotEmpty) {
        final totalSales = sales.fold<double>(
          0,
          (sum, s) => sum + ((s['total_amount'] as num?)?.toDouble() ?? 0),
        );

        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Sales (${sales.length})',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Total: ${currencyFormat.format(totalSales)}'),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Customer', 'Quantity', 'Amount'],
                  data: sales
                      .take(50)
                      .map((s) => [
                            s['sale_date'] != null
                                ? dateFormat
                                    .format(DateTime.parse(s['sale_date']))
                                : 'N/A',
                            s['customer_name'] ?? 'N/A',
                            '${s['quantity'] ?? 0}',
                            currencyFormat.format(
                                (s['total_amount'] as num?)?.toDouble() ?? 0),
                          ])
                      .toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                if (sales.length > 50)
                  pw.Text('... and ${sales.length - 50} more sales'),
              ],
            ),
          ),
        );
      }

      // Save PDF
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/smart_farm_export_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Smart Farm Data Export',
        text: 'Your Smart Farm data export (PDF) is attached.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _requestAccountDeletion() async {
    final userId = SupabaseService().currentUserId ?? 'unknown';
    final email = context.read<AuthProvider>().user?.email ?? 'unknown';

    final uri = Uri(
      scheme: 'mailto',
      path: 'support@smartfarm.com',
      queryParameters: {
        'subject': 'Account deletion request',
        'body': 'Please delete my account.\nUser ID: $userId\nEmail: $email',
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open email client')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final preferences = provider.preferences;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 30),
                    ),
                    title: const Text(
                      'User Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle:
                        Text(preferences?.farmName ?? 'Tap to edit profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/profile'),
                  ),
                ),

                const SizedBox(height: 24),

                // Preferences Section
                const Text(
                  'Preferences',
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
                        leading: const Icon(Icons.alarm),
                        title: const Text('Vaccination Alarm Time'),
                        subtitle: Text(_alarmTime != null
                            ? 'At ${_alarmTime!.format(context)}'
                            : 'Not set'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _alarmTime ??
                                const TimeOfDay(hour: 6, minute: 0),
                          );
                          if (picked != null) {
                            setState(() {
                              _alarmTime = picked;
                            });
                            // Save to preferences and reschedule alarm
                            final userId = SupabaseService().currentUserId;
                            if (userId != null) {
                              context
                                  .read<SettingsProvider>()
                                  .setVaccinationAlarmTime(picked, userId);
                            }
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.attach_money),
                        title: const Text('Currency'),
                        trailing: DropdownButton<String>(
                          value: ['USD', 'NGN', 'GHS', 'KES', 'ZAR']
                                  .contains(preferences?.defaultCurrency)
                              ? preferences?.defaultCurrency
                              : 'USD',
                          underline: const SizedBox(),
                          items: ['USD', 'NGN', 'GHS', 'KES', 'ZAR']
                              .map((currency) => DropdownMenuItem(
                                    value: currency,
                                    child: Text(currency),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              final userId = SupabaseService().currentUserId;
                              if (userId != null) {
                                provider.updateCurrency(userId, value);
                              }
                            }
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.palette),
                        title: const Text('Theme'),
                        trailing: DropdownButton<String>(
                          value: ['light', 'dark', 'system']
                                  .contains(preferences?.themeMode)
                              ? preferences?.themeMode
                              : 'light',
                          underline: const SizedBox(),
                          items: ['light', 'dark', 'system']
                              .map((theme) => DropdownMenuItem(
                                    value: theme,
                                    child: Text(theme[0].toUpperCase() +
                                        theme.substring(1)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              final userId = SupabaseService().currentUserId;
                              if (userId != null) {
                                provider.updateThemeMode(userId, value);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Notifications Section
                const Text(
                  'Notifications',
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
                        secondary: const Icon(Icons.notifications),
                        title: const Text('Feeding Reminders'),
                        subtitle: Text(
                          '${preferences?.feedingSchedules.length ?? 0} schedules',
                        ),
                        value: preferences?.pushNotifications ?? false,
                        onChanged: (value) {
                          final userId = SupabaseService().currentUserId;
                          if (userId != null) {
                            provider.toggleNotification('push', value, userId);
                          }
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.event),
                        title: const Text('Daily Report Reminders'),
                        subtitle: preferences?.dailyReportReminderTime != null
                            ? Text(
                                'At ${preferences!.dailyReportReminderTime!.hour}:${preferences.dailyReportReminderTime!.minute.toString().padLeft(2, '0')}',
                              )
                            : const Text('Not set'),
                        value: preferences?.dailyReportReminderTime != null,
                        onChanged: (value) {
                          if (value) {
                            // Navigate to notification settings to set time
                            context.push('/settings/notifications');
                          } else {
                            final userId = SupabaseService().currentUserId;
                            if (userId != null) {
                              provider.setDailyReportReminder(null, userId);
                            }
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.tune),
                        title: const Text('Manage Notifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/settings/notifications'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Data & Privacy Section
                const Text(
                  'Data & Privacy',
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
                        leading: const Icon(Icons.file_download),
                        title: const Text('Export Data'),
                        subtitle: const Text('Download your batch data'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final isPremium =
                              context.read<SubscriptionProvider>().isPremium;
                          if (!isPremium) {
                            _showUpgradeDialog();
                            return;
                          }
                          _exportData();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Delete Account'),
                        subtitle: const Text('Permanently delete your account'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _requestAccountDeletion();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // About Section
                const Text(
                  'About',
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
                        leading: const Icon(Icons.info),
                        title: const Text('About App'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/settings/about'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _launchUrl('https://www.smartfarm.com/privacy');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('Terms of Service'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _launchUrl('https://www.smartfarm.com/terms');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
