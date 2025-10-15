import 'package:employee_management/features/presentation/screens/punch_history_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/widgets/app_side_drawer.dart';
import 'package:intl/intl.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:get_it/get_it.dart';
import '../../../core/utils/network_result.dart';
import '../../data/models/punch/response/attendence_response.dart';
import '../../data/models/report/attendance_report_response.dart';
import '../../domain/use_cases/attendance_report_use_case.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final PunchHistoryUseCase _useCase = GetIt.I<PunchHistoryUseCase>();
  final AttendanceReportUseCase _attendanceReportUseCase = GetIt.I<AttendanceReportUseCase>();

  AttendanceReportResponse? _reportData;
  bool _isLoading = true;
  String? _error;
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchReportDataForMonth(_focusedMonth);
  }

  void _onCalendarPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    });
    _fetchReportDataForMonth(_focusedMonth);
  }

  Future<void> _fetchReportDataForMonth(DateTime month) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final date = DateTime(month.year, month.month, 1);
    final result = await _attendanceReportUseCase.call(date: DateFormat('yyyy-MM-dd').format(date),);
    if (result is NetworkSuccess<AttendanceReportResponse>) {
      setState(() {
        _reportData = result.data;
        _isLoading = false;
      });
    } else if (result is NetworkError) {
      setState(() {
        _error = (result as NetworkError).message;
        _isLoading = false;
      });
    }
  }

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

  bool _isHalfDay(DateTime day, List<DateTime> halfDays) {
    return halfDays.any((halfDay) =>
    halfDay.day == day.day && halfDay.month == day.month && halfDay.year == day.year);
  }

  bool _isShortLeave(DateTime day, List<DateTime> shortLeaves) {
    return shortLeaves.any((shortLeave) =>
    shortLeave.day == day.day && shortLeave.month == day.month && shortLeave.year == day.year);
  }

  bool _isPresentDay(DateTime day, Set<DateTime> presentDays) {
    return presentDays.any((presentDay) =>
    presentDay.day == day.day && presentDay.month == day.month && presentDay.year == day.year);
  }

  void showPunchDetailSheet(DateTime date) async {
    final result = await _useCase.callPunchDetail(date: DateFormat('yyyy-MM-dd').format(date),);

    if (result is NetworkSuccess<AttendanceResponse>) {
      final attendanceDetails = result.data.attendances;
      final formattedDate = DateFormat('EEEE, d MMM yyyy').format(date);

      String punchInTime = '--:--';
      String punchOutTime = '--:--';

      for (var attendance in attendanceDetails) {
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30)),),
        builder: (context) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return AttendanceDetailSheet(
                attendanceDetails: attendanceDetails,
                punchIn: punchInTime,
                punchOut: punchOutTime,
                scrollController: scrollController,
                formattedDate: formattedDate,
              );
            },
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No attendance data found.')),);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Sandwich Relief Card
              _buildSandwichReliefCard(theme),

              const SizedBox(height: 12),

              // Stats & Upcoming Leaves Card
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                      : _buildStatsAndUpcoming(theme),
                ),
              ),

              // Legend
              _buildLegend(theme),

              const SizedBox(height: 12),

              // Calendar
              SizedBox(
                height: 400,
                child: _isLoading ? const Center(child: CircularProgressIndicator())
                    : TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365 * 4)),
                  lastDay: DateTime.now().add(const Duration(days: 365 * 4)),
                  focusedDay: _focusedMonth,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Month',},
                  onFormatChanged: (format) {},
                  onPageChanged: _onCalendarPageChanged,
                  onDaySelected: (selected, focused) => showPunchDetailSheet(selected),
                  calendarBuilders: _buildCalendarBuilders(),
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    leftChevronVisible: true,
                    rightChevronVisible: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatBlock(Icons.calendar_today, 'Working', (_reportData?.totalWorkingDays ?? 0).toDouble(), Colors.grey.shade700),
            _buildStatBlock(Icons.check_circle, 'Present', (_reportData?.presentDays ?? 0).toDouble(), Colors.green),
            _buildStatBlock(Icons.cancel, 'Absent', (_reportData?.absentDays ?? 0).toDouble(), Colors.red),
            _buildStatBlock(Icons.beach_access, 'Leave', (_reportData?.leaveDays ?? 0).toDouble(), Colors.orange),

          ],
        ),
        const SizedBox(height: 12),
        // Upcoming Leaves & Holidays
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.primary,
          title: Text('Upcoming Leaves & Holidays', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),),
          childrenPadding: const EdgeInsets.only(left: 0, right: 0, bottom: 8),
          children: [
            if (_reportData?.upcomingHolidays != null && _reportData!.upcomingHolidays.isNotEmpty)
              ..._reportData!.upcomingHolidays.map((holiday) => ListTile(
                leading: Icon(Icons.celebration, color: Colors.deepOrange[700], size: 20),
                title: Text('Holiday - ${holiday.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(DateFormat('EEE, d MMM yyyy').format(DateTime.parse(holiday.date)), style: const TextStyle(fontSize: 12)),
              )),
            if (_reportData?.upcomingLeaves != null && _reportData!.upcomingLeaves.isNotEmpty)
              ..._reportData!.upcomingLeaves.map((leave) => ListTile(
                leading: Icon(Icons.beach_access, color: Colors.blue[700], size: 20),
                title: Text(leave.leaveType, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text("${DateFormat('EEE, d MMM yyyy').format(DateTime.parse(leave.fromDate))} to ${DateFormat('EEE, d MMM yyyy').format(DateTime.parse(leave.toDate))}", style: const TextStyle(fontSize: 12)),
              )),
            if ((_reportData?.upcomingHolidays == null || _reportData!.upcomingHolidays.isEmpty) &&
                (_reportData?.upcomingLeaves == null || _reportData!.upcomingLeaves.isEmpty))
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('No upcoming leaves or holidays.', style: TextStyle(color: Colors.grey[600])),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  CalendarBuilders _buildCalendarBuilders() {
    final now = DateTime.now();

    final List<DateTime> absentDays = _reportData?.absentDates.map((d) => DateTime.parse(d)).toList() ?? [];
    final Set<DateTime> leaveDays = _reportData?.leaveDates.map((d) => DateTime.parse(d)).toSet() ?? {};
    final List<DateTime> holidayDays = _reportData?.upcomingHolidays.map((h) => DateTime.parse(h.date)).toList() ?? [];
    final List<DateTime> halfDays = _reportData?.halfDayLeaveDates.map((d) => DateTime.parse(d)).toList() ?? [];  //change absent date to halfday dates
    final List<DateTime> shortLeave = _reportData?.shortLeaveDates.map((d) => DateTime.parse(d)).toList() ?? [];  //change absent date to halfday dates
    final Set<DateTime> presentDays = _reportData?.presentDates.map((d) => DateTime.parse(d)).toSet() ?? {};

    return CalendarBuilders(
      defaultBuilder: (context, day, focusedDay) {
        final bool isHolidayDay = _isHoliday(day, holidayDays);
        final bool isLeaveDay = _isLeaveDay(day, leaveDays);
        final bool isAbsentDay = _isAbsentDay(day, absentDays);
        final bool isHalfDay = _isHalfDay(day, halfDays);
        final bool isShortLeave = _isShortLeave(day, shortLeave);
        final bool isPresentDay = _isPresentDay(day, presentDays);

        Color bgColor;
        Color textColor;
        Widget child;

        if (isAbsentDay) {
          bgColor = Colors.red.withValues(alpha: 0.3);
          textColor = Colors.red[900]!;
          child = Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16));
        } else if (isLeaveDay) {
          bgColor = Colors.orange.withValues(alpha: 0.3);
          textColor = Colors.orange[900]!;
          child = Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16));
        } else if (isHolidayDay) {
          bgColor = Colors.transparent;
          textColor = Colors.white;
          child = const Icon(Icons.celebration, size: 30, color: Colors.deepPurpleAccent); // pop icon
        }else if (isHalfDay) {
          bgColor = Colors.teal.shade500.withValues(alpha: 0.2);
          textColor = Colors.teal[900]!;
          child = Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16));
        } else if (isShortLeave) {
          bgColor = Colors.blue.withValues(alpha: 0.2);
          textColor = Colors.blue[900]!;
          child = Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16));
        }  else if (isPresentDay) {
          bgColor = Colors.green.withValues(alpha: 0.3);
          textColor = Colors.green[900]!;
          child = Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16));
        }else {
            bgColor = Colors.grey.withValues(alpha: 0.2); // Present
            textColor = Colors.grey[900]!;
          child = Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16));
        }

        final bool isToday = day.year == now.year && day.month == now.month && day.day == now.day;

        return Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor, border: isToday ? Border.all(color: const Color(0xFF388E3C), width: 2.5) : null,),
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  }

  Widget _buildColorIndicator(Color color, String label, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 18, color: color)
        else
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300),),
          ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

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
