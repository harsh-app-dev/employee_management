import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:employee_management/features/presentation/screens/punch_history_screen.dart';
import 'package:employee_management/features/presentation/state/dashboard_controller.dart';
import 'package:employee_management/features/presentation/state/punch_controller.dart';
import 'package:employee_management/features/presentation/state/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_state.dart';
import '../../data/models/tasks/submit/submit_tasks_response.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;
  late final PunchController _punchController;
  late final ProfileController _profileController;
  final ValueNotifier<String> _profileInitials = ValueNotifier('?');
  final ValueNotifier<String> _employeeActive = ValueNotifier('');
  TimeOfDay? _punchInTime;
  TimeOfDay? _punchOutTime;

  @override
  void initState() {
    super.initState();
    _controller = getIt<DashboardController>();
    _punchController = getIt<PunchController>();
    _profileController = getIt<ProfileController>();
    _profileController.fetchAndSaveProfile().then((_) async {
      final state = _profileController.profileApiState.value;

      await _fetchEmployeeActive();
      await _validatePunchTimesByStatus();

      if (state.isSuccess == true) {
        await _fetchProfileInitials();
      }
      });
    _requestLocationPermission();
    _loadPunchTimes();
    _punchController.getPunchState();
    _controller.fetchTasks();
  }

  Future<void> _validatePunchTimesByStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final punchInStr = prefs.getString('punchInTime');
    final punchOutStr = prefs.getString('punchOutTime');
    final status = _employeeActive.value;
    if (status == 'Not Present') {
      await _clearPunchTimes();
    } else if (status == 'Active') {
      if (punchInStr != null) {
        setState(() {
          _punchInTime = _parseTimeOfDay(punchInStr);
        });
      }
      await prefs.remove('punchOutTime');
      setState(() {
        _punchOutTime = null;
      });
    } else if (status == 'Left') {
      setState(() {
        _punchInTime = punchInStr != null ? _parseTimeOfDay(punchInStr) : null;
        _punchOutTime = punchOutStr != null
            ? _parseTimeOfDay(punchOutStr)
            : null;
      });
    }
  }

  Future<void> _loadPunchTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final punchInStr = prefs.getString('punchInTime');
    final punchOutStr = prefs.getString('punchOutTime');
    final status = _employeeActive.value;
    if (status == 'Not Present') {
      setState(() {
        _punchInTime = null;
        _punchOutTime = null;
      });
    } else if (status == 'Active') {
      setState(() {
        _punchInTime = punchInStr != null ? _parseTimeOfDay(punchInStr) : null;
        _punchOutTime = null;
      });
    } else if (status == 'Left') {
      setState(() {
        _punchInTime = punchInStr != null ? _parseTimeOfDay(punchInStr) : null;
        _punchOutTime = punchOutStr != null
            ? _parseTimeOfDay(punchOutStr)
            : null;
      });
    }
  }

  Future<void> _savePunchInTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString('punchInTime', timeStr);
  }

  Future<void> _savePunchOutTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString('punchOutTime', timeStr);
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(":");
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _fetchProfileInitials() async {
    final profiles = await _profileController.profileDao.getAllProfiles();
    final profile = profiles.isNotEmpty ? profiles.first : null;
    if (profile != null) {
      final first = profile.first_name.isNotEmpty ? profile.first_name[0] : '';
      final last = profile.last_name.isNotEmpty ? profile.last_name[0] : '';
      _profileInitials.value = (first + last).toUpperCase();
    } else {
      _profileInitials.value = '?';
    }
  }

  Future<void> _fetchEmployeeActive() async {
    final profiles = await _profileController.profileDao.getAllProfiles();
    final profile = profiles.isNotEmpty ? profiles.first : null;
    if (profile != null) {
      _employeeActive.value = profile.employee_active;
    } else {
      _employeeActive.value = 'Not Present';
    }
  }

  Future<void> _clearPunchTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('punchInTime');
    await prefs.remove('punchOutTime');
    setState(() {
      _punchInTime = null;
      _punchOutTime = null;
    });
  }

  Future<void> _setStateForEmployeeActive(String status) async {
    if (status == 'Not Present') {
      await _clearPunchTimes();
    } else if (status == 'Active') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('punchOutTime');
      setState(() {
        _punchOutTime = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.onPrimary,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.history,
              color: theme.colorScheme.onPrimary,
              size: 5.h,
            ),
            tooltip: 'Punch History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PunchHistoryScreen()),
              );
            },
            splashRadius: 3.h,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          ValueListenableBuilder<String>(
            valueListenable: _profileInitials,
            builder: (context, initials, _) {
              return Padding(
                padding: EdgeInsets.only(top: 1.h, right: 1.h, bottom: 1.h),
                child: GestureDetector(
                  onTap: () {
                    getIt<GlobalKey<NavigatorState>>().currentState?.pushNamed(
                      '/profile',
                    );
                  },
                  child: CircleAvatar(
                    radius: 3.h,
                    backgroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      (initials.isNotEmpty ? initials : '?'),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    margin: EdgeInsets.only(bottom: 3.h),
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : theme.cardColor,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary.withOpacity(
                                        0.7,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 26.sp,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                "Today's Attendance",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 20.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.login,
                                    color: Colors.green,
                                    size: 22,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Punch In: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    _employeeActive.value == 'Not Present'
                                        ? '--:--'
                                        : _punchInTime != null
                                        ? _punchInTime!.format(context)
                                        : '--:--',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Punch Out: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    _employeeActive.value == 'Active' ||
                                            _employeeActive.value ==
                                                'Not Present'
                                        ? '--:--'
                                        : _punchOutTime != null
                                        ? _punchOutTime!.format(context)
                                        : '--:--',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          ValueListenableBuilder<String>(
                            valueListenable: _employeeActive,
                            builder: (context, employeeActive, _) {
                              String buttonText = 'Punch In';
                              VoidCallback? onPressed;
                              Color textColor = Colors.white;
                              IconData buttonIcon = Icons.login;
                              bool isButtonEnabled = true;

                              if (employeeActive == 'Not Present') {
                                buttonText = 'Punch In';
                                buttonIcon = Icons.login;
                                textColor = Colors.white;
                                onPressed = () async {
                                  await _setStateForEmployeeActive(
                                    'Not Present',
                                  );
                                  await _punchController.punchInOut('In');
                                  if (_punchController
                                          .punchInOutApiState
                                          .value
                                          ?.isSuccess ??
                                      false) {
                                    _employeeActive.value = 'Active';
                                    final now = TimeOfDay.now();
                                    setState(() {
                                      _punchInTime = now;
                                    });
                                    await _savePunchInTime(now);
                                    showGlobalSnackBar('Punch In successful!');
                                  } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                    showGlobalSnackBar(_punchController.punchInOutApiState.value?.error ?? 'Punch In failed!',);
                                  }
                                };
                              } else if (employeeActive == 'Active') {
                                buttonText = 'Punch Out';
                                buttonIcon = Icons.logout;
                                textColor = Colors.white;
                                onPressed = () async {
                                  await _setStateForEmployeeActive('Active');
                                  await _punchController.punchInOut('out');
                                  if (_punchController
                                          .punchInOutApiState
                                          .value
                                          ?.isSuccess ??
                                      false) {
                                    _employeeActive.value = 'Left';
                                    final now = TimeOfDay.now();
                                    setState(() {
                                      _punchOutTime = now;
                                    });
                                    await _savePunchOutTime(now);
                                    showGlobalSnackBar('Punch Out successful!');
                                  } else if (_punchController
                                          .punchInOutApiState
                                          .value
                                          ?.isError ??
                                      false) {
                                    showGlobalSnackBar(
                                      _punchController.punchInOutApiState.value?.error ?? 'Punch Out failed!',
                                    );
                                  }
                                };
                              } else if (employeeActive == 'Left') {
                                buttonText = 'Attendance Marked';
                                buttonIcon = Icons.check_circle_outline;
                                textColor = Colors.black;
                                isButtonEnabled = false;
                                onPressed = () {
                                  showGlobalSnackBar('You have already punched in and out today. Please try again tomorrow',);
                                };
                              }

                              return SizedBox(
                                width: double.infinity,
                                height: 7.h,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: (employeeActive == 'Not Present')
                                        ? LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.primary
                                                  .withOpacity(0.7),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : (employeeActive == 'Active')
                                        ? LinearGradient(
                                            colors: [
                                              Colors.red,
                                              Colors.redAccent,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.grey.shade400,
                                              Colors.grey.shade300,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: isButtonEnabled
                                        ? onPressed
                                        : null,
                                    icon: Icon(
                                      buttonIcon,
                                      size: 20.sp,
                                      color: textColor,
                                    ),
                                    label: Text(
                                      buttonText,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Padding(
                    padding: EdgeInsets.only(bottom: 1.5.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Task Overview',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _controller.tasksApiState,
                    builder: (context, apiState, _) {
                      if (apiState.isLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else if (apiState.isError) {
                        return Center(
                          child: Text(apiState.error ?? 'Failed to load tasks'),
                        );
                      } else if (apiState.isSuccess &&
                          apiState.data?.data != null &&
                          apiState.data!.data!.isNotEmpty) {
                        final tasks = apiState.data!.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: tasks.length,
                          itemBuilder: (context, taskIndex) {
                            final task = tasks[taskIndex];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 2.h),
                              child: Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                margin: EdgeInsets.zero,
                                color: theme.brightness == Brightness.light
                                    ? Colors.white
                                    : theme.cardColor,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5.w,
                                    vertical: 3.h,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.confirmation_number,
                                            color: theme.colorScheme.primary,
                                            size: 28,
                                          ),
                                          SizedBox(width: 2.w),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                task.ticket?.title ??
                                                    task.ticketTitle ??
                                                    '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              if (task.ticketId != null)
                                                Text(
                                                  'Ticket ID: ${task.ticketId}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Spacer(),
                                          TextButton(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          30,
                                                        ),
                                                      ),
                                                ),
                                                backgroundColor:
                                                    theme.cardColor,
                                                builder: (context) {
                                                  return DraggableScrollableSheet(
                                                    expand: false,
                                                    initialChildSize: 0.5,
                                                    minChildSize: 0.3,
                                                    maxChildSize: 0.95,
                                                    builder: (context, scrollController) {
                                                      return Padding(
                                                        padding: EdgeInsets.only(
                                                          left: 5.w,
                                                          right: 5.w,
                                                          top: 3.h,
                                                          bottom:
                                                              MediaQuery.of(
                                                                    context,
                                                                  )
                                                                  .viewInsets
                                                                  .bottom +
                                                              16,
                                                        ),
                                                        child: SingleChildScrollView(
                                                          controller:
                                                              scrollController,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .assignment,
                                                                    color: theme
                                                                        .colorScheme
                                                                        .primary,
                                                                    size: 28,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 2.w,
                                                                  ),
                                                                  Text(
                                                                    'Task Details',
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          20,
                                                                      letterSpacing:
                                                                          0.5,
                                                                    ),
                                                                  ),
                                                                  Spacer(),
                                                                  IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .close,
                                                                      color: theme
                                                                          .colorScheme
                                                                          .primary,
                                                                    ),
                                                                    onPressed: () =>
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop(),
                                                                  ),
                                                                ],
                                                              ),
                                                              Divider(
                                                                height: 3.h,
                                                                thickness: 1.3,
                                                                color: theme
                                                                    .colorScheme
                                                                    .primary
                                                                    .withOpacity(
                                                                      0.15,
                                                                    ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          1.2.h,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .work,
                                                                      color: theme
                                                                          .colorScheme
                                                                          .primary,
                                                                      size: 22,
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Text(
                                                                      'Project:',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .primary,
                                                                        fontSize:
                                                                            17,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        task.ticket?.project?.title ??
                                                                            task.projectTitle ??
                                                                            '',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                          color: theme
                                                                              .colorScheme
                                                                              .onSurface,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          1.2.h,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .confirmation_number,
                                                                      color: theme
                                                                          .colorScheme
                                                                          .primary,
                                                                      size: 22,
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Text(
                                                                      'Ticket Title:',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .primary,
                                                                        fontSize:
                                                                            17,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        task.ticket?.title ??
                                                                            task.ticketTitle ??
                                                                            '',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                          color: theme
                                                                              .colorScheme
                                                                              .onSurface,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          1.2.h,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .confirmation_number_outlined,
                                                                      color: theme
                                                                          .colorScheme
                                                                          .primary,
                                                                      size: 22,
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Text(
                                                                      'Ticket ID:',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .primary,
                                                                        fontSize:
                                                                            17,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        task.ticketId !=
                                                                                null
                                                                            ? task.ticketId.toString()
                                                                            : '-',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                          color: theme
                                                                              .colorScheme
                                                                              .onSurface,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          1.2.h,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .layers,
                                                                      color: theme
                                                                          .colorScheme
                                                                          .primary,
                                                                      size: 22,
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Text(
                                                                      'Phase:',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .primary,
                                                                        fontSize:
                                                                            17,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        task.taskPhase ??
                                                                            '',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                          color: theme
                                                                              .colorScheme
                                                                              .onSurface,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          1.2.h,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .calendar_today,
                                                                      color: theme
                                                                          .colorScheme
                                                                          .primary,
                                                                      size: 22,
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Text(
                                                                      'Date:',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .primary,
                                                                        fontSize:
                                                                            17,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Text(
                                                                      task.createdAt?.substring(
                                                                            0,
                                                                            10,
                                                                          ) ??
                                                                          task.taskCreatedDate ??
                                                                          '',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            15,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .onSurface,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          3.w,
                                                                    ),
                                                                    Icon(
                                                                      Icons
                                                                          .access_time,
                                                                      color: theme
                                                                          .colorScheme
                                                                          .primary,
                                                                      size: 22,
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Text(
                                                                      'Time:',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .primary,
                                                                        fontSize:
                                                                            17,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          2.w,
                                                                    ),
                                                                    Text(
                                                                      task.taskTimeSpend ??
                                                                          '',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            15,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .onSurface,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          1.2.h,
                                                                    ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      'Description:',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .primary,
                                                                        fontSize:
                                                                            17,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          0.5.h,
                                                                    ),
                                                                    Text(
                                                                      (task.taskDescription ??
                                                                              '')
                                                                          .replaceAll(
                                                                            RegExp(
                                                                              r'<[^>]*>|&[^;]+;',
                                                                            ),
                                                                            '',
                                                                          ),
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            15,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .onSurface,
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                            child: Row(
                                              children: [
                                                Text(
                                                  'View All',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.expand_more,
                                                  color:
                                                      theme.colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        height: 3.h,
                                        thickness: 1.3,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.15),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 1.2.h,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.work,
                                              color: theme.colorScheme.primary,
                                              size: 22,
                                            ),
                                            SizedBox(width: 2.w),
                                            Text(
                                              'Project:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                                fontSize: 17,
                                              ),
                                            ),
                                            SizedBox(width: 2.w),
                                            Expanded(
                                              child: Text(
                                                task.ticket?.project?.title ??
                                                    task.projectTitle ??
                                                    '',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 1.2.h,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: theme.colorScheme.primary,
                                              size: 22,
                                            ),
                                            SizedBox(width: 2.w),
                                            Text(
                                              'Date:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                                fontSize: 17,
                                              ),
                                            ),
                                            SizedBox(width: 2.w),
                                            Text(
                                              task.createdAt?.substring(
                                                    0,
                                                    10,
                                                  ) ??
                                                  task.taskCreatedDate ??
                                                  '',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            SizedBox(width: 3.w),
                                            Icon(
                                              Icons.access_time,
                                              color: theme.colorScheme.primary,
                                              size: 22,
                                            ),
                                            SizedBox(width: 2.w),
                                            Text(
                                              'Time:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                                fontSize: 17,
                                              ),
                                            ),
                                            SizedBox(width: 2.w),
                                            Text(
                                              task.taskTimeSpend ?? '',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return Center(
                          child: SizedBox(
                            height: 40.h,
                            child: Center(
                              child: Text(
                                'No task found.',
                                style: TextStyle(fontSize: 20.sp),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _punchController.punchInOutApiState,
            builder: (context, punchInOutState, _) {
              final isLoading = punchInOutState?.isLoading ?? false;
              if (isLoading) {
                return Container(
                  color: Colors.black.withOpacity(0.2),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<ApiState<SubmitTasksResponse>>(
        valueListenable: _controller.submitTasksApiState,
        builder: (context, submitState, _) {
          final isLoading = submitState.isLoading;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                FloatingActionButton.extended(
                  onPressed: isLoading
                      ? null
                      : () async {
                    final tasks = _controller.tasksApiState.value.data;
                    if (tasks != null && tasks.data != null && tasks.data!.isNotEmpty) {
                      await _controller.submitTasks(tasks);
                      if (_controller.submitTasksApiState.value.isSuccess) {
                        showGlobalSnackBar('All tasks submitted successfully');
                      } else if (_controller.submitTasksApiState.value.isError) {
                        showGlobalSnackBar(_controller.submitTasksApiState.value.error ?? 'Failed to submit tasks');
                      }
                    } else {
                      showGlobalSnackBar('You have no pending tasks to submit');
                    }
                  },
                  label: Text(
                    isLoading ? 'Submitting...' : 'Submit',
                    style: TextStyle(
                      color: isLoading ? Colors.transparent : theme.colorScheme.surface,
                      fontSize: 14.sp,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                if (isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        showGlobalSnackBar('Location permission is required.');
      }
    }
  }
}
