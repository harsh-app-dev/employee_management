import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/leave/leave_response.dart';
import '../../../core/widgets/app_side_drawer.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  // Helper functions for calendar indicators (moved outside build method)
  bool _isLeaveDay(DateTime day, Set<DateTime> approvedLeaveDays) {
    return approvedLeaveDays.any((leaveDay) =>
    leaveDay.day == day.day && leaveDay.month == day.month && leaveDay.year == day.year);
  }

  bool _isAbsentDay(DateTime day, List<DateTime> absentDays) {
    return absentDays.any((absentDay) =>
    absentDay.day == day.day && absentDay.month == day.month && absentDay.year == day.year);
  }

  bool _isHoliday(DateTime day, List<DateTime> holidayDays) {
    return holidayDays.any((holiday) =>
    holiday.day == day.day && holiday.month == day.month && holiday.year == day.year);
  }

  bool _isWeekend(DateTime day) {
    return day.weekday == 6 || day.weekday == 7;
  }

  @override
  Widget build(BuildContext context) {
    final List<LeaveResponse> leaveRequests = [
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
      LeaveResponse(
        id: "2",
        dateRange: DateTimeRange(
          start: DateTime.now().add(const Duration(days: 5)),
          end: DateTime.now().add(const Duration(days: 7)),
        ),
        leaveType: "Casual Leave",
        reason: "Family function",
        hr: "HR1",
        teamLead: "Lead1",
        status: "Approved",
        appliedDate: DateTime.now().subtract(const Duration(days: 1)),
        totalDays: 3,
        isNewlyApplied: false,
        leaveTypeName: "Casual Leave",
      ),
    ];

    // Dummy data for calendar indicators
    final List<DateTime> absentDays = [
      DateTime.now().subtract(const Duration(days: 3)),
    ];

    final List<DateTime> holidayDays = [
      DateTime(DateTime.now().year, DateTime.now().month, 25), // 25th of current month
      DateTime(DateTime.now().year, DateTime.now().month + 1, 1), // 1st of next month
    ];

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
    int totalAbsent = absentDays.where((day) => day.month == now.month && day.year == now.year).length;
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

                        // Break separator with pierced effect
                        if (idx < punchSessions.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // The continuous line
                                Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                    height: 20
                                ),
                                // The "break" indicator that appears to pierce through the line
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white, // This creates the "pierced" effect
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "Break",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
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
    final DateTime sandwichStart = DateTime(DateTime.now().year, 9, 1);
    final DateTime nowDate = DateTime.now();
    final int sandwichDaysElapsed = nowDate.difference(sandwichStart).inDays;
    final int sandwichDaysRemaining = 60 - sandwichDaysElapsed;
    final bool sandwichEligible = sandwichDaysElapsed >= 60;

    final List<Map<String, dynamic>> upcomingLeavesAndHolidays = [
      {
        "date": DateTime(2025, 10, 29),
        "type": "Applied Leave",
        "label": "Diwali Vacation",
        "icon": Icons.beach_access,
        "color": Colors.blue[700],
      },
      {
        "date": DateTime(2026, 1, 26),
        "type": "National Holiday",
        "label": "Republic Day",
        "icon": Icons.flag,
        "color": Colors.deepOrange[700],
      },
      {
        "date": DateTime(2025, 11, 10),
        "type": "Planned Leave",
        "label": "Goa Trip",
        "icon": Icons.beach_access,
        "color": Colors.blue[500],
      },
    ];

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
                      // Stat cards row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatBlock(Icons.calendar_today, 'Working', totalWorkingDays, Colors.blue),
                          _buildStatBlock(Icons.check_circle, 'Present', 19, Colors.green),
                          _buildStatBlock(Icons.cancel, 'Absent', totalAbsent, Colors.red),
                          _buildStatBlock(Icons.monetization_on, 'Paid', totalPaidDays, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Expandable Upcoming Leaves & Holidays Section
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        iconColor: theme.colorScheme.primary,
                        collapsedIconColor: theme.colorScheme.primary,
                        title: Text(
                          'Upcoming Leaves & Holidays',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
                        ),
                        childrenPadding: const EdgeInsets.only(left: 0, right: 0, bottom: 8),
                        children: upcomingLeavesAndHolidays.map((event) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            dense: true,
                            leading: Icon(event["icon"], color: event["color"], size: 20),
                            title: Text('${event["type"]} - ${event["label"]}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(DateFormat('EEE, d MMM yyyy').format(event["date"]),
                                style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Color Indicator Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color Indicators:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildColorIndicator(Colors.green[900]!.withOpacity(0.5), 'Present'),
                        _buildColorIndicator(Colors.red[900]!.withOpacity(0.5), 'Absent'),
                        _buildColorIndicator(Colors.orange[900]!.withOpacity(0.5), 'Leave'),
                        _buildColorIndicator(Colors.purple[900]!.withOpacity(0.5), 'Holiday'),
                        _buildColorIndicator(Colors.blue[900]!.withOpacity(0.5), 'Weekend'),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 400,
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
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
                      // Determine the day status using helper functions
                      final bool weekend = _isWeekend(day);
                      final bool nationalHoliday = _isHoliday(day, holidayDays);
                      final bool leaveDay = _isLeaveDay(day, approvedLeaveDays);
                      final bool absentDay = _isAbsentDay(day, absentDays);

                      // Set colors and icons based on status
                      Color bgColor;
                      IconData? icon;
                      Color textColor;

                      if (absentDay) {
                        bgColor = Colors.red.withOpacity(0.3);
                        textColor = Colors.red[900]!;
                      } else if (leaveDay) {
                        bgColor = Colors.orange.withOpacity(0.3);
                        textColor = Colors.orange[900]!;
                      } else if (nationalHoliday) {
                        bgColor = Colors.purple.withOpacity(0.3);
                        textColor = Colors.purple[900]!;
                      } else if (weekend) {
                        bgColor = Colors.blue.withOpacity(0.2);
                        textColor = Colors.blue[900]!;
                      } else {
                        bgColor = Colors.green.withOpacity(0.3);
                        textColor = Colors.green[900]!;
                      }

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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
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

  // Helper widget for color indicators
  Widget _buildColorIndicator(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
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