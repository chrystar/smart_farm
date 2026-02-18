import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/vaccine_schedule.dart';
import '../providers/vaccination_provider.dart';
import '../widgets/vaccine_schedule_card.dart';

class VaccinationSchedulePage extends StatefulWidget {
  final String batchId;
  final String batchName;
  final DateTime? batchStartDate;

  const VaccinationSchedulePage({
    required this.batchId,
    required this.batchName,
    this.batchStartDate,
  });

  @override
  State<VaccinationSchedulePage> createState() => _VaccinationSchedulePageState();
}

class _VaccinationSchedulePageState extends State<VaccinationSchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VaccinationProvider>();
      provider.loadSchedules(widget.batchId).then((_) {
        // If no schedules found, load default schedule
        if (provider.schedules.isEmpty) {
          provider.loadDefaultSchedules();
        }
      });
      provider.loadVaccinationLogs(widget.batchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vaccination Schedule - ${widget.batchName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Schedule'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return Consumer<VaccinationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }

        if (provider.schedules.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vaccines, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No vaccination schedule yet'),
              ],
            ),
          );
        }

        // Calculate current batch day
        final currentDay = widget.batchStartDate != null
            ? DateTime.now().difference(widget.batchStartDate!).inDays + 1
            : null;

        // Sort schedules: upcoming/in-progress first, then past
        final sortedSchedules = List<VaccineSchedule>.from(provider.schedules);
        if (currentDay != null) {
          sortedSchedules.sort((a, b) {
            // Calculate end day using duration field
            int getEndDay(VaccineSchedule schedule) {
              return schedule.ageInDays + schedule.durationDays - 1;
            }
            
            final aEndDay = getEndDay(a);
            final bEndDay = getEndDay(b);
            final aIsPast = currentDay > aEndDay;
            final bIsPast = currentDay > bEndDay;
            
            if (aIsPast != bIsPast) {
              return aIsPast ? 1 : -1; // Past items go to bottom
            }
            return a.ageInDays.compareTo(b.ageInDays); // Otherwise sort by day
          });
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedSchedules.length,
          itemBuilder: (context, index) {
            final schedule = sortedSchedules[index];
            return VaccineScheduleCard(
              schedule: schedule,
              batchStartDate: widget.batchStartDate,
              currentBatchDay: currentDay,
            );
          },
        );
      },
    );
  }

  Widget _buildLogsTab() {
    return Consumer<VaccinationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checklist, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No vaccination logs yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.logs.length,
          itemBuilder: (context, index) {
            final log = provider.logs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(log.vaccineName),
                subtitle: Text(
                  'Administered: ${DateFormat('MMM dd, yyyy').format(log.administeredDate)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => provider.deleteVaccinationLog(log.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
