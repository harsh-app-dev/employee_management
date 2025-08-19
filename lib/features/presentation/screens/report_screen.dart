import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/leave/leave_response.dart';
import '../../../core/widgets/app_side_drawer.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<LeaveResponse>
    leaveRequests = [
      LeaveResponse(
        id: "1",
        dateRange: DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 2)),
          end: DateTime.now().subtract(const Duration(days: 1)),
        ),
        leaveType: "Sick Leave",
        reason: "Fever",
        hr: "HR1",
        teamLead: "Lead1",
        status: "Approved",
        appliedDate: DateTime.now().subtract(const Duration(days: 3)),
        totalDays: 2,
        isNewlyApplied: false,
        leaveTypeName: "Sick Leave",
      ),
    ];
    try {
    } catch (_) {}
    final theme = Theme.of(context);

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    int totalWorkingDays = 0;
    for (DateTime d = firstDayOfMonth; !d.isAfter(lastDayOfMonth); d = d.add(Duration(days: 1))) {
      if (d.weekday >= 1 && d.weekday <= 5) totalWorkingDays++;
    }

    Set<DateTime> approvedLeaveDays = {};
    for (final leave in leaveRequests.where((l) => l.status == 'Approved')) {
      for (int i = 0; i <= leave.dateRange.duration.inDays; i++) {
        final day = leave.dateRange.start.add(Duration(days: i));
        if (day.month == now.month && day.year == now.year) approvedLeaveDays.add(DateTime(day.year, day.month, day.day));
      }
    }
    int totalAbsent = 1;
    int totalPaidDays = totalWorkingDays - totalAbsent;

    Map<String, int> leaveTypeCounts = {};
    for (final leave in leaveRequests.where((l) => l.status == 'Approved')) {
      if (leave.dateRange.start.month == now.month && leave.dateRange.start.year == now.year) {
        leaveTypeCounts[leave.leaveType] = (leaveTypeCounts[leave.leaveType] ?? 0) + 1;
      }
    }


    void _showPunchDetailSheet(DateTime date) {
      final theme = Theme.of(context);

      final punchSessions = [
        {'in': '09:00 AM', 'out': '11:30 AM', 'worked': '2h 30m'},
        {'in': '12:00 PM', 'out': '02:00 PM', 'worked': '2h 0m'},
        {'in': '02:30 PM', 'out': '06:00 PM', 'worked': '3h 30m'},
      ];
      final totalMinutes = [150, 120, 210].reduce((a, b) => a + b);
      final totalHours = totalMinutes ~/ 60;
      final totalMins = totalMinutes % 60;

      final formattedDate = DateFormat('EEEE, d MMM yyyy').format(date);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Handle bar
                  Container(
                    width: 50,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  // Date & Close button
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Divider(color: Colors.grey[300], thickness: 1.2, height: 20),

                  const SizedBox(height: 10),

                  // Punch Sessions List
                  ...punchSessions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final punch = entry.value;
                    return Column(
                      children: [
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.login, color: Colors.green[700], size: 22),
                                    const SizedBox(width: 6),
                                    Text('In: ${punch['in']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    const Spacer(),
                                    Icon(Icons.logout, color: Colors.red[700], size: 22),
                                    const SizedBox(width: 6),
                                    Text('Out: ${punch['out']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.timer, color: theme.colorScheme.primary, size: 18),
                                    const SizedBox(width: 6),
                                    Text("Worked: ${punch['worked']}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.primary,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Break separator
                        if (idx < punchSessions.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300], thickness: 1, endIndent: 8)),
                                const Text("Break", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                Expanded(child: Divider(color: Colors.grey[300], thickness: 1, indent: 8)),
                              ],
                            ),
                          ),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // Total Worked
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, color: theme.colorScheme.primary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          "Total Worked: $totalHours hrs $totalMins mins",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // --- Sandwich Relief Section ---
    final DateTime sandwichStart = DateTime(DateTime.now().year, 7, 1);
    final DateTime nowDate = DateTime.now();
    final int sandwichDaysElapsed = nowDate.difference(sandwichStart).inDays;
    final int sandwichDaysRemaining = 60 - sandwichDaysElapsed;
    final bool sandwichEligible = sandwichDaysElapsed >= 60;

    return DefaultTabController(
      length: 2,
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary.withOpacity(0.85), theme.colorScheme.secondary.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text('60-Day Sandwich Relief', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!sandwichEligible)
                          Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(
                                      value: (60 - (sandwichDaysRemaining > 0 ? sandwichDaysRemaining : 0)) / 60,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.white24,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '${sandwichDaysRemaining > 0 ? sandwichDaysRemaining : 0}',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Days remaining for sandwich relief', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Icon(Icons.celebration, color: Colors.amberAccent, size: 32),
                              const SizedBox(height: 6),
                              Text('Congratulations!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amberAccent)),
                              const SizedBox(height: 4),
                              Text('You are eligible for a sandwich relief! No leave taken in the last 60 days since July 1.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

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
                      const SizedBox(height: 10),
                      Text('Leave Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: theme.colorScheme.primary)),
                      const SizedBox(height: 4),
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

              SizedBox(
                height: 400,
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365 * 5)),
                  lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
                  focusedDay: DateTime.now(),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.green[700],
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue[800],
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(color: Colors.red[800]),
                    defaultTextStyle: TextStyle(color: Colors.grey[900]),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    _showPunchDetailSheet(selectedDay);
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final now = DateTime.now();
                      final isPast = !day.isAfter(DateTime(now.year, now.month, now.day));
                      if (!isPast) return null;

                      bool isIncomplete = day.weekday == 6 || day.weekday == 7;
                      Color bgColor = isIncomplete
                          ? const Color(0xFFFF4D4F).withOpacity(0.30)
                          : const Color(0xFF4CAF50).withOpacity(0.30);

                      bool isToday = day.year == now.year && day.month == now.month && day.day == now.day;

                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bgColor,
                          border: isToday
                              ? Border.all(
                            color: const Color(0xFF388E3C),
                            width: 2.5,
                          )
                              : null,
                        ),
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
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}


// floating action button for manual punch in and out

/* floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_isFabExpanded) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0 + 10.0, right: 20.0),
              child: FloatingActionButton(
                heroTag: 'manualPunchIn',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ManualPunchInDialog(
                      onSubmit: (dateTime, reason) {
                        // TODO: Handle the submitted values here
                        print('Manual Punch In: dateTime="+dateTime.toString()+", reason=$reason');
                      },
                    ),
                  );
                  setState(() => _isFabExpanded = false);
                },
                child: Icon(Icons.fingerprint),
                tooltip: 'Manual Punch In',
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0, right: 20.0),
            child: FloatingActionButton(
              onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
              child: Icon(_isFabExpanded ? Icons.close : Icons.add),
              tooltip: 'Expand',
            ),
          ),
        ],
      ),*/