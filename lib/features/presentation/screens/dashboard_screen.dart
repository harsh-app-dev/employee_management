import 'package:employee_management/core/configs/strings.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:employee_management/features/presentation/state/dashboard_controller.dart';
import 'package:employee_management/features/presentation/state/punch_controller.dart';
import 'package:employee_management/features/presentation/state/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/debouncing_state.dart';
import 'app_side_drawer.dart';

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
  final Debouncer _submitDebouncer = Debouncer(delay: Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _controller = getIt<DashboardController>();
    _punchController = getIt<PunchController>();
    _profileController = getIt<ProfileController>();
    _profileController.fetchAndSaveProfile().then((_) async {
      await _fetchProfileData();
    });
    _requestLocationPermission();
    _loadPunchTimes();
    _controller.fetchTasks();
  }

  Future<void> _loadPunchTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final punchInStr = prefs.getString('punchInTime');
    final punchOutStr = prefs.getString('punchOutTime');
    setState(() {
      _punchInTime = punchInStr != null ? _parseTimeOfDay(punchInStr) : null;
      _punchOutTime = punchOutStr != null ? _parseTimeOfDay(punchOutStr) : null;
    });
  }

  Future<void> _savePunchInTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString('punchInTime', timeStr);
  }

  Future<void> _savePunchOutTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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

  Future<void> _fetchProfileData() async {
    final profiles = await _profileController.profileDao.getAllProfiles();
    final profile = profiles.isNotEmpty ? profiles.first : null;
    if (profile != null) {
      _profileInitials.value = getInitials(profile.first_name, profile.last_name);
    } else {
      _profileInitials.value = '?';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.onPrimary,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.onPrimary),
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
          alignment: Alignment.centerLeft,
          child: Text(AppStrings.dashboard, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary,),),
        ),
        actions: [
        ],
      ),
      drawer: Drawer(
        child: AppSideDrawer(),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
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
                                Text(AppStrings.attendance,
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
                                    Icon(Icons.login, color: Colors.green, size: 22,),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${AppStrings.inText}: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green,),
                                    ),
                                    Text(
                                      _punchInTime != null ? _punchInTime!.format(context) : '--:--',
                                      style: TextStyle(fontWeight: FontWeight.w500,),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 1.w),
                                Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.red, size: 22,),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${AppStrings.out}: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red,),
                                    ),
                                    Text(
                                      _punchOutTime != null ? _punchOutTime!.format(context) : '--:--',
                                      style: TextStyle(fontWeight: FontWeight.w500,),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            // Show only one button at a time based on punch state
                            SizedBox(
                              width: double.infinity,
                              height: 7.h,
                              child: Builder(
                                builder: (context) {
                                  String buttonText;
                                  VoidCallback? onPressed;
                                  Color buttonColor;
                                  IconData buttonIcon;
                                  bool isButtonEnabled = true;

                                  if (_punchInTime == null) {
                                    // Show Punch In
                                    buttonText = AppStrings.punchIn;
                                    buttonIcon = Icons.login;
                                    buttonColor = theme.colorScheme.primary;
                                    onPressed = () {
                                      _submitDebouncer.run(() async {
                                        await _punchController.punchInOut('In');
                                        if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                          final now = TimeOfDay.now();
                                          setState(() {
                                            _punchInTime = now;
                                          });
                                          await _savePunchInTime(now);
                                          showGlobalSnackBar(AppStrings.punchSuccess);
                                        } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                          showGlobalSnackBar(
                                            _punchController.punchInOutApiState.value?.error ?? AppStrings.punchFailed,
                                          );
                                        }
                                      });
                                    };
                                  } else if (_punchOutTime == null) {
                                    // Show Punch Out
                                    buttonText = AppStrings.punchOut;
                                    buttonIcon = Icons.logout;
                                    buttonColor = Colors.red;
                                    onPressed = () {
                                      _submitDebouncer.run(() async {
                                        await _punchController.punchInOut('out');
                                        if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                          final now = TimeOfDay.now();
                                          setState(() {
                                            _punchOutTime = now;
                                          });
                                          await _savePunchOutTime(now);
                                          showGlobalSnackBar(AppStrings.punchSuccess);
                                        } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                          showGlobalSnackBar(
                                            _punchController.punchInOutApiState.value?.error ?? AppStrings.punchFailed,
                                          );
                                        }
                                      });
                                    };
                                  } else {
                                    // Attendance complete
                                    buttonText = 'Attendance Marked';
                                    buttonIcon = Icons.check_circle_outline;
                                    buttonColor = Colors.grey;
                                    isButtonEnabled = false;
                                    onPressed = null;
                                  }

                                  return ElevatedButton.icon(
                                    onPressed: isButtonEnabled ? onPressed : null,
                                    icon: Icon(buttonIcon, size: 24.sp, color: Colors.white),
                                    label: Text(
                                      buttonText,
                                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: buttonColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
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
        showGlobalSnackBar(AppStrings.locationPermission);
      }
    }
  }

}
