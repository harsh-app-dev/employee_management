import 'package:employee_management/core/configs/strings.dart';
import 'package:employee_management/features/presentation/screens/punch_history_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:get/get.dart';
import '../../../core/utils/network_result.dart';
import '../../data/models/location/parsed_location.dart';
import 'package:employee_management/core/services/location_services.dart';
import '../../data/models/punch/response/attendence_response.dart';
import 'package:employee_management/features/presentation/controllers/punch_history_controller.dart';

class PunchHistoryScreen extends StatefulWidget {
  const PunchHistoryScreen({super.key});

  @override
  State<PunchHistoryScreen> createState() => _PunchHistoryScreenState();
}

class _PunchHistoryScreenState extends State<PunchHistoryScreen> {
  late final PunchHistoryController controller;

  @override
  void initState() {
    super.initState();
    // Register controller if not already registered
    controller = Get.put(PunchHistoryController());
  }

  String formatTime(String? time, {String? date}) {
    if (time == null || time.isEmpty) return '--:--';

    try {
      final timeFormat = DateFormat('HH:mm:ss');
      final parsedTime = timeFormat.parse(time);
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
      return time;
    }
  }

  String? formatDuration(String duration) {
    if (duration.isEmpty) return '00:00';
    try {
      final parts = duration.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}h ${parts[1]}m';
      }
      return duration;
    } catch (e) {
      return duration;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlutterSizer(
      builder: (context, orientation, screenType) {
        return Scaffold(
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7),],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              AppStrings.punchHistory,
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary,),
            ),
            elevation: 0,
            centerTitle: true,
          ),
          backgroundColor: const Color(0xFFF5F7FA),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2.h, bottom: 0.5.h),
                child: Obx(() {
                  return ToggleButtons(
                    borderRadius: BorderRadius.circular(8),
                    isSelected: [
                      controller.selectedFilter.value == DateFilter.week,
                      controller.selectedFilter.value == DateFilter.month,
                      controller.selectedFilter.value == DateFilter.custom,
                    ],
                    onPressed: (index) {
                      controller.changeFilter(index);
                    },
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppStrings.weekly),),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppStrings.monthly),),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppStrings.custom),),
                    ],
                  );
                }),
              ),
              Padding(
                padding: EdgeInsets.symmetric( vertical: 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left, size: 35),
                      onPressed: () {
                        controller.prevRange();
                      },
                    ),
                    SizedBox(
                      width: 70.w,
                      child: Obx(() {
                        final isCustom = controller.selectedFilter.value == DateFilter.custom;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isCustom ? () => controller.pickDateRange(context) : null,
                          splashColor: isCustom ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                          hoverColor: isCustom ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 1.w,),
                            margin: EdgeInsets.symmetric(horizontal: 0.5.w, vertical: 1.5.h,),
                            decoration: BoxDecoration(
                              color: isCustom ? Colors.green.withValues(alpha: 0.12) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5,),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4),),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${DateFormat('dd MMM yyyy').format(controller.startDate.value)} → ${DateFormat('dd MMM yyyy').format(controller.endDate.value)}",
                                  style: TextStyle(fontSize: 14.dp, fontWeight: FontWeight.w600, color: theme.colorScheme.primary,),
                                ),
                                if (isCustom) ...[
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).colorScheme.primary, size: 28,),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        bool canGoForward = false;
                        if (controller.selectedFilter.value == DateFilter.week) {
                          canGoForward = controller.endDate.value.isBefore(DateTime(now.year, now.month, now.day),);
                        } else if (controller.selectedFilter.value == DateFilter.month) {
                          canGoForward = controller.endDate.value.isBefore(DateTime(now.year, now.month, now.day),);
                        } else if (controller.selectedFilter.value == DateFilter.custom) {
                          canGoForward = controller.endDate.value.isBefore(DateTime(now.year, now.month, now.day),);
                        }
                        return Opacity(
                            opacity: canGoForward ? 1.0 : 0.0,
                            child: IgnorePointer(
                              ignoring: !canGoForward,
                              child: IconButton(
                                icon: Icon(Icons.arrow_right, size: 35),
                                onPressed: () {
                                  controller.nextRange();
                                },
                              ),
                            )
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  final isLoading = controller.isLoading.value;
                  final history = controller.punchHistory;
                  final hasMore = controller.hasMore.value;
                  if (isLoading && history.isEmpty) return const Center(child: CircularProgressIndicator());
                  if (history.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              AppStrings.noPunchEntries,
                              style: TextStyle(fontSize: 20, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!controller.isLoading.value && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100 && controller.hasMore.value) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: Stack(
                      children: [
                        ListView.builder(
                          itemCount: history.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == history.length) {
                              return const Center(child: CircularProgressIndicator(),);
                            }
                            final item = history[index];
                            final punchIn = item.punchIn;
                            final punchOut = item.punchOut;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10,),
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: theme.colorScheme.surface,),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 20,),
                                                SizedBox(width: 8),
                                                Text(DateFormat('EEE, MMM d, yyyy',).format(DateTime.parse(item.attendanceDate,),),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),
                                                ),
                                              ],
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final result = await GetIt.I<PunchHistoryUseCase>().callPunchDetail(date: item.attendanceDate);
                                                if (result is NetworkSuccess<AttendanceResponse>) {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                                    ),
                                                    builder: (context) {
                                                      final attendanceDetails = result.data.attendances;

                                                      String punchInTime = '--:--';
                                                      String punchOutTime = '--:--';

                                                      for (var attendance in attendanceDetails) {
                                                        if (attendance.workLogs != null && attendance.workLogs!.isNotEmpty) {
                                                          final log = attendance.workLogs!.first;
                                                          if (log.type == 'punch_in') {
                                                            punchInTime = log.time ?? '--:--';
                                                          } else if (log.type == 'punch_out') {
                                                            punchOutTime = log.time ?? '--:--';
                                                          }
                                                        }
                                                      }
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
                                                            formattedDate: DateFormat('EEEE, d MMM yyyy')
                                                              .format(DateTime.parse(item.attendanceDate)),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text("Failed to load punch details")),
                                                  );
                                                }
                                              },
                                              child: Text(
                                                AppStrings.viewAll, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14),
                                              ),
                                            ),

                                          ],
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12,),
                                          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12),),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.login, color: Colors.green, size: 18,),
                                                            SizedBox(width: 4,),
                                                            Text(AppStrings.inText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green,),),
                                                          ],
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          punchIn != null ? formatTime(punchIn.time) : '--',
                                                          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.8,),),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.logout, color: Colors.red, size: 18,),
                                                            SizedBox(width: 4,),
                                                            Text(AppStrings.out, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red,),),
                                                          ],
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          punchOut != null ? formatTime(punchOut.time) : '--',
                                                          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.8,),),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 10),
                                              _PunchLocationColumn(punchInLatLong: punchIn?.punchedInLatLong, punchOutLatLong: punchOut?.punchedOutLatLong,),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6,),
                                          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16),),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Icon(Icons.timer, color: theme.colorScheme.primary, size: 18),

                                              SizedBox(width: 1),
                                              Text('${AppStrings.workedHrs}: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,),),
                                              Text(formatDuration(item.totalWorkHour)!, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6),),),

                                              SizedBox(width: 10),
                                              Icon(Icons.pause_circle_filled, color: Colors.orange, size: 18,),

                                              SizedBox(width: 1),
                                              Text('${AppStrings.breakHrs}: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,),),
                                              Text(formatDuration(item.totalBreakHour)!, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6),),),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PunchLocationColumn extends StatefulWidget {
  final String? punchInLatLong;
  final String? punchOutLatLong;

  const _PunchLocationColumn({
    this.punchInLatLong,
    this.punchOutLatLong,
  });

  @override
  State<_PunchLocationColumn> createState() => _PunchLocationColumnState();
}

