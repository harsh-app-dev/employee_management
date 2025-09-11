import 'dart:io';
import 'dart:async';
import 'package:employee_management/core/configs/strings.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';
import '../../../core/utils/network_result.dart';
import '../../../core/widgets/debouncing_state.dart';
import '../../data/models/floor/profile_data.dart';
import '../../domain/use_cases/punch_in_out_use_case.dart';
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
  List<PunchEntry> _todaysPunchEntries = [];
  bool _isBreakButtonEnabled = false;
  bool _isOnBreak = false;
  bool _isBreakLoading = false;

  // Timer related variables
  Timer? _workingTimer;
  Duration _workingDuration = Duration.zero;
  DateTime? _punchInTime;

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
    _loadPunchInTime();

   /* WidgetsBinding.instance.addPostFrameCallback((_) {
      showAnnouncementDialog(
        context,
        announcementText:  "Your company has assigned you to work from home. "
            "Please read the following terms carefully before giving your consent.\n\n"
            "1. You will comply with all company policies while working remotely.\n"
            "2. Ensure secure handling of company data.\n"
            "3. Your working hours will remain as per company norms.\n"
            "4. The company can revoke remote work privileges at any time.\n\n"
            "By checking the box below, you confirm that you have read and understood "
            "the Work From Home policy and agree to follow it.",
      );
    });*/
  }

  @override
  void dispose() {
    _workBreakTimer?.cancel();
    _workingTimer?.cancel();
    super.dispose();
  }

  // Timer related methods
  void _startWorkingTimer() {
    _workingTimer?.cancel();
    _workingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_punchInTime != null) {
        setState(() {
          _workingDuration = DateTime.now().difference(_punchInTime!);
        });
      }
    });
  }

  void _stopWorkingTimer() {
    _workingTimer?.cancel();
    _workingTimer = null;
  }

  Future<void> _loadPunchInTime() async {
    final prefs = await SharedPreferences.getInstance();
    final punchInTimeStr = prefs.getString('punchInTime');
    if (punchInTimeStr != null) {
      setState(() {
        _punchInTime = DateTime.parse(punchInTimeStr);
        _workingDuration = DateTime.now().difference(_punchInTime!);
        _startWorkingTimer();
      });
    }
  }

  Future<void> _savePunchInTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_punchInTime != null) {
      await prefs.setString('punchInTime', _punchInTime!.toIso8601String());
    } else {
      await prefs.remove('punchInTime');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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
        _punchInTime = null;
        _workingDuration = Duration.zero;
        _stopWorkingTimer();
      });
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
      // Remove milliseconds if present (anything after a decimal point in the seconds part)
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
    setState(() { });
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
        final date = entry.date;
        final punchInIso = entry.punchIn != null ? "${date}T${entry.punchIn}" : null;
        final punchOutIso = entry.punchOut != null ? "${date}T${entry.punchOut}" : null;
        _workedDuration = _formatApiDuration(entry.totalWorkTime)!;
        _breakDuration = _formatApiDuration(entry.totalBreakTime)!;
        _firstPunchIn = punchInIso != null ? _formatTime(punchInIso) : '--';
        _lastPunchOut = punchOutIso != null ? _formatTime(punchOutIso) : '--';
        _isBreakButtonEnabled = entry.punchIn != null && entry.punchOut == null;
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
    setState(() { });
  }

  Future<void> _refreshPunchHistoryAndWorkedTimes() async {
    setState(() { });
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
        final date = entry.date;
        final punchInIso = entry.punchIn != null ? "${date}T${entry.punchIn}" : null;
        final punchOutIso = entry.punchOut != null ? "${date}T${entry.punchOut}" : null;
        _workedDuration = _formatApiDuration(entry.totalWorkTime)!;
        _breakDuration = _formatApiDuration(entry.totalBreakTime)!;
        _firstPunchIn = punchInIso != null ? _formatTime(punchInIso) : '--';
        _lastPunchOut = punchOutIso != null ? _formatTime(punchOutIso) : '--';
        _isBreakButtonEnabled = entry.punchIn != null && entry.punchOut == null;
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
    setState(() { });
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
                                            // Worked Hours Box
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
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                  Text(
                                                    (_workedDuration != '--' && _workedDuration.isNotEmpty)
                                                        ? _workedDuration
                                                        : (_punchInTime != null
                                                        ? _formatDuration(_workingDuration)
                                                        : '00:00:00'),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16.sp,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 1.h),

                                            // Break Hours Box
                                            Container(
                                              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.pause_circle_filled, color: Colors.orange),
                                                  SizedBox(width: 2.w),
                                                  Text(
                                                    '${AppStrings.breakHrs}: ',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                  Text(
                                                    _breakDuration != '--' ? _breakDuration : '00:00:00',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16.sp,
                                                      color: Colors.orange,
                                                    ),
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
                                              final isAbsent = _currentProfile?.is_active == 'absent';
                                              final isLeft = _currentProfile?.is_active == 'left';

                                              if (isAbsent) {
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
                                                      await _punchController.punchInOut('In', punchPhoto: _selfieImage);
                                                      if (!mounted) return;
                                                      if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                                        setState(() {
                                                          _isApiLoading = false;
                                                          _punchInTime = DateTime.now();
                                                          _startWorkingTimer();
                                                          _savePunchInTime();
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
                                              } else if (isActive) {
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
                                                      await _punchController.punchInOut('out', punchPhoto: _selfieImage);
                                                      if (!mounted) return;
                                                      if (_punchController.punchInOutApiState.value?.isSuccess ?? false) {
                                                        setState(() {
                                                          _isApiLoading = false;
                                                          _stopWorkingTimer();
                                                          _punchInTime = null;
                                                          _savePunchInTime();
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
                                              } else if (isLeft) {
                                                buttonText = AppStrings.punchOut;
                                                buttonIcon = Icons.logout;
                                                buttonColor = Colors.grey;
                                                onPressed = null;
                                              } else {
                                                buttonText = AppStrings.punchIn;
                                                buttonIcon = Icons.login;
                                                buttonColor = theme.colorScheme.primary;
                                                onPressed = null;
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
                                                            await _refreshPunchHistoryAndWorkedTimes();
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
                                                            await _refreshPunchHistoryAndWorkedTimes();
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
                                if (_todaysPunchEntries.isNotEmpty && _todaysPunchEntries.first.breaks.isNotEmpty)
                                  Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),),
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
                                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.withOpacity(0.1),),
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
                                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.1),),
                                                    child: Icon(Icons.play_circle_fill, color: Colors.green, size: 20),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Break Out', style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                                                      SizedBox(height: 2),
                                                      Text(_formatTime(breakOverIso ?? ''),
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


/*
// This dialog is used when the company provide a work from home and we get a push notification for that and we open this dialog
Future<bool?> showAnnouncementDialog(
    BuildContext context, {
      required String announcementText,
    }) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // cannot close by tapping outside
    builder: (context) {
      bool isChecked = false;

      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);

          return WillPopScope(
            onWillPop: () async => false, // disable back button
            child: Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 Header Icon (speaker)
                    Icon(
                      Icons.campaign_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Fixed Title
                    Text(
                      "Announcement",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Scrollable Announcement Text
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          announcementText,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Compact Checkbox
                    CheckboxListTile(
                      value: isChecked,
                      onChanged: (val) => setState(() => isChecked = val ?? false),
                      dense: true, // compact vertical spacing
                      contentPadding: EdgeInsets.zero, // remove left/right padding
                      controlAffinity: ListTileControlAffinity.leading, // checkbox before text
                      title: Text(
                        "I agree to the terms, conditions and policy.",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Agree Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isChecked
                              ? theme.colorScheme.primary
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isChecked
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        child: const Text(
                          "I Agree",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


*/
