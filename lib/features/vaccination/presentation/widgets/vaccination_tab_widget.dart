import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/vaccine_schedule.dart';
import '../providers/vaccination_provider.dart';
import '../pages/vaccination_schedule_page.dart';
import '../pages/droppings_report_screen.dart';
import '../widgets/vaccine_schedule_card.dart';

class VaccinationTabWidget extends StatefulWidget {
  final String batchId;
  final String batchName;
  final DateTime? batchStartDate;

  const VaccinationTabWidget({
    required this.batchId,
    required this.batchName,
    this.batchStartDate,
  });

  @override
  State<VaccinationTabWidget> createState() => _VaccinationTabWidgetState();
}

class _VaccinationTabWidgetState extends State<VaccinationTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VaccinationProvider>();
      provider.loadSchedules(widget.batchId).then((_) {
        if (provider.schedules.isEmpty) {
          provider.loadDefaultSchedules();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VaccinationProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vaccination Schedule',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${provider.schedules.length} vaccines scheduled',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VaccinationSchedulePage(
                            batchId: widget.batchId,
                            batchName: widget.batchName,
                            batchStartDate: widget.batchStartDate,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View All'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DroppingsReportScreen(
                          batchId: widget.batchId,
                          batchName: widget.batchName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Report Droppings to Vet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            if (provider.schedules.isEmpty)
             const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.vaccines,
                      size: 48,
                      color: Colors.grey,
                    ),
                     SizedBox(height: 8),
                     Text('Loading schedule...'),
                  ],
                ),
              )
            else
              Expanded(
                child: Builder(
                  builder: (context) {
                    // Calculate current day once
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sortedSchedules.length > 3
                          ? 3
                          : sortedSchedules.length,
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
                ),
              ),
            if (provider.schedules.length > 3)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '+${provider.schedules.length - 3} more vaccines',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

