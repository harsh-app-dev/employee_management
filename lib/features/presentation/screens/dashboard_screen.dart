import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:employee_management/features/presentation/screens/punch_history_screen.dart';
import 'package:employee_management/features/presentation/state/dashboard_controller.dart';
import 'package:employee_management/features/presentation/state/punch_controller.dart';
import 'package:employee_management/features/presentation/state/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collection/collection.dart';

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
  TimeOfDay? _punchInTime;
  TimeOfDay? _punchOutTime;

  @override
  void initState() {
    super.initState();
    _controller = getIt<DashboardController>();
    _punchController = getIt<PunchController>();
    _profileController = getIt<ProfileController>();
    _profileController.fetchAndSaveProfile();
    _fetchProfileInitials();
    _requestLocationPermission(); // 👈 Ask location

    _punchController.getPunchState();
    _controller.fetchTasks();
  }

  Future<void> _fetchProfileInitials() async {
    // Use a String id instead of int (e.g., get the latest profile or use a stored id)
    // For now, fetch the first profile in the table
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

  void _setPunchInTime() {
    final now = TimeOfDay.now();
    setState(() {
      _punchInTime = now;
    });
  }

  void _setPunchOutTime() {
    final now = TimeOfDay.now();
    setState(() {
      _punchOutTime = now;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dummy tasks list for demonstration (replace with API data in production)
    final List<Map<String, dynamic>> tasks = [
      {
        'client': 'Acme Corp',
        'project': 'Mobile App',
        'ticket': 'AD-134',
        'date': '01/07/2025',
        'time': '3h 10min',
        'phase': 'Development',
        'description':
        'Implement login, dashboard, and punch features. Integrate API and handle state management for user attendance.',
      },
      {
        'client': 'Beta Ltd',
        'project': 'Web Portal',
        'ticket': 'AD-137',
        'date': '01/07/2025',
        'time': '1h 15min',
        'phase': 'Testing',
        'description':
        'Write unit tests and perform bug fixes for the portal.',
      },
      {
        'client': 'Gamma Inc',
        'project': 'API Backend',
        'ticket': 'AD-140',
        'date': '01/07/2025',
        'time': '2h 45m',
        'phase': 'Deployment',
        'description':
        'Deploy backend services and monitor logs. Optimize database queries.',
      },
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.onPrimary, // Set background color
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
                  // Punch In/Out Button - Modern Card Style
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
                          // Attendance Title Row
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.calendar_today, color: Colors.white, size: 26.sp),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                "Today's Attendance",
                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 24.sp),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          // Punch In/Out Time Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.login, color: Colors.green, size: 22),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Punch In: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                  Text(
                                    _punchInTime != null
                                        ? _punchInTime!.format(context)
                                        : '--:--',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red, size: 22),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Punch Out: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                  ),
                                  Text(
                                    _punchOutTime != null
                                        ? _punchOutTime!.format(context)
                                        : '--:--',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          ValueListenableBuilder(
                            valueListenable:
                            _punchController.punchStateApiState,
                            builder: (context, punchState, _) {
                              final isLoading = punchState?.isLoading ?? false;
                              final isPunchedIn =
                                  _punchController.isPunchedIn.value;
                              final isPunchedOut =
                                  _punchController.isPunchedOut.value;
                              String buttonText = 'Punch In';
                              VoidCallback? onPressed;
                              Color buttonColor = theme.colorScheme.primary;
                              Color textColor = Colors.white;
                              IconData buttonIcon = Icons.login;
                              List<Color> gradientColors = [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)];

                              if (!isPunchedIn && !isPunchedOut && !isLoading) {
                                buttonText = 'Punch In';
                                buttonIcon = Icons.login;
                                buttonColor = theme.colorScheme.primary;
                                textColor = Colors.white;
                                gradientColors = [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)];
                                onPressed = () async {
                                  await _punchController.punchInOut('In');
                                  _setPunchInTime();
                                  if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                    showGlobalSnackBar('Punch In successful!');
                                  } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                    showGlobalSnackBar(
                                      _punchController.punchInOutApiState.value?.error ?? 'Punch In failed!',
                                    );
                                  }
                                };
                              } else if (isPunchedIn &&
                                  !isPunchedOut &&
                                  !isLoading) {
                                buttonText = 'Punch Out';
                                buttonIcon = Icons.logout;
                                buttonColor = Colors.red;
                                textColor = Colors.white;
                                gradientColors = [Colors.red, Colors.redAccent];
                                onPressed = () async {
                                  await _punchController.punchInOut('out');
                                  _setPunchOutTime();
                                  if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                    showGlobalSnackBar('Punch Out successful!');
                                  } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                    showGlobalSnackBar(
                                      _punchController.punchInOutApiState.value?.error ?? 'Punch Out failed!',
                                    );
                                  }
                                };
                              } else {
                                buttonText = 'Punch In';
                                buttonIcon = Icons.login;
                                buttonColor = Colors.grey.shade400;
                                textColor = Colors.black;
                                gradientColors = [Colors.grey.shade400, Colors.grey.shade300];
                                onPressed = () async {
                                  showGlobalSnackBar(
                                    _punchController.punchInOutApiState.value?.error ??
                                        ' You have already punched in and out today. Please try again tomorrow',
                                  );
                                };
                              }

                              return SizedBox(
                                width: double.infinity,
                                height: 7.h,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: onPressed,
                                    icon: isLoading
                                        ? SizedBox(
                                      width: 3.5.h,
                                      height: 3.5.h,
                                      child:
                                      const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : Icon(
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
                  // Task Overview Title
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
                  // Task List with Multiple Cards
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, taskIndex) {
                      final task = tasks[taskIndex];
                      final mainInfo = [
                        {
                          'icon': Icons.business,
                          'label': 'Client',
                          'value': task['client'],
                        },
                        {
                          'icon': Icons.work,
                          'label': 'Project',
                          'value': task['project'],
                        },
                        // Combine Date and Time in one row
                        {
                          'icon': Icons.calendar_today,
                          'label': 'Date & Time',
                          'value': '${task['date']}  |  ${task['time']}',
                        },
                      ];
                      final allInfo = [
                        {
                          'icon': Icons.business,
                          'label': 'Client',
                          'value': task['client'],
                        },
                        {
                          'icon': Icons.work,
                          'label': 'Project',
                          'value': task['project'],
                        },
                        {
                          'icon': Icons.airplane_ticket,
                          'label': 'Ticket',
                          'value': task['ticket'],
                        },
                        {
                          'icon': Icons.access_time,
                          'label': 'Time',
                          'value': task['time'],
                        },
                        {
                          'icon': Icons.layers,
                          'label': 'Phase',
                          'value': task['phase'],
                        },
                        {
                          'icon': Icons.attach_money,
                          'label': 'Description',
                          'value': task['description'],
                        },
                      ];
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.confirmation_number,
                                      color: theme.colorScheme.primary,
                                      size: 28,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      task['ticket'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                          ),
                                          backgroundColor: theme.cardColor,
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
                                                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                                                    ),
                                                    child: SingleChildScrollView(
                                                      controller: scrollController,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.assignment,
                                                                color: theme.colorScheme.primary,
                                                                size: 28,
                                                              ),
                                                              SizedBox(width: 2.w),
                                                              Text(
                                                                'Task Details',
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 20,
                                                                  letterSpacing: 0.5,
                                                                ),
                                                              ),
                                                              Spacer(),
                                                              IconButton(
                                                                icon: Icon(
                                                                  Icons.close,
                                                                  color: theme.colorScheme.primary,
                                                                ),
                                                                onPressed: () => Navigator.of(context).pop(),
                                                              ),
                                                            ],
                                                          ),
                                                          Divider(
                                                            height: 3.h,
                                                            thickness: 1.3,
                                                            color: theme.colorScheme.primary.withOpacity(0.15),
                                                          ),
                                                          ...allInfo.map(
                                                                (info) {
                                                              if (info['label'] == 'Description') {
                                                                return Padding(
                                                                  padding: EdgeInsets.symmetric(vertical: 1.2.h),
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                        'Description:',
                                                                        style: TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          color: theme.colorScheme.primary,
                                                                          fontSize: 17,
                                                                        ),
                                                                      ),
                                                                      SizedBox(height: 0.5.h),
                                                                      Text(
                                                                        info['value'] ?? '',
                                                                        style: TextStyle(
                                                                          fontSize: 15,
                                                                          color: theme.colorScheme.onSurface,
                                                                          fontWeight: FontWeight.normal,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              } else if (info['label'] == 'Phase') {
                                                                // Phase and Time in one line
                                                                final timeInfo = allInfo.firstWhereOrNull((i) => i['label'] == 'Time');
                                                                if (timeInfo != null) {
                                                                  return Padding(
                                                                    padding: EdgeInsets.symmetric(vertical: 1.2.h),
                                                                    child: Row(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          'Phase:',
                                                                          style: TextStyle(
                                                                            fontWeight: FontWeight.bold,
                                                                            color: theme.colorScheme.primary,
                                                                            fontSize: 17,
                                                                          ),
                                                                        ),
                                                                        SizedBox(width: 2.w),
                                                                        Text(
                                                                          info['value'] ?? '',
                                                                          style: TextStyle(
                                                                            fontSize: 15,
                                                                            color: theme.colorScheme.onSurface,
                                                                            fontWeight: FontWeight.normal,
                                                                          ),
                                                                        ),
                                                                        SizedBox(width: 4.w),
                                                                        Text(
                                                                          'Time:',
                                                                          style: TextStyle(
                                                                            fontWeight: FontWeight.bold,
                                                                            color: theme.colorScheme.primary,
                                                                            fontSize: 17,
                                                                          ),
                                                                        ),
                                                                        SizedBox(width: 2.w),
                                                                        Text(
                                                                          timeInfo['value'] ?? '',
                                                                          style: TextStyle(
                                                                            fontSize: 15,
                                                                            color: theme.colorScheme.onSurface,
                                                                            fontWeight: FontWeight.normal,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                } else {
                                                                  return SizedBox.shrink();
                                                                }
                                                              } else if (info['label'] == 'Time') {
                                                                // Skip rendering Time separately
                                                                return SizedBox.shrink();
                                                              }
                                                              // Default rendering for other fields
                                                              return Padding(
                                                                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                                                                child: Row(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      info['label'] + ':',
                                                                      style: TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        color: theme.colorScheme.primary,
                                                                        fontSize: 17,
                                                                      ),
                                                                    ),
                                                                    SizedBox(width: 2.w),
                                                                    Expanded(
                                                                      child: Text(
                                                                        info['value'] ?? '',
                                                                        style: TextStyle(
                                                                          fontSize: 15,
                                                                          color: theme.colorScheme.onSurface,
                                                                          fontWeight: FontWeight.normal,
                                                                        ),
                                                                        overflow: TextOverflow.visible,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ).toList(),
                                                        ],
                                                      ),
                                                    )
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
                                                color: theme.colorScheme.primary,
                                                fontSize: 16
                                            ),
                                          ),
                                          Icon(
                                            Icons.expand_more,
                                            color: theme.colorScheme.primary,
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
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.15,
                                  ),
                                ),
                                ...mainInfo.take(2).map(
                                      (info) => Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 1.2.h,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          info['icon'] as IconData,
                                          color: theme.colorScheme.primary,
                                          size: 22,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          info['label'] + ':',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            fontSize: 17,
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Expanded(
                                          child: Text(
                                            info['value'] ?? '',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color:
                                              theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Date & Time in one line
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 1.2.h,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          color: theme.colorScheme.primary,
                                          fontSize: 17,
                                        ),
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        task['date'],
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.normal,
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
                                          color: theme.colorScheme.primary,
                                          fontSize: 17,
                                        ),
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        task['time'],
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.normal,
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
                  ),
                ],
              ),
            ),
          ),
          // Loader overlay for punch in/out API
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
      floatingActionButton: Container(
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
        child: FloatingActionButton.extended(
          onPressed: () {
            showGlobalSnackBar('All tasks are submitted successfully');
          },
          icon: Icon(Icons.send, color: theme.colorScheme.surface, size: 18.sp,),
          label: Text('Submit', style: TextStyle(color: theme.colorScheme.surface, fontSize: 14.sp),),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
