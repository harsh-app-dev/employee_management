import 'dart:io';
import 'dart:async';
import 'package:employee_management/core/configs/strings.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/network_result.dart';
import '../../../core/widgets/debouncing_state.dart';
import '../../data/models/floor/profile_data.dart';
import '../../data/models/punch/response/attendence_response.dart';
import '../state/profile_controller.dart';
import '../state/punch_controller.dart';
import '../../../core/widgets/app_side_drawer.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:intl/intl.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PunchController _punchController;
  late final ProfileController _profileController;
  final ValueNotifier<String> _profileInitials = ValueNotifier('?');
  Profile? _currentProfile;
  final Debouncer _submitDebouncer = Debouncer(delay: Duration(seconds: 2));
  File? _selfieImage;
  final ImagePicker _picker = ImagePicker();
  Timer? _workBreakTimer;
  int _workedSeconds = 0;
  int _breakSeconds = 0;
  String? _lastPunchType;
  DateTime? _lastPunchTime;
  bool _isApiLoading = false;
  String _workedDuration = '--';
  String _breakDuration = '--';
  String _firstPunchIn = '--';
  String _lastPunchOut = '--';
  final PunchHistoryUseCase _punchHistoryUseCase = getIt<PunchHistoryUseCase>();
  List<Attendance> _todaysPunchEntries = [];
  bool _isBreakButtonEnabled = false;
  bool _isOnBreak = false;
  bool _isBreakLoading = false;

  @override
  void initState() {
    super.initState();
    _punchController = getIt<PunchController>();
    _profileController = getIt<ProfileController>();
    _profileController.fetchAndSaveProfile().then((_) async {
      await _fetchProfileData();
    });
    requestLocationPermission();
    _checkAndResetPunchTimes();
    _loadWorkBreakFromPrefs();
    _startWorkBreakUiTimer();
    _fetchTodaysPunchHistory();
    // add announcement dialog
  }

  @override
  void dispose() {
    super.dispose();
  }


  Future<void> _checkAndResetPunchTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString('lastPunchDate');
    final today = DateTime.now();
    bool shouldReset = false;
    if (lastDateStr != null) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate == null || lastDate.year != today.year || lastDate.month != today.month || lastDate.day != today.day) {
        shouldReset = true;
      }
    } else {
      shouldReset = true;
    }
    if (shouldReset) {
      await prefs.remove('punchInTime');
      await prefs.remove('punchOutTime');
      await prefs.setString('lastPunchDate', today.toIso8601String());
    }
  }

  Future<void> _fetchProfileData() async {
    final profiles = await _profileController.profileDao.getAllProfiles();
    final profile = profiles.isNotEmpty ? profiles.first : null;
    if (profile != null) {
      _profileInitials.value = getInitials(profile.first_name, profile.last_name);
      setState(() {
        _currentProfile = profile;
      });
    } else {
      _profileInitials.value = '?';
      setState(() {
        _currentProfile = null;
      });
    }
  }

  void _startWorkBreakUiTimer() {
    _workBreakTimer?.cancel();
    _workBreakTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _loadWorkBreakFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workedSeconds = prefs.getInt('workedSeconds') ?? 0;
      _breakSeconds = prefs.getInt('breakSeconds') ?? 0;
      _lastPunchType = prefs.getString('lastPunchType');
      final lastPunchTimeStr = prefs.getString('lastPunchTime');
      _lastPunchTime = lastPunchTimeStr != null ? DateTime.tryParse(lastPunchTimeStr) : null;
    });
  }

  Future<void> _saveWorkBreakToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workedSeconds', _workedSeconds);
    await prefs.setInt('breakSeconds', _breakSeconds);
    if (_lastPunchType != null) await prefs.setString('lastPunchType', _lastPunchType!);
    if (_lastPunchTime != null) await prefs.setString('lastPunchTime', _lastPunchTime!.toIso8601String());
  }

  void _updateWorkBreakOnPunch(String punchType) async {
    final now = DateTime.now();
    if (_lastPunchType == 'in' && _lastPunchTime != null) {
      final session = now.difference(_lastPunchTime!).inSeconds;
      _workedSeconds += session;
      _lastPunchType = 'out';
      _lastPunchTime = now;
    } else if (punchType == 'in') {
      if (_lastPunchType == 'out' && _lastPunchTime != null) {
        final breakSession = now.difference(_lastPunchTime!).inSeconds;
        _breakSeconds += breakSession;
      }
      _lastPunchType = 'in';
      _lastPunchTime = now;
    }
    await _saveWorkBreakToPrefs();
    setState(() {});
  }

  String? _formatApiDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return '--';
    try {
      if (durationStr.contains('.')) {
        durationStr = durationStr.split('.')[0];
      }

      final parts = durationStr.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = parts.length > 2 ? int.parse(parts[2]) : 0;

      String result = '';
      if (hours > 0) result += '${hours}h ';
      if (minutes > 0) result += '${minutes}m ';
      if (seconds > 0) result += '${seconds}s ';

      return result.trim();
    } catch (_) {
      return durationStr;
    }
  }


  String _formatTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (_) {
      return '--';
    }
  }

  Future<void> _fetchTodaysPunchHistory() async {
    setState(() {});

    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final result = await _punchHistoryUseCase.callPunchDetail();
    print("===============================$result");

    if (result is NetworkSuccess<AttendanceResponse>) {
      print("checking passed");

      final records = result.data.attendances;
      _todaysPunchEntries = records;

      List<DateTime> punchInTimes = [];
      List<DateTime> punchOutTimes = [];
      List<DateTime> breakStartTimes = [];
      List<DateTime> breakEndTimes = [];

      // Collect all work logs from ALL attendance records for today
      List<WorkLog> allTodaysWorkLogs = [];

      for (var attendance in records) {
        if (attendance.attendanceDate == dateStr && attendance.workLogs != null) {
          allTodaysWorkLogs.addAll(attendance.workLogs!);
          print("Found attendance for today with ${attendance.workLogs!.length} work logs");
        }
      }

      if (allTodaysWorkLogs.isNotEmpty) {
        print("Total work logs for today: ${allTodaysWorkLogs.length}");

        for (var log in allTodaysWorkLogs) {
          try {
            print("Log type: ${log.type}, time: ${log.time}");

            if (log.time != null && log.time!.isNotEmpty) {
              DateTime? eventDateTime;

              try {
                // Find the attendance record that contains this log to get the date
                String? logDate;
                for (var attendance in records) {
                  if (attendance.workLogs != null && attendance.workLogs!.contains(log)) {
                    logDate = attendance.attendanceDate;
                    break;
                  }
                }

                if (logDate != null) {
                  eventDateTime = DateTime.parse("${logDate}T${log.time}");
                  print("Parsing successful: $eventDateTime");
                }
              } catch (e) {
                print("Date parsing failed: $e");
              }

              if (eventDateTime != null) {
                switch (log.type) {
                  case 'punch_in':
                    punchInTimes.add(eventDateTime);
                    print("Added punch_in time: $eventDateTime");
                    break;
                  case 'punch_out':
                    punchOutTimes.add(eventDateTime);
                    print("Added punch_out time: $eventDateTime");
                    break;
                  case 'break_start':
                    breakStartTimes.add(eventDateTime);
                    print("Added break_start time: $eventDateTime");
                    break;
                  case 'break_end':
                    breakEndTimes.add(eventDateTime);
                    print("Added break_end time: $eventDateTime");
                    break;
                }
              }
            }
          } catch (e) {
            print("Error processing log: $e");
          }
        }
      } else {
        print("No work logs found for today");
      }

      // Sort all times
      punchInTimes.sort();
      punchOutTimes.sort();
      breakStartTimes.sort();
      breakEndTimes.sort();

      print("Punch in times: $punchInTimes");
      print("Punch out times: $punchOutTimes");
      print("Break start times: $breakStartTimes");
      print("Break end times: $breakEndTimes");

      // Get first punch in and last punch out
      _firstPunchIn = punchInTimes.isNotEmpty ? DateFormat('hh:mm a').format(punchInTimes.first) : '--';
      _lastPunchOut = punchOutTimes.isNotEmpty ? DateFormat('hh:mm a').format(punchOutTimes.last) : '--';

      // Calculate total work and break duration from all today's attendance records
      Duration totalWorkDuration = Duration();
      Duration totalBreakDuration = Duration();

      for (var attendance in records) {
        if (attendance.attendanceDate == dateStr) {
          if (attendance.totalWorkHour != null && attendance.totalWorkHour!.isNotEmpty) {
            totalWorkDuration += _parseDurationFromString(attendance.totalWorkHour!);
          }
          if (attendance.totalBreakHour != null && attendance.totalBreakHour!.isNotEmpty) {
            totalBreakDuration += _parseDurationFromString(attendance.totalBreakHour!);
          }
        }
      }

      _workedDuration = _formatDuration(totalWorkDuration);
      _breakDuration = _formatDuration(totalBreakDuration);

      print("Work duration: $_workedDuration, Break duration: $_breakDuration");

      // Enable break button if user is punched in but not punched out
      _isBreakButtonEnabled = punchInTimes.isNotEmpty &&
          (punchOutTimes.isEmpty || punchOutTimes.last.isBefore(punchInTimes.last));

      // Check if currently on break (break started but not ended)
      _isOnBreak = breakStartTimes.isNotEmpty &&
          (breakEndTimes.isEmpty || breakEndTimes.last.isBefore(breakStartTimes.last));

    } else {
      print("checking failed - Network error");
      _todaysPunchEntries = [];
      _firstPunchIn = '--';
      _lastPunchOut = '--';
      _workedDuration = '--';
      _breakDuration = '--';
      _isBreakButtonEnabled = false;
      _isOnBreak = false;
    }

    setState(() {});
  }

  Duration _parseDurationFromString(String durationStr) {
    try {
      final parts = durationStr.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = parts.length > 2 ? int.parse(parts[2]) : 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } catch (e) {
      return Duration();
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds == 0) return '--';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    String result = '';
    if (hours > 0) result += '${hours}h ';
    if (minutes > 0) result += '${minutes}m ';

    return result.trim();
  }

  Future<void> _refreshPunchHistoryAndWorkedTimes() async {
    setState(() {});
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final result = await _punchHistoryUseCase.callPunchDetail();

    if (result is NetworkSuccess<AttendanceResponse>) {
      final entries = result.data.attendances;
      _todaysPunchEntries = entries;

      // Collect all work logs from all today's attendance records
      List<WorkLog> allTodaysWorkLogs = [];
      for (var attendance in entries) {
        if (attendance.attendanceDate == dateStr && attendance.workLogs != null) {
          allTodaysWorkLogs.addAll(attendance.workLogs!);
        }
      }

      if (allTodaysWorkLogs.isNotEmpty) {
        final punchInEvents = allTodaysWorkLogs.where((e) => e.type == 'punch_in').toList();
        final punchOutEvents = allTodaysWorkLogs.where((e) => e.type == 'punch_out').toList();
        final breakStartEvents = allTodaysWorkLogs.where((e) => e.type == 'break_start').toList();
        final breakEndEvents = allTodaysWorkLogs.where((e) => e.type == 'break_end').toList();

        // Sort events by time (you might need to parse the time strings to DateTime for proper sorting)
        punchInEvents.sort((a, b) => (a.time ?? '').compareTo(b.time ?? ''));
        punchOutEvents.sort((a, b) => (a.time ?? '').compareTo(b.time ?? ''));
        breakStartEvents.sort((a, b) => (a.time ?? '').compareTo(b.time ?? ''));
        breakEndEvents.sort((a, b) => (a.time ?? '').compareTo(b.time ?? ''));

        bool isPunchedIn = punchInEvents.isNotEmpty &&
            (punchOutEvents.isEmpty || punchOutEvents.last.time!.compareTo(punchInEvents.last.time!) < 0);

        bool isOnBreak = breakStartEvents.isNotEmpty &&
            (breakEndEvents.isEmpty || breakEndEvents.last.time!.compareTo(breakStartEvents.last.time!) < 0);

        // Calculate total durations from all today's attendance records
        Duration totalWorkDuration = Duration();
        Duration totalBreakDuration = Duration();

        for (var attendance in entries) {
          if (attendance.attendanceDate == dateStr) {
            if (attendance.totalWorkHour != null && attendance.totalWorkHour!.isNotEmpty) {
              totalWorkDuration += _parseDurationFromString(attendance.totalWorkHour!);
            }
            if (attendance.totalBreakHour != null && attendance.totalBreakHour!.isNotEmpty) {
              totalBreakDuration += _parseDurationFromString(attendance.totalBreakHour!);
            }
          }
        }

        _workedDuration = _formatDuration(totalWorkDuration);
        _breakDuration = _formatDuration(totalBreakDuration);
        _firstPunchIn = punchInEvents.isNotEmpty ? punchInEvents.first.time ?? '--' : '--';
        _lastPunchOut = punchOutEvents.isNotEmpty ? punchOutEvents.last.time ?? '--' : '--';

        _isBreakButtonEnabled = isPunchedIn;
        _isOnBreak = isOnBreak;
      } else {
        _workedDuration = '--';
        _breakDuration = '--';
        _firstPunchIn = '--';
        _lastPunchOut = '--';
        _isBreakButtonEnabled = false;
        _isOnBreak = false;
      }
    } else {
      _workedDuration = '--';
      _breakDuration = '--';
      _firstPunchIn = '--';
      _lastPunchOut = '--';
      _isBreakButtonEnabled = false;
      _isOnBreak = false;
    }
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activityEvents = _getAllTodaysActivityEvents();

    return Scaffold(
      backgroundColor: theme.colorScheme.onPrimary,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.onPrimary, size: 30,),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7),],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Align(
          alignment: Alignment.center,
          child: Text(AppStrings.dashboard, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary,),),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white, size: 30,),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationScreen()),);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: AppSideDrawer(),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                    child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Card(
                                  elevation: 10,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),),
                                  margin: EdgeInsets.only(bottom: 3.h),
                                  color: theme.brightness == Brightness.light ? Colors.white : theme.cardColor,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h,),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7,),],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: EdgeInsets.all(10),
                                              child: Icon(Icons.calendar_today, color: Colors.white, size: 24.sp,),
                                            ),
                                            SizedBox(width: 2.w),
                                            Text(
                                              AppStrings.attendance,
                                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 20.sp,),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2.h),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.login, color: Colors.green, size: 22),
                                                SizedBox(width: 1.w),
                                                Text('In: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                                Text(_firstPunchIn, style: TextStyle(fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                            SizedBox(width: 4.w),
                                            Row(
                                              children: [
                                                Icon(Icons.logout, color: Colors.red, size: 22),
                                                SizedBox(width: 1.w),
                                                Text('Out: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                                Text(_lastPunchOut, style: TextStyle(fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2.h),
                                        Column(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.timer, color: theme.colorScheme.primary),
                                                  SizedBox(width: 2.w),
                                                  Text(
                                                    '${AppStrings.workedHrs}: ',
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary,),
                                                  ),
                                                  Text(
                                                    _workedDuration.isNotEmpty && _workedDuration != '--' ? _workedDuration : '00:00:00',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: theme.colorScheme.primary,),
                                                  ),

                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 1.h),

                                            // Break Hours Box
                                            Container(
                                              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
                                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10),),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.pause_circle_filled, color: Colors.orange),
                                                  SizedBox(width: 2.w),
                                                  Text(
                                                    '${AppStrings.breakHrs}: ',
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange,),
                                                  ),
                                                  Text(
                                                    _breakDuration != '--' ? _breakDuration : '00:00:00',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.orange,),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2.h),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 9.h,
                                          child: Builder(
                                            builder: (context) {
                                              String buttonText;
                                              VoidCallback? onPressed;
                                              Color buttonColor;
                                              IconData buttonIcon;

                                              final isActive = _currentProfile?.is_active == 'active';
                                              final isLeft = _currentProfile?.is_active == 'left' || _currentProfile?.is_active == 'absent';

                                              if (isActive) {
                                                buttonText = AppStrings.punchOut;
                                                buttonIcon = Icons.logout;
                                                buttonColor = Colors.red;
                                                onPressed = () async {

                                                  if (!await checkInternet(context)) return;

                                                  final confirm = await showPunchConfirmationDialog(context, isPunchOut: true);
                                                  if(!confirm) return;

                                                  final XFile? image = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front,);

                                                  if (image != null) {
                                                    setState(() {
                                                      _selfieImage = File(image.path);
                                                      _isApiLoading = true;
                                                    });
                                                    await _submitDebouncer.run(() async {
                                                      await _punchController.punchInOut('punch_out', punchPhoto: _selfieImage);
                                                      if (!mounted) return;
                                                      if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                                        setState(() {
                                                          _isApiLoading = false;
                                                          _isBreakButtonEnabled = false;
                                                          _isOnBreak = false;
                                                        });
                                                        _updateWorkBreakOnPunch('out');
                                                        await _refreshPunchHistoryAndWorkedTimes();
                                                        if (_currentProfile != null) {
                                                          final updated = Profile(
                                                            id: _currentProfile!.id,
                                                            first_name: _currentProfile!.first_name,
                                                            last_name: _currentProfile!.last_name,
                                                            email: _currentProfile!.email,
                                                            dob: _currentProfile!.dob,
                                                            phoneNo: _currentProfile!.phoneNo,
                                                            designation: _currentProfile!.designation,
                                                            organization: _currentProfile!.organization,
                                                            is_active: 'left',
                                                          );
                                                          await _profileController.profileDao.insertProfile(updated);
                                                          setState(() {
                                                            _currentProfile = updated;
                                                          });
                                                        }
                                                        showGlobalSnackBarWithIcon(AppStrings.punchOutSuccess, icon: Icons.logout, iconColor: Colors.red);
                                                      } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                                        if (!mounted) return;
                                                        setState(() { _isApiLoading = false; });
                                                        showGlobalSnackBarWithIcon(_punchController.punchInOutApiState.value?.error ?? AppStrings.punchFailed, icon: Icons.error_outline, iconColor: Colors.red);
                                                      } else {
                                                        if (!mounted) return;
                                                        setState(() { _isApiLoading = false; });
                                                      }
                                                    });
                                                  } else {
                                                    showGlobalSnackBarWithIcon('Please take a selfie to proceed.', icon: Icons.camera_alt, iconColor: Colors.orange);
                                                  }
                                                };
                                              } else if (isLeft) {
                                                buttonText = AppStrings.punchIn;
                                                buttonIcon = Icons.login;
                                                buttonColor = theme.colorScheme.primary;
                                                onPressed = () async {

                                                  if (!await checkInternet(context)) return;

                                                  final XFile? image = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front,);
                                                  if (image != null) {
                                                    setState(() {
                                                      _selfieImage = File(image.path);
                                                      _isApiLoading = true;
                                                    });
                                                    await _submitDebouncer.run(() async {
                                                      await _punchController.punchInOut('punch_in', punchPhoto: _selfieImage);
                                                      if (!mounted) return;
                                                      if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                                        setState(() {
                                                          _isApiLoading = false;
                                                          _isBreakButtonEnabled = true;
                                                          _isOnBreak = false;
                                                        });
                                                        _updateWorkBreakOnPunch('in');
                                                        await _refreshPunchHistoryAndWorkedTimes();
                                                        if (_currentProfile != null) {
                                                          final updated = Profile(
                                                            id: _currentProfile!.id,
                                                            first_name: _currentProfile!.first_name,
                                                            last_name: _currentProfile!.last_name,
                                                            email: _currentProfile!.email,
                                                            dob: _currentProfile!.dob,
                                                            phoneNo: _currentProfile!.phoneNo,
                                                            designation: _currentProfile!.designation,
                                                            organization: _currentProfile!.organization,
                                                            is_active: 'active',
                                                          );
                                                          await _profileController.profileDao.insertProfile(updated);
                                                          setState(() {
                                                            _currentProfile = updated;
                                                          });
                                                        }
                                                        showGlobalSnackBarWithIcon(AppStrings.punchInSuccess, icon: Icons.login, iconColor: Colors.green);
                                                        setState(() {
                                                          _isBreakButtonEnabled = true;
                                                          _isOnBreak = false;
                                                        });
                                                      } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                                        if (!mounted) return;
                                                        setState(() { _isApiLoading = false; });
                                                        showGlobalSnackBarWithIcon(_punchController.punchInOutApiState.value?.error ?? AppStrings.punchFailed, icon: Icons.error_outline, iconColor: Colors.red);
                                                      } else {
                                                        if (!mounted) return;
                                                        setState(() { _isApiLoading = false; });
                                                      }
                                                    });
                                                  } else {
                                                    showGlobalSnackBarWithIcon('Please take a selfie to proceed.', icon: Icons.camera_alt, iconColor: Colors.orange);
                                                  }
                                                };
                                              } else {
                                                buttonText = AppStrings.punchIn;
                                                buttonIcon = Icons.login;
                                                buttonColor = theme.colorScheme.primary;
                                                onPressed = () async {

                                                  if (!await checkInternet(context)) return;

                                                  final XFile? image = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front,);
                                                  if (image != null) {
                                                    setState(() {
                                                      _selfieImage = File(image.path);
                                                      _isApiLoading = true;
                                                    });
                                                    await _submitDebouncer.run(() async {
                                                      await _punchController.punchInOut('punch_in', punchPhoto: _selfieImage);
                                                      if (!mounted) return;
                                                      if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                                        setState(() {
                                                          _isApiLoading = false;
                                                        });
                                                        _updateWorkBreakOnPunch('in');
                                                        await _refreshPunchHistoryAndWorkedTimes();
                                                        if (_currentProfile != null) {
                                                          final updated = Profile(
                                                            id: _currentProfile!.id,
                                                            first_name: _currentProfile!.first_name,
                                                            last_name: _currentProfile!.last_name,
                                                            email: _currentProfile!.email,
                                                            dob: _currentProfile!.dob,
                                                            phoneNo: _currentProfile!.phoneNo,
                                                            designation: _currentProfile!.designation,
                                                            organization: _currentProfile!.organization,
                                                            is_active: 'active',
                                                          );
                                                          await _profileController.profileDao.insertProfile(updated);
                                                          setState(() {
                                                            _currentProfile = updated;
                                                          });
                                                        }
                                                        showGlobalSnackBarWithIcon(AppStrings.punchInSuccess, icon: Icons.login, iconColor: Colors.green);
                                                        setState(() {
                                                          _isBreakButtonEnabled = true;
                                                          _isOnBreak = false;
                                                        });
                                                      } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                                        if (!mounted) return;
                                                        setState(() { _isApiLoading = false; });
                                                        showGlobalSnackBarWithIcon(_punchController.punchInOutApiState.value?.error ?? AppStrings.punchFailed, icon: Icons.error_outline, iconColor: Colors.red);
                                                      } else {
                                                        if (!mounted) return;
                                                        setState(() { _isApiLoading = false; });
                                                      }
                                                    });
                                                  } else {
                                                    showGlobalSnackBarWithIcon('Please take a selfie to proceed.', icon: Icons.camera_alt, iconColor: Colors.orange);
                                                  }
                                                };
                                              }
                                              return Row(
                                                children: [
                                                  Expanded(
                                                    flex: 1,
                                                    child: ElevatedButton.icon(
                                                      onPressed: onPressed,
                                                      icon: Icon(buttonIcon, size: 22.sp, color: Colors.white,),
                                                      label: Text(
                                                        buttonText,
                                                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                          backgroundColor: buttonColor,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                          elevation: 0,
                                                          padding: EdgeInsets.symmetric(vertical: 14)
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 3.w,),
                                                  Expanded(
                                                    flex: 1,
                                                    child: ElevatedButton.icon(
                                                      onPressed: (isActive) ? () async {
                                                        if (!_isOnBreak) {
                                                          setState(() { _isBreakLoading = true; });
                                                          await _submitDebouncer.run(() async {
                                                            await _punchController.punchInOut('break_start');
                                                            setState(() {
                                                              _isBreakLoading = false;
                                                            });
                                                            if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                                              await _refreshPunchHistoryAndWorkedTimes();
                                                              showGlobalSnackBarWithIcon('Break started successfully!', icon: Icons.pause_circle, iconColor: Colors.orange);
                                                              _isOnBreak = true;
                                                            } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                                              showGlobalSnackBarWithIcon(_punchController.punchInOutApiState.value?.error ?? 'Failed to start break', icon: Icons.error, iconColor: Colors.red);
                                                            }
                                                          });
                                                        } else {
                                                          setState(() { _isBreakLoading = true; });
                                                          await _submitDebouncer.run(() async {
                                                            await _punchController.punchInOut('break_end');
                                                            setState(() {
                                                              _isBreakLoading = false;
                                                            });
                                                            if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                                              await _refreshPunchHistoryAndWorkedTimes();
                                                              showGlobalSnackBarWithIcon('Break ended successfully!', icon: Icons.play_circle, iconColor: Colors.green);
                                                            } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                                              showGlobalSnackBarWithIcon(_punchController.punchInOutApiState.value?.error ?? 'Failed to end break', icon: Icons.error, iconColor: Colors.red);
                                                            }
                                                          });
                                                        }
                                                      } : null,
                                                      icon: Icon(_isOnBreak ? Icons.play_circle_fill : Icons.pause_circle_outline, size: 22.sp, color: Colors.white),
                                                      label: Text(_isOnBreak ? 'Break Out' : 'Break In',
                                                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: _isOnBreak ? Colors.green : Colors.orange,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                        elevation: 0,
                                                        padding: EdgeInsets.symmetric(vertical: 14),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (activityEvents.isNotEmpty)
                                  Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    margin: EdgeInsets.only(bottom: 3.h),
                                    color: theme.brightness == Brightness.light ? Colors.white : theme.cardColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Today\'s Activity Logs',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
                                          ),
                                          Divider(height: 24, thickness: 1.3, color: Theme.of(context).colorScheme.primary.withOpacity(0.15),),

                                          Stack(
                                            children: [
                                              Positioned(left: 9, top: 10, bottom: 10,
                                                child: Container(width: 2, color: Colors.grey.shade300,),
                                              ),
                                              // All activity entries
                                              Column(
                                                children: activityEvents.expand((activity) {
                                                  final List<Widget> activityEntries = [];
                                                  final activityDate = _getActivityDate(activity);
                                                  final activityTime = "${activityDate}T${activity.time}";

                                                  activityEntries.add(
                                                    Container(
                                                      margin: EdgeInsets.only(bottom: 4),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Container(
                                                            width: 20,
                                                            height: 20,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: _getActivityColor(activity.type),
                                                              border: Border.all(color: Colors.white, width: 3),
                                                            ),
                                                          ),
                                                          SizedBox(width: 16),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                      _getActivityTitle(activity.type),
                                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(height: 4),
                                                                Text(
                                                                  _formatTime(activityTime) ?? '--:--',
                                                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );

                                                  return activityEntries;
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ]
                          ),
                        )
                    )
                )
              ],
            ),
            ValueListenableBuilder(
              valueListenable: _punchController.punchInOutApiState,
              builder: (context, punchInOutState, _) {
                final isLoading = punchInOutState?.isLoading ?? false;
                if (isLoading) {
                  return Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CircularProgressIndicator()),);
                }
                return const SizedBox.shrink();
              },
            ),
            if (_isApiLoading)
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CircularProgressIndicator()),),
                ),
              ),
            if (_isBreakLoading)
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CircularProgressIndicator()),),
                ),
              ),
          ],
        ),
      ),
    );
  }


  // Helper method to get all activity events from today's attendance
  List<WorkLog> _getAllTodaysActivityEvents() {
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    List<WorkLog> allEvents = [];
    for (var attendance in _todaysPunchEntries) {
      if (attendance.attendanceDate == dateStr && attendance.workLogs != null) {
        allEvents.addAll(attendance.workLogs!);
      }
    }

    // Sort events by time (most recent first for the reversed display)
    allEvents.sort((a, b) {
      // Parse dates for proper sorting
      try {
        final dateA = _getActivityDate(a);
        final dateB = _getActivityDate(b);
        final timeA = DateTime.parse("${dateA}T${a.time}");
        final timeB = DateTime.parse("${dateB}T${b.time}");
        return timeB.compareTo(timeA); // Most recent first
      } catch (e) {
        return (b.time ?? '').compareTo(a.time ?? '');
      }
    });

    return allEvents;
  }

// Helper to get the date for an activity
  String _getActivityDate(WorkLog log) {
    for (var attendance in _todaysPunchEntries) {
      if (attendance.workLogs != null && attendance.workLogs!.contains(log)) {
        return attendance.attendanceDate ?? '';
      }
    }
    return '';
  }

// Helper to get activity color based on type
  Color _getActivityColor(String? type) {
    switch (type) {
      case 'punch_in':
        return Colors.green;
      case 'punch_out':
        return Colors.red;
      case 'break_start':
        return Colors.orange;
      case 'break_end':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getActivityTitle(String? type) {
    switch (type) {
      case 'punch_in':
        return 'Punched In';
      case 'punch_out':
        return 'Punched Out';
      case 'break_start':
        return 'Break Started';
      case 'break_end':
        return 'Break Ended';
      default:
        return 'Activity';
    }
  }
}
