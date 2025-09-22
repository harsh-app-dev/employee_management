import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/util.dart';
import '../../data/models/punch/response/attendence_response.dart';

class AttendanceDetailSheet extends StatelessWidget {
  final List<Attendance> attendanceDetails;
  final String punchIn;
  final String punchOut;
  final ScrollController scrollController;

  const AttendanceDetailSheet({
    super.key,
    required this.attendanceDetails,
    required this.punchIn,
    required this.punchOut,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (attendanceDetails.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('No punch logs available')),
      );
    }

    final allWorkLogs = _getAllWorkLogsSorted(attendanceDetails);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ListView(
        controller: scrollController,
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(8),),
            ),
          ),
          Row(
            children: [
              Icon(Icons.access_time, color: theme.colorScheme.primary, size: 28),
              SizedBox(width: 8),
              Text(
                'Punch Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.primary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          Divider(height: 24, thickness: 1.3, color: theme.colorScheme.primary.withValues(alpha: 0.15),),

          if (allWorkLogs.isNotEmpty) ...[
            _buildCompleteTimeline(allWorkLogs, attendanceDetails.first.attendanceDate),
            SizedBox(height: 5),
          ],

          Divider(height: 28, thickness: 1.3, color: theme.colorScheme.primary.withValues(alpha: 0.15),),

          Row(
            children: [
              Icon(Icons.timer, color: theme.colorScheme.primary, size: 18),

              SizedBox(width: 1),
              Text('Worked Hrs: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
              Text(_calculateTotalWorkHours(attendanceDetails), style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),),

              SizedBox(width: 10),
              Icon(Icons.pause_circle_filled, color: Colors.orange, size: 18),

              SizedBox(width: 1),
              Text('Break Hrs: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
              Text(_calculateTotalBreakHours(attendanceDetails), style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),),
            ],
          ),
        ],
      ),
    );
  }

  // Extract all work logs from all attendance objects and sort them by time
  List<WorkLog> _getAllWorkLogsSorted(List<Attendance> attendances) {
    List<WorkLog> allWorkLogs = [];
    for (var attendance in attendances) {
      if (attendance.workLogs != null && attendance.workLogs!.isNotEmpty) {
        allWorkLogs.addAll(attendance.workLogs!);
      }
    }
    // Sort logs by time (latest first)
    allWorkLogs.sort((a, b) {
      try {
        final timeA = _parseTime(a.time ?? '');
        final timeB = _parseTime(b.time ?? '');
        return timeB.compareTo(timeA); // descending
      } catch (e) {
        return 0;
      }
    });

    return allWorkLogs;
  }

  String _calculateTotalWorkHours(List<Attendance> attendances) {
    return attendances.isNotEmpty ? attendances.first.totalWorkHour ?? '--' : '--';
  }

  String _calculateTotalBreakHours(List<Attendance> attendances) {
    return attendances.isNotEmpty ? attendances.first.totalBreakHour ?? '--' : '--';
  }

  Widget _buildCompleteTimeline(List<WorkLog> workLogs, String? parentDate) {
    final scrollController = ScrollController();
    return SizedBox(
      height: 300,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        radius: const Radius.circular(8),
        thickness: 6,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Stack(
            children: [
              if (workLogs.isNotEmpty)
                Positioned(left: 10, top: 20, bottom: 20, child: Container(width: 2, color: Colors.grey.shade300),),
              Column(
                children: workLogs.map((log) {
                  final isLast = workLogs.last == log;
                  return Container(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: getColorForType(log.type), border: Border.all(color: Colors.white, width: 3),),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getLabelForType(log.type),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.time != null ? _formatTime(log.time!, parentDate) : '--:--',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600,),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseTime(String time) {
    try {
      return DateFormat('HH:mm:ss').parse(time);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatTime(String time, String? date) {
    try {
      if (date != null) {
        final dateTimeStr = '${date.split(' ')[0]} $time';
        final dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTimeStr);
        return DateFormat('hh:mm a').format(dateTime);
      } else {
        final timeOnly = DateFormat('HH:mm:ss').parse(time);
        return DateFormat('hh:mm a').format(timeOnly);
      }
    } catch (e) {
      return time;
    }
  }
}
