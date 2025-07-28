import 'dart:convert';

import 'package:employee_management/core/configs/strings.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import '../../../core/utils/network_result.dart';
import '../../../core/widgets/debouncing_state.dart';
import '../../data/models/floor/profile_data.dart';
import '../../domain/use_cases/punch_in_out_use_case.dart';
import '../state/profile_controller.dart';
import '../state/punch_controller.dart';
import '../widgets/manual_punch_in_dialog.dart';
import 'app_side_drawer.dart';
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
  bool _isFabExpanded = false;
  List<PunchEntry> _todaysPunchEntries = [];
  String _todaysPunchIn = '--';
  String _todaysPunchOut = '--';
  bool _isPunchLoading = false;
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
    _requestLocationPermission();
    _checkAndResetPunchTimes();
    _loadWorkBreakFromPrefs();
    _startWorkBreakUiTimer();
    _fetchTodaysPunchHistory();
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

  Future<void> _updateWorkedAndBreakTimes() async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final result = await _punchHistoryUseCase(startDate: todayStr, endDate: todayStr, page: 1, pageSize: 1,);

    if (result is NetworkSuccess<PunchHistoryResponse>) {
      final data = result.data.results;
      if (data.isNotEmpty) {
        final entry = data[0];
        String? firstIn = entry.punchIn;
        String? lastOut = entry.punchOut;
        setState(() {
          _workedDuration = _formatApiDuration(entry.totalWorkTime);
          _breakDuration = _formatApiDuration(entry.totalBreakTime);
          _firstPunchIn = firstIn != null && firstIn.isNotEmpty ? _formatTime(firstIn) : '--';
          _lastPunchOut = lastOut != null && lastOut.isNotEmpty ? _formatTime(lastOut) : '--';
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

  Future<void> _fetchTodaysPunchHistory() async {
    setState(() { _isPunchLoading = true; });
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final result = await _punchHistoryUseCase(
      startDate: dateStr,
      endDate: dateStr,
      page: 1,
      pageSize: 1,
    );
    if (result is NetworkSuccess<PunchHistoryResponse>) {
      final entries = result.data.results;
      _todaysPunchEntries = entries;
      if (_todaysPunchEntries.isNotEmpty) {
        final entry = _todaysPunchEntries.first;
        final date = entry.date; // e.g., "2025-07-28"
        final punchInIso = entry.punchIn != null ? "${date}T${entry.punchIn}" : null;
        final punchOutIso = entry.punchOut != null ? "${date}T${entry.punchOut}" : null;
        _workedDuration = _formatApiDuration(entry.totalWorkTime);
        _breakDuration = _formatApiDuration(entry.totalBreakTime);
        _firstPunchIn = punchInIso != null ? _formatTime(punchInIso) : '--';
        _lastPunchOut = punchOutIso != null ? _formatTime(punchOutIso) : '--';
        // Set break button enabled based on punch in/out status
        _isBreakButtonEnabled = entry.punchIn != null && entry.punchOut == null;
        // Determine break state
        if (entry.breaks.isNotEmpty) {
          final lastBreak = entry.breaks.last;
          _isOnBreak = lastBreak.breakStart != null && (lastBreak.breakOver == null || lastBreak.breakOver!.isEmpty);
        } else {
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
    } else {
      _workedDuration = '--';
      _breakDuration = '--';
      _firstPunchIn = '--';
      _lastPunchOut = '--';
      _isBreakButtonEnabled = false;
      _isOnBreak = false;
    }
    setState(() { _isPunchLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: AppSideDrawer(),
      ),
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
                                        // Punch In/Out Button
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
                                                buttonText = AppStrings.punchOut;
                                                buttonIcon = Icons.logout;
                                                buttonColor = Colors.red;
                                                onPressed = () async {
                                                  final confirm = await showPunchConfirmationDialog(context, isPunchOut: true);
                                                  if(!confirm) return;

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
                                                        await _fetchTodaysPunchHistory();
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
                                                        showGlobalSnackBarWithIcon(AppStrings.punchOutSuccess, icon: Icons.logout, iconColor: Colors.red);
                                                        setState(() {
                                                          _isBreakButtonEnabled = false;
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
                                                        await _fetchTodaysPunchHistory();
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
                                                      onPressed: _isBreakButtonEnabled
                                                          ? () async {
                                                        if (!_isOnBreak) {
                                                          // Break In logic
                                                          setState(() { _isBreakLoading = true; });
                                                          final attendanceId = _todaysPunchEntries.isNotEmpty ? _todaysPunchEntries.first.id : null;
                                                          if (attendanceId == null) {
                                                            setState(() { _isBreakLoading = false; });
                                                            showGlobalSnackBarWithIcon('Attendance not found for today', icon: Icons.error, iconColor: Colors.red);
                                                            return;
                                                          }
                                                          final now = DateTime.now();
                                                          final breakStart = now.toIso8601String();
                                                          final breakOver = "";
                                                          final punchInOutUseCase = getIt<PunchInOutUseCase>();
                                                          final result = await punchInOutUseCase.createBreakLog(
                                                            breakStart: breakStart,
                                                            breakOver: breakOver,
                                                            attendanceId: attendanceId,
                                                          );
                                                          setState(() { _isBreakLoading = false; });
                                                          if (result is NetworkSuccess) {
                                                            setState(() { _isOnBreak = ! _isOnBreak; });
                                                            await _fetchTodaysPunchHistory();
                                                            await _updateWorkedAndBreakTimes();
                                                            // Ensure punch in/out times are updated after break events
                                                            if (_todaysPunchEntries.isNotEmpty) {
                                                              final entry = _todaysPunchEntries.first;
                                                              final date = entry.date;
                                                              final punchInIso = entry.punchIn != null ? "${date}T${entry.punchIn}" : null;
                                                              final punchOutIso = entry.punchOut != null ? "${date}T${entry.punchOut}" : null;
                                                              setState(() {
                                                                _firstPunchIn = punchInIso != null ? _formatTime(punchInIso) : '--';
                                                                _lastPunchOut = punchOutIso != null ? _formatTime(punchOutIso) : '--';
                                                              });
                                                            }
                                                            showGlobalSnackBarWithIcon('Break started successfully!', icon: Icons.pause_circle, iconColor: Colors.orange);
                                                          } else {
                                                            showGlobalSnackBarWithIcon('Failed to start break', icon: Icons.error, iconColor: Colors.red);
                                                          }
                                                        } else {
                                                          // Break Out logic
                                                          setState(() { _isBreakLoading = true; });
                                                          final attendanceId = _todaysPunchEntries.isNotEmpty ? _todaysPunchEntries.first.id : null;
                                                          if (attendanceId == null) {
                                                            setState(() { _isBreakLoading = false; });
                                                            showGlobalSnackBarWithIcon('Attendance not found for today', icon: Icons.error, iconColor: Colors.red);
                                                            return;
                                                          }
                                                          final now = DateTime.now();
                                                          final lastBreak = _todaysPunchEntries.first.breaks.lastOrNull;
                                                          if (lastBreak == null) {
                                                            setState(() { _isBreakLoading = false; });
                                                            showGlobalSnackBarWithIcon('No break to end.', icon: Icons.error, iconColor: Colors.red);
                                                            return;
                                                          }
                                                          final breakStart = lastBreak.breakStart != null ? "${_todaysPunchEntries.first.date}T${lastBreak.breakStart}" : null;
                                                          final breakOver = now.toIso8601String();
                                                          final punchInOutUseCase = getIt<PunchInOutUseCase>();
                                                          final result = await punchInOutUseCase.createBreakLog(
                                                            breakStart: breakStart ?? now.toIso8601String(),
                                                            breakOver: breakOver,
                                                            attendanceId: attendanceId,
                                                          );
                                                          setState(() { _isBreakLoading = false; });
                                                          if (result is NetworkSuccess) {
                                                            setState(() { _isOnBreak = ! _isOnBreak; });
                                                            await _fetchTodaysPunchHistory();
                                                            await _updateWorkedAndBreakTimes();
                                                            // Ensure punch in/out times are updated after break events
                                                            if (_todaysPunchEntries.isNotEmpty) {
                                                              final entry = _todaysPunchEntries.first;
                                                              final date = entry.date;
                                                              final punchInIso = entry.punchIn != null ? "${date}T${entry.punchIn}" : null;
                                                              final punchOutIso = entry.punchOut != null ? "${date}T${entry.punchOut}" : null;
                                                              setState(() {
                                                                _firstPunchIn = punchInIso != null ? _formatTime(punchInIso) : '--';
                                                                _lastPunchOut = punchOutIso != null ? _formatTime(punchOutIso) : '--';
                                                              });
                                                            }
                                                            showGlobalSnackBarWithIcon('Break ended successfully!', icon: Icons.play_circle, iconColor: Colors.green);
                                                          } else {
                                                            showGlobalSnackBarWithIcon('Failed to end break', icon: Icons.error, iconColor: Colors.red);
                                                          }
                                                        }
                                                      }
                                                          : null,
                                                      icon: Icon(_isOnBreak ? Icons.play_circle_fill : Icons.pause_circle_outline, size: 22.sp, color: Colors.white),
                                                      label: Text(
                                                        _isOnBreak ? 'Break Out' : 'Break In',
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

                                              /* return ElevatedButton.icon(
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
                                        );*/
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_todaysPunchEntries.isNotEmpty && _todaysPunchEntries.first.breaks.isNotEmpty)
                                  Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    margin: EdgeInsets.only(bottom: 3.h),
                                    color: theme.brightness == Brightness.light ? Colors.white : theme.cardColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Today\'s Break Logs',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
                                          ),
                                          Divider(
                                            height: 24,
                                            thickness: 1.3,
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                          ),
                                          ..._todaysPunchEntries.first.breaks.asMap().entries.map((entry) {
                                            final i = entry.key;
                                            final brk = entry.value;
                                            final parentDate = _todaysPunchEntries.first.date;
                                            final breakStartIso = brk.breakStart != null ? "${parentDate}T${brk.breakStart}" : null;
                                            final breakOverIso = brk.breakOver != null ? "${parentDate}T${brk.breakOver}" : null;
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 14.0, left: 10.0, right: 10.0),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.orange.withOpacity(0.1),
                                                    ),
                                                    child: Icon(Icons.pause_circle_filled, color: Colors.orange, size: 20),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Break In', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                                                      SizedBox(height: 2),
                                                      Text(_formatTime(breakStartIso ?? '') ?? '--:--',
                                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                                    ],
                                                  ),
                                                  Spacer(),
                                                  Container(
                                                    padding: EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.green.withOpacity(0.1),
                                                    ),
                                                    child: Icon(Icons.play_circle_fill, color: Colors.green, size: 20),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Break Out', style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                                                      SizedBox(height: 2),
                                                      Text(_formatTime(breakOverIso ?? '') ?? '--:--',
                                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
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
            if (_isBreakLoading)
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
        showGlobalSnackBarWithIcon(AppStrings.locationPermission);
      }
    }
  }

}

Future<bool> showPunchConfirmationDialog(
    BuildContext context, {
      required bool isPunchOut,
    }) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFF5F7EC),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Confirm ${isPunchOut ? 'Punch Out' : 'Punch In'}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black,),
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to ${isPunchOut ? 'punch out' : 'punch in'}?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.green.shade700, textStyle: const TextStyle(fontSize: 14),),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10,),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ) ?? false;
}
