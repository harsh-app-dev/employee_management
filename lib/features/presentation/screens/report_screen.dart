import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'app_side_drawer.dart';
import 'leave_screen.dart'; // To access _leaveRequests if needed, or you can pass the data in a real app

class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<LeaveRequest> leaveRequests = [];
    try {
    } catch (_) {}
    final theme = Theme.of(context);

    // Demo: Calculate for current month
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    // Working days: Mon-Fri
    int totalWorkingDays = 0;
    for (DateTime d = firstDayOfMonth; !d.isAfter(lastDayOfMonth); d = d.add(Duration(days: 1))) {
      if (d.weekday >= 1 && d.weekday <= 5) totalWorkingDays++;
    }
    // Paid days: working days + approved leaves (count unique leave days in month)
    Set<DateTime> approvedLeaveDays = {};
    for (final leave in leaveRequests.where((l) => l.status == 'Approved')) {
      for (int i = 0; i <= leave.dateRange.duration.inDays; i++) {
        final day = leave.dateRange.start.add(Duration(days: i));
        if (day.month == now.month && day.year == now.year) approvedLeaveDays.add(DateTime(day.year, day.month, day.day));
      }
    }
    int totalAbsent = 1; // Demo value, replace with real calculation if available
    int totalPaidDays = totalWorkingDays - totalAbsent;
    // Leave summary: count by type for current month
    Map<String, int> leaveTypeCounts = {};
    for (final leave in leaveRequests.where((l) => l.status == 'Approved')) {
      if (leave.dateRange.start.month == now.month && leave.dateRange.start.year == now.year) {
        leaveTypeCounts[leave.leaveType] = (leaveTypeCounts[leave.leaveType] ?? 0) + 1;
      }
    }

    void _showPunchDetailSheet(DateTime date) {
      final theme = Theme.of(context);
      // Demo punch sessions for the selected date
      final punchSessions = [
        {'in': '09:00 AM', 'out': '11:30 AM', 'worked': '2h 30m'},
        {'in': '12:00 PM', 'out': '02:00 PM', 'worked': '2h 0m'},
        {'in': '02:30 PM', 'out': '06:00 PM', 'worked': '3h 30m'},
      ];
      final totalMinutes = [150, 120, 210].reduce((a, b) => a + b);
      final totalHours = totalMinutes ~/ 60;
      final totalMins = totalMinutes % 60;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 8),
                      const Text('Punch Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.colorScheme.primary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Divider(height: 24, thickness: 1.3, color: theme.colorScheme.primary.withOpacity(0.15)),
                  ...punchSessions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final punch = entry.value;
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.login, color: Colors.green, size: 22),
                              const SizedBox(width: 8),
                              Text('In: ${punch['in']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Icon(Icons.logout, color: Colors.red, size: 22),
                              const SizedBox(width: 8),
                              Text('Out: ${punch['out']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              Icon(Icons.timer, color: theme.colorScheme.primary, size: 18),
                              const SizedBox(width: 6),
                              const Text('Worked: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(punch['worked']!, style: TextStyle(fontSize: 14, color: theme.colorScheme.primary)),
                            ],
                          ),
                        ),
                        if (idx < punchSessions.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('— Break —', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                ),
                                const Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
                              ],
                            ),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, color: theme.colorScheme.primary, size: 22),
                          const SizedBox(width: 8),
                          const Text('Total Worked: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('$totalHours hrs $totalMins mins', style: TextStyle(fontSize: 16, color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        drawer: AppSideDrawer(),
        appBar: AppBar(
          title: const Text('Report', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Summary Section ---
              Card(
                margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4, top: 4),
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary.withOpacity(0.13), theme.colorScheme.primary.withOpacity(0.07)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatBlock(Icons.calendar_today, 'Working', totalWorkingDays, Colors.blue),
                          _buildStatBlock(Icons.check_circle, 'Present', 20, Colors.green),
                          _buildStatBlock(Icons.cancel, 'Absent', 1, Colors.red),
                          _buildStatBlock(Icons.monetization_on, 'Paid', totalPaidDays, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Leave Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: theme.colorScheme.primary)),
                      const SizedBox(height: 10),
                      leaveTypeCounts.isEmpty
                          ? Text('No leaves taken this month.', style: TextStyle(color: Colors.grey[700], fontSize: 15))
                          : Wrap(
                              spacing: 14,
                              runSpacing: 8,
                              children: leaveTypeCounts.entries
                                  .map((e) => Chip(
                                        label: Text('${e.key}: ${e.value}', style: TextStyle(fontWeight: FontWeight.w600)),
                                        backgroundColor: theme.colorScheme.primary.withOpacity(0.13),
                                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                                      ))
                                  .toList(),
                            ),
                    ],
                  ),
                ),
              ),
              // --- Calendar ---
              Expanded(
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: DateTime.now(),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                  onDaySelected: (selectedDay, focusedDay) {
                    _showPunchDetailSheet(selectedDay);
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final now = DateTime.now();
                      final isPast = !day.isAfter(DateTime(now.year, now.month, now.day));
                      if (!isPast) return null; // Only color past and today

                      // Demo: Mark weekends as incomplete (red), others as present (green)
                      bool isIncomplete = day.weekday == 6 || day.weekday == 7; // Sat/Sun
                      Color bgColor = isIncomplete
                          ? const Color(0xFFFF4D4F).withOpacity(0.18) // Vibrant red
                          : const Color(0xFF4CAF50).withOpacity(0.18); // Vibrant green

                      // Add a subtle border/shadow for today
                      bool isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                      BoxDecoration decoration = BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        boxShadow: isToday
                            ? [BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1)]
                            : [],
                        border: isToday
                            ? Border.all(color: const Color(0xFF388E3C), width: 2)
                            : null,
                      );

                      return Container(
                        decoration: decoration,
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isIncomplete ? const Color(0xFFD32F2F) : const Color(0xFF1B5E20),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget _buildStatBlock(IconData icon, String label, int value, Color color) {
  return Container(
    width: 70,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, spreadRadius: 1)],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    ),
  );
} 