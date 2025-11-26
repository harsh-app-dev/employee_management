import 'package:employee_management/features/presentation/screens/punch_history_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/widgets/app_side_drawer.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../domain/use_cases/punch_history_use_case.dart';
import '../../domain/use_cases/attendance_report_use_case.dart';
import '../../data/models/punch/response/attendence_response.dart';
import '../state/getx/report_controller.dart';

class ReportScreen extends StatelessWidget {
  ReportScreen({super.key});

  // Initialize the controller using GetX

  final ReportController controller = Get.put(
    ReportController(
      punchUseCase: Get.find<PunchHistoryUseCase>(),
      reportUseCase: Get.find<AttendanceReportUseCase>(),
    ),
  );


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Refresh API every time this widget is built
    controller.fetchReportData(controller.focusedMonth.value);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppSideDrawer(),
        appBar: AppBar(
          title: const Text(
            'Report',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Obx(
              () => SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSandwichReliefCard(theme),
                const SizedBox(height: 12),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: controller.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : controller.error.value != null
                        ? Center(
                        child: Text(
                          'Error: ${controller.error.value}',
                          style: const TextStyle(color: Colors.red),
                        ))
                        : _buildStatsAndUpcoming(theme),
                  ),
                ),
                _buildLegend(theme),
                const SizedBox(height: 12),
                SizedBox(
                  height: 400,
                  child: controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : TableCalendar(
                    firstDay: DateTime.now()
                        .subtract(const Duration(days: 365 * 4)),
                    lastDay: DateTime.now()
                        .add(const Duration(days: 365 * 4)),
                    focusedDay: controller.focusedMonth.value,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month'
                    },
                    onFormatChanged: (_) {},
                    onPageChanged: controller.onCalenderPageChanged,
                    onDaySelected: (selected, focused) async {
                      final punchData =
                      await controller.getPunchDetails(selected);
                      if (punchData != null) {
                        _showPunchDetailSheet(
                            context, selected, punchData);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text('No attendance data found.')),
                        );
                      }
                    },
                    calendarBuilders: _buildCalendarBuilders(),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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


