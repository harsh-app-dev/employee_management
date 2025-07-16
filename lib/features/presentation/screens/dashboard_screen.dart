import 'package:employee_management/core/configs/strings.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:employee_management/features/presentation/state/punch_controller.dart';
import 'package:employee_management/features/presentation/state/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../../../core/utils/network_result.dart';
import '../../../core/widgets/debouncing_state.dart';
import '../../data/models/floor/profile_data.dart';
import 'app_side_drawer.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:intl/intl.dart';

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
  String? _lastPunchType; // 'in' or 'out'
  DateTime? _lastPunchTime;
  bool _isApiLoading = false;
  String _workedDuration = '--';
  String _breakDuration = '--';
  String _firstPunchIn = '--';
  String _lastPunchOut = '--';
  final PunchHistoryUseCase _punchHistoryUseCase = getIt<PunchHistoryUseCase>();

  @override
  void initState() {
    super.initState();
    _punchController = getIt<PunchController>();
    _profileController = getIt<ProfileController>();
    _profileController.fetchAndSaveProfile().then((_) async {
      await _fetchProfileData();
    });
    _requestLocationPermission();
    _checkAndResetPunchTimes();
    _loadWorkBreakFromPrefs();
    _startWorkBreakUiTimer();
    _updateWorkedAndBreakTimes();
    // _controller.fetchTasks();
  }

  @override
  void dispose() {
    _workBreakTimer?.cancel();
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
      setState(() {
      });
    } else {
      await _loadPunchTimes();
    }
  }

  Future<void> _loadPunchTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final punchInStr = prefs.getString('punchInTime');
    final punchOutStr = prefs.getString('punchOutTime');
    setState(() {
    });
  }

  Future<void> _savePunchInTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString('punchInTime', timeStr);
    await prefs.setString('lastPunchDate', DateTime.now().toIso8601String());
  }

  Future<void> _savePunchOutTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString('punchOutTime', timeStr);
    await prefs.setString('lastPunchDate', DateTime.now().toIso8601String());
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
      setState(() {}); // Only triggers UI update, does not increment stored seconds
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
      // User is punching out, add to workedSeconds
      final session = now.difference(_lastPunchTime!).inSeconds;
      _workedSeconds += session;
      _lastPunchType = 'out';
      _lastPunchTime = now;
    } else if (punchType == 'in') {
      // User is punching in, add to breakSeconds
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

  Future<void> _updateWorkedAndBreakTimes() async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final result = await _punchHistoryUseCase(
      startDate: todayStr,
      endDate: todayStr,
      page: 1,
      pageSize: 1,
    );
    if (result is NetworkSuccess<List<PunchHistoryResponse>>) {
      final data = result.data;
      if (data.isNotEmpty) {
        final punches = data[0].punches;
        // Find first punch in and last punch out
        String? firstIn;
        String? lastOut;
        for (final punch in punches) {
          if (firstIn == null && punch.punchIn != null && punch.punchIn!.isNotEmpty) {
            firstIn = punch.punchIn;
          }
          if (punch.punchOut != null && punch.punchOut!.isNotEmpty) {
            lastOut = punch.punchOut;
          }
        }
        setState(() {
          _workedDuration = _formatApiDuration(data[0].totalWorkTime);
          _breakDuration = _formatApiDuration(data[0].totalBreakTime);
          _firstPunchIn = firstIn != null ? _formatTime(firstIn) : '--';
          _lastPunchOut = lastOut != null ? _formatTime(lastOut) : '--';
        });
      } else {
        setState(() {
          _workedDuration = '--';
          _breakDuration = '--';
          _firstPunchIn = '--';
          _lastPunchOut = '--';
        });
      }
    } else {
      setState(() {
        _workedDuration = '--';
        _breakDuration = '--';
        _firstPunchIn = '--';
        _lastPunchOut = '--';
      });
    }
  }

  String _formatApiDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return '--';
    try {
      final parts = durationStr.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      String result = '';
      if (hours > 0) result += '${hours}h ';
      if (minutes > 0) result += '${minutes}m ';
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

  int get displayedWorkedSeconds {
    if (_lastPunchType == 'in' && _lastPunchTime != null) {
      return _workedSeconds + DateTime.now().difference(_lastPunchTime!).inSeconds;
    }
    return _workedSeconds;
  }

  int get displayedBreakSeconds {
    if (_lastPunchType == 'out' && _lastPunchTime != null) {
      return _breakSeconds + DateTime.now().difference(_lastPunchTime!).inSeconds;
    }
    return _breakSeconds;
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer, color: theme.colorScheme.primary, size: 20),
                                    SizedBox(width: 1.w),
                                    Text('Worked: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(_workedDuration, style: TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                SizedBox(width: 4.w),
                                Row(
                                  children: [
                                    Icon(Icons.pause_circle_filled, color: Colors.orange, size: 20),
                                    SizedBox(width: 1.w),
                                    Text('Break: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(_breakDuration, style: TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            // Show only one button at a time based on is_active
                            SizedBox(
                              width: double.infinity,
                              height: 7.h,
                              child: Builder(
                                builder: (context) {
                                  String buttonText;
                                  VoidCallback? onPressed;
                                  Color buttonColor;
                                  IconData buttonIcon;

                                  final isActive = _currentProfile?.is_active == 'true';

                                  if (isActive) {
                                    // Show Punch Out
                                    buttonText = AppStrings.punchOut;
                                    buttonIcon = Icons.logout;
                                    buttonColor = Colors.red;
                                    onPressed = () async {
                                      final XFile? image = await _picker.pickImage(
                                        source: ImageSource.camera,
                                        preferredCameraDevice: CameraDevice.front,
                                      );
                                      if (image != null) {
                                        setState(() { _selfieImage = File(image.path); _isApiLoading = true; });
                                        await _submitDebouncer.run(() async {
                                          await _punchController.punchInOut('out', punchPhoto: _selfieImage);
                                          if (!mounted) return;
                                          if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                            final now = TimeOfDay.now();
                                            if (!mounted) return;
                                            setState(() {
                                              _isApiLoading = false;
                                            });
                                            await _savePunchOutTime(now);
                                            _updateWorkBreakOnPunch('out');
                                            await _updateWorkedAndBreakTimes();
                                            // Update is_active to false in DB
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
                                                is_active: 'false',
                                              );
                                              await _profileController.profileDao.insertProfile(updated);
                                              setState(() {
                                                _currentProfile = updated;
                                              });
                                            }
                                            showGlobalSnackBar(AppStrings.punchOutSuccess);
                                          } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                            if (!mounted) return;
                                            setState(() { _isApiLoading = false; });
                                            showGlobalSnackBar(
                                              _punchController.punchInOutApiState.value?.error ?? AppStrings.punchFailed,
                                            );
                                          } else {
                                            if (!mounted) return;
                                            setState(() { _isApiLoading = false; });
                                          }
                                        });
                                      } else {
                                        showGlobalSnackBar('Please take a selfie to proceed.');
                                      }
                                    };
                                  } else {
                                    // Show Punch In
                                    buttonText = AppStrings.punchIn;
                                    buttonIcon = Icons.login;
                                    buttonColor = theme.colorScheme.primary;
                                    onPressed = () async {
                                      final XFile? image = await _picker.pickImage(
                                        source: ImageSource.camera,
                                        preferredCameraDevice: CameraDevice.front,
                                      );
                                      if (image != null) {
                                        setState(() { _selfieImage = File(image.path); _isApiLoading = true; });
                                        await _submitDebouncer.run(() async {
                                          await _punchController.punchInOut('In', punchPhoto: _selfieImage);
                                          if (!mounted) return;
                                          if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                            final now = TimeOfDay.now();
                                            if (!mounted) return;
                                            setState(() {
                                              _isApiLoading = false;
                                            });
                                            await _savePunchInTime(now);
                                            _updateWorkBreakOnPunch('in');
                                            await _updateWorkedAndBreakTimes();
                                            // Update is_active to true in DB
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
                                                is_active: 'true',
                                              );
                                              await _profileController.profileDao.insertProfile(updated);
                                              setState(() {
                                                _currentProfile = updated;
                                              });
                                            }
                                            showGlobalSnackBar(AppStrings.punchInSuccess);
                                          } else if (_punchController.punchInOutApiState.value?.isError ?? false) {
                                            if (!mounted) return;
                                            setState(() { _isApiLoading = false; });
                                            showGlobalSnackBar(
                                              _punchController.punchInOutApiState.value?.error ?? AppStrings.punchFailed,
                                            );
                                          } else {
                                            if (!mounted) return;
                                            setState(() { _isApiLoading = false; });
                                          }
                                        });
                                      } else {
                                        showGlobalSnackBar('Please take a selfie to proceed.');
                                      }
                                    };
                                  }

                                  return ElevatedButton.icon(
                                    onPressed: onPressed,
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
            if (_isApiLoading)
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
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