class _PunchLocationColumnState extends State<_PunchLocationColumn> {
  String? punchInAddress;
  String? punchOutAddress;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _resolveLocations();
  }

  Future<void> _resolveLocations() async {
    final inAddr = await LocationService.getReadableLocation(
      widget.punchInLatLong,
    );
    final outAddr = await LocationService.getReadableLocation(
      widget.punchOutLatLong,
    );
    setState(() {
      punchInAddress = inAddr;
      punchOutAddress = outAddr;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('--:--', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),),),
      );
    }
    final parsedIn = ParsedLocation.fromString(punchInAddress);
    final parsedOut = ParsedLocation.fromString(punchOutAddress);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.punchInLatLong != null) ...[
          Row(
            children: [
              Icon(Icons.location_on, color: theme.colorScheme.primary, size: 18),
              SizedBox(width: 6),
              Text('Punch In Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),),
            ],
          ),
          SizedBox(height: 4),
          Text(
            parsedIn.formatShort().isNotEmpty ? parsedIn.formatShort() : '--:--',
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.6),),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
        ],
        if (widget.punchOutLatLong != null) ...[
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 18),
              SizedBox(width: 6),
              Text('Punch Out Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),),
            ],
          ),
          SizedBox(height: 4),
          Text(
            parsedOut.formatShort().isNotEmpty ? parsedOut.formatShort() : '--:--',
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.6),),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
