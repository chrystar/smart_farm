import 'package:flutter/material.dart';
import '../../domain/entities/vaccine_schedule.dart';

class VaccineScheduleCard extends StatelessWidget {
  final VaccineSchedule schedule;
  final DateTime? batchStartDate;
  final int? currentBatchDay;

  const VaccineScheduleCard({
    required this.schedule,
    this.batchStartDate,
    this.currentBatchDay,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate day range using duration field
    final int startDay = schedule.ageInDays;
    final int endDay = schedule.ageInDays + schedule.durationDays - 1;
    
    // Determine status
    final bool isPast = currentBatchDay != null && currentBatchDay! > endDay;
    final bool isToday = currentBatchDay != null && currentBatchDay! == schedule.ageInDays;
    final bool isInProgress = currentBatchDay != null && 
        currentBatchDay! >= startDay && 
        currentBatchDay! <= endDay &&
        !isToday;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isToday)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (isInProgress)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'IN PROGRESS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (isPast)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PAST',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                schedule.vaccineName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          schedule.durationDays > 1
                              ? 'Days $startDay-$endDay (${schedule.durationDays} days)'
                              : 'Day $startDay',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isPast ? Colors.grey[700] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPast 
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getRouteLabel(schedule.route),
                      style: TextStyle(
                        color: isPast ? Colors.grey[700] : Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dosage',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            schedule.dosage,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Type',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _getVaccineTypeLabel(schedule.vaccineType),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (schedule.notes != null) ...[
              const SizedBox(height: 12),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                schedule.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ));
  }

  String _getVaccineTypeLabel(VaccineType type) {
    switch (type) {
      case VaccineType.newcastle:
        return 'Newcastle (ND)';
      case VaccineType.ibd:
        return 'IBD (Gumboro)';
      case VaccineType.fowlPox:
        return 'Fowl Pox';
      case VaccineType.infectiousCoryza:
        return 'Infectious Coryza';
      case VaccineType.fowlTyphoid:
        return 'Fowl Typhoid';
      case VaccineType.coccidiostat:
        return 'Coccidiostat';
      case VaccineType.other:
        return 'Other';
    }
  }

  String _getRouteLabel(VaccineRoute route) {
    switch (route) {
      case VaccineRoute.eyeDrop:
        return 'Eye Drop';
      case VaccineRoute.nasal:
        return 'Nasal';
      case VaccineRoute.oral:
        return 'Oral';
      case VaccineRoute.water:
        return 'Water';
      case VaccineRoute.intramuscular:
        return 'I.M.';
      case VaccineRoute.wingWeb:
        return 'Wing Web';
      case VaccineRoute.other:
        return 'Other';
    }
  }
}