  // Punch Detail Bottom Sheet
  void _showPunchDetailSheet(BuildContext context, DateTime date, AttendanceResponse data) {
    final formattedDate = DateFormat('EEEE, d MMM yyyy').format(date);

    String punchInTime = '--:--';
    String punchOutTime = '--:--';

    for (var attendance in data.attendances) {
      if (attendance.workLogs != null && attendance.workLogs!.isNotEmpty) {
        for (var log in attendance.workLogs!) {
          if (log.type == 'punch_in') punchInTime = log.time ?? '--:--';
          if (log.type == 'punch_out') punchOutTime = log.time ?? '--:--';
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return AttendanceDetailSheet(
              attendanceDetails: data.attendances,
              punchIn: punchInTime,
              punchOut: punchOutTime,
              scrollController: scrollController,
              formattedDate: formattedDate,
            );
          },
        );
      },
    );
  }

  // ------------------------- UI Widgets ----------------------------

  Widget _buildSandwichReliefCard(ThemeData theme) {
    final DateTime sandwichStart = DateTime(DateTime.now().year, 9, 1);
    final DateTime nowDate = DateTime.now();
    final int sandwichDaysElapsed = nowDate.difference(sandwichStart).inDays;
    final int sandwichDaysRemaining = 60 - sandwichDaysElapsed;
    final bool sandwichEligible = sandwichDaysElapsed >= 60;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary.withValues(alpha: 0.85), theme.colorScheme.secondary.withValues(alpha: 0.85)],
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
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        Text(
                          '${sandwichDaysRemaining > 0 ? sandwichDaysRemaining : 0}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                    const Icon(Icons.celebration, color: Colors.amberAccent, size: 32),
                    const SizedBox(height: 6),
                    const Text('Congratulations!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amberAccent)),
                    const SizedBox(height: 4),
                    const Text('You are eligible for a sandwich relief! No leave taken in the last 60 days since July 1.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsAndUpcoming(ThemeData theme) {
    final data = controller.reportData.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatBlock(Icons.calendar_today, 'Working', (data?.totalWorkingDays ?? 0).toDouble(), Colors.grey.shade700),
            _buildStatBlock(Icons.check_circle, 'Present', (data?.presentDays ?? 0).toDouble(), Colors.green),
            _buildStatBlock(Icons.cancel, 'Absent', (data?.absentDays ?? 0).toDouble(), Colors.red),
            _buildStatBlock(Icons.beach_access, 'Leave', (data?.leaveDays ?? 0).toDouble(), Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.primary,
          title: Text(
            'Upcoming Leaves & Holidays',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
          ),
          childrenPadding: const EdgeInsets.only(left: 0, right: 0, bottom: 8),
          children: [
            if (data?.upcomingHolidays != null && data!.upcomingHolidays.isNotEmpty)
              ...data.upcomingHolidays.map((holiday) => ListTile(
                leading: Icon(Icons.celebration, color: Colors.deepOrange[700], size: 20),
                title: Text('Holiday - ${holiday.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(DateFormat('EEE, d MMM yyyy').format(DateTime.parse(holiday.date)),
                    style: const TextStyle(fontSize: 12)),
              )),
            if (data?.upcomingLeaves != null && data!.upcomingLeaves.isNotEmpty)
              ...data.upcomingLeaves.map((leave) => ListTile(
                leading: Icon(Icons.beach_access, color: Colors.blue[700], size: 20),
                title: Text(leave.leaveType,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                    "${DateFormat('EEE, d MMM yyyy').format(DateTime.parse(leave.fromDate))} to ${DateFormat('EEE, d MMM yyyy').format(DateTime.parse(leave.toDate))}",
                    style: const TextStyle(fontSize: 12)),
              )),
            if ((data?.upcomingHolidays == null || data!.upcomingHolidays.isEmpty) &&
                (data?.upcomingLeaves == null || data!.upcomingLeaves.isEmpty))
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('No upcoming leaves or holidays.', style: TextStyle(color: Colors.grey[600])),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBlock(IconData icon, String label, double value, Color color) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, spreadRadius: 1)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right : 10, top: 25),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _buildColorIndicator(Colors.green[900]!.withValues(alpha: 0.5), 'Present'),
          _buildColorIndicator(Colors.red[900]!.withValues(alpha: 0.5), 'Absent'),
          _buildColorIndicator(Colors.orange[900]!.withValues(alpha: 0.5), 'Leave'),
          _buildColorIndicator(Colors.purple[900]!.withValues(alpha: 0.5), 'Holiday', icon: Icons.celebration),
          _buildColorIndicator(Colors.teal[500]!.withValues(alpha: 0.5), 'HalfDay'),
          _buildColorIndicator(Colors.blue.withValues(alpha: 0.5), 'ShortLeave'),
          _buildColorIndicator(Colors.grey.withValues(alpha: 0.5), 'No Record'),
        ],
      ),
    );
  }

  Widget _buildColorIndicator(Color color, String label, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon != null
            ? Icon(icon, color: color, size: 16)
            : Container(width: 16, height: 16, color: color, margin: const EdgeInsets.only(right: 4)),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  CalendarBuilders _buildCalendarBuilders() {
    final data = controller.reportData.value;

    final List<DateTime> absentDays =
        data?.absentDates.map((d) => DateTime.parse(d)).toList() ?? [];
    final Set<DateTime> leaveDays =
        data?.leaveDates.map((d) => DateTime.parse(d)).toSet() ?? {};
    final List<DateTime> holidayDays =
        data?.upcomingHolidays.map((h) => DateTime.parse(h.date)).toList() ?? [];
    final List<DateTime> halfDays =
        data?.halfDayLeaveDates.map((d) => DateTime.parse(d)).toList() ?? [];
    final List<DateTime> shortLeaves =
        data?.shortLeaveDates.map((d) => DateTime.parse(d)).toList() ?? [];
    final Set<DateTime> presentDays =
        data?.presentDates.map((d) => DateTime.parse(d)).toSet() ?? {};

    return CalendarBuilders(
      defaultBuilder: (context, day, focusedDay) {
        Widget dayWidget;
        if (controller.isHoliday(day, holidayDays)) {
          dayWidget = Center(
            child: Icon(
              Icons.celebration,
              color: Colors.purple[700],
              size: 24,
            ),
          );
        } else {
          // Other day types: colored circle with date
          Color? bgColor;
          if (controller.isLeaveDay(day, leaveDays)) {
            bgColor = Colors.orange[200];
          } else if (controller.isAbsentDay(day, absentDays)) {
            bgColor = Colors.red[200];
          } else if (controller.isHalfDay(day, halfDays)) {
            bgColor = Colors.teal[200];
          } else if (controller.isShortLeave(day, shortLeaves)) {
            bgColor = Colors.blue[200];
          } else if (controller.isPresentDay(day, presentDays)) {
            bgColor = Colors.green[200];
          }

          dayWidget = Center(
            child: Container(
              decoration: bgColor != null
                  ? BoxDecoration(color: bgColor, shape: BoxShape.circle)
                  : null,
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Text(day.day.toString()),
            ),
          );
        }

        return dayWidget;
      },
    );
  }
}
