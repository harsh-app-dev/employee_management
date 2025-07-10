import 'package:employee_management/core/configs/strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/location/parsed_location.dart';

enum DateFilter { week, month, custom }

class PunchHistoryScreen extends StatefulWidget {
  const PunchHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PunchHistoryScreen> createState() => _PunchHistoryScreenState();
}

class _PunchHistoryScreenState extends State<PunchHistoryScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<PunchHistoryResponse> _punchHistory = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  final int _pageSize = 10;
  final PunchHistoryUseCase _useCase = GetIt.I<PunchHistoryUseCase>();
  DateFilter _selectedFilter = DateFilter.week;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(Duration(days: now.weekday - 1));
    _endDate = _startDate.add(const Duration(days: 6));
    _fetchPunchHistory();
  }

  Future<void> _fetchPunchHistory({bool isLoadMore = false}) async {
    if (_isLoading || (!_hasMore && isLoadMore)) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    final List<PunchHistoryResponse> dummyData = List.generate(_pageSize, (i) {
      final dayOffset = (_currentPage - 1) * _pageSize + i;
      final date = _endDate.subtract(Duration(days: dayOffset));
      return PunchHistoryResponse(
        id: dayOffset,
        date: date.toIso8601String().substring(0, 10),
        punchIn: DateTime(date.year, date.month, date.day, 9, 0).toIso8601String(),
        punchOut: DateTime(date.year, date.month, date.day, 18, 0).toIso8601String(),
        isPunchedIn: true,
        isPunchedOut: true,
        employee: 'John Doe',
        punchInLocation: 'Office HQ, City',
        punchOutLocation: 'Office HQ, City',
      );
    });
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      if (isLoadMore) {
        _punchHistory.addAll(dummyData);
      } else {
        _punchHistory = dummyData;
      }
      _hasMore = dummyData.length == _pageSize;
      _isLoading = false;
      if (isLoadMore) _currentPage++;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _currentPage = 1;
        _hasMore = true;
      });
      _fetchPunchHistory();
    }
  }

  void _loadMore() {
    if (_hasMore && !_isLoading) {
      _currentPage++;
      _fetchPunchHistory(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlutterSizer(
      builder: (context, orientation, screenType) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2.h, bottom: 0.5.h),
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(8),
                  isSelected: [
                    _selectedFilter == DateFilter.week,
                    _selectedFilter == DateFilter.month,
                    _selectedFilter == DateFilter.custom,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedFilter = DateFilter.values[index];
                      final now = DateTime.now();
                      if (_selectedFilter == DateFilter.week) {
                        _startDate = now.subtract(Duration(days: now.weekday - 1));
                        _endDate = _startDate.add(const Duration(days: 6));
                      } else if (_selectedFilter == DateFilter.month) {
                        _startDate = DateTime(now.year, now.month, 1);
                        _endDate = DateTime(now.year, now.month + 1, 0);
                      } else if (_selectedFilter == DateFilter.custom) {
                        _startDate = now.subtract(Duration(days: now.weekday - 1));
                        _endDate = _startDate.add(const Duration(days: 6));
                      }
                      _currentPage = 1;
                      _hasMore = true;
                    });
                    _fetchPunchHistory();
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(AppStrings.weekly),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(AppStrings.monthly),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(AppStrings.custom),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left, size: 35),
                      onPressed: () {
                        setState(() {
                          if (_selectedFilter == DateFilter.week) {
                            _startDate = _startDate.subtract(const Duration(days: 7));
                            _endDate = _endDate.subtract(const Duration(days: 7));
                          } else if (_selectedFilter == DateFilter.month) {
                            final prevMonth = DateTime(_startDate.year, _startDate.month - 1, 1);
                            _startDate = prevMonth;
                            _endDate = DateTime(prevMonth.year, prevMonth.month + 1, 0);
                          } else if (_selectedFilter == DateFilter.custom) {
                            final diff = _endDate.difference(_startDate).inDays;
                            _startDate = _startDate.subtract(Duration(days: diff + 1));
                            _endDate = _endDate.subtract(Duration(days: diff + 1));
                          }
                          _currentPage = 1;
                          _hasMore = true;
                        });
                        _fetchPunchHistory();
                      },
                    ),
                    SizedBox(
                      width: 70.w,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _selectedFilter == DateFilter.custom ? _pickDateRange : null,
                        splashColor: _selectedFilter == DateFilter.custom ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                        hoverColor: _selectedFilter == DateFilter.custom ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 1.w),
                          margin: EdgeInsets.symmetric(horizontal: 0.5.w, vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: _selectedFilter == DateFilter.custom
                                ? Colors.green.withOpacity(0.12)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5,),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4),),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${DateFormat('dd MMM yyyy').format(_startDate)} → ${DateFormat('dd MMM yyyy').format(_endDate)}",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              if (_selectedFilter == DateFilter.custom) ...[
                                SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        bool canGoForward = false;
                        if (_selectedFilter == DateFilter.week) {
                          canGoForward = _endDate.isBefore(DateTime(now.year, now.month, now.day));
                        } else if (_selectedFilter == DateFilter.month) {
                          canGoForward = _endDate.isBefore(DateTime(now.year, now.month, now.day));
                        } else if (_selectedFilter == DateFilter.custom) {
                          canGoForward = _endDate.isBefore(DateTime(now.year, now.month, now.day));
                        }
                        return Opacity(
                          opacity: canGoForward ? 1.0 : 0.0,
                          child: IgnorePointer(
                            ignoring: !canGoForward,
                            child: IconButton(
                              icon: Icon(Icons.arrow_right, size: 35),
                              onPressed: () {
                                setState(() {
                                  if (_selectedFilter == DateFilter.week) {
                                    _startDate = _startDate.add(const Duration(days: 7));
                                    _endDate = _endDate.add(const Duration(days: 7));
                                  } else if (_selectedFilter == DateFilter.month) {
                                    final nextMonth = DateTime(_startDate.year, _startDate.month + 1, 1);
                                    _startDate = nextMonth;
                                    _endDate = DateTime(nextMonth.year, nextMonth.month + 1, 0);
                                  } else if (_selectedFilter == DateFilter.custom) {
                                    final diff = _endDate.difference(_startDate).inDays;
                                    _startDate = _startDate.add(Duration(days: diff + 1));
                                    _endDate = _endDate.add(Duration(days: diff + 1));
                                  }
                                  _currentPage = 1;
                                  _hasMore = true;
                                });
                                _fetchPunchHistory();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading && _punchHistory.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _punchHistory.isEmpty
                    ? const Center(child: Text(AppStrings.noPunchEntries))
                    : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!_isLoading && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100 && _hasMore) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                      ListView.builder(
                        itemCount: _punchHistory.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _punchHistory.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final item = _punchHistory[index];

                          final punchInLoc = ParsedLocation.fromString(item.punchInLocation);
                          final punchOutLoc = ParsedLocation.fromString(item.punchOutLocation);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: theme.colorScheme.surface,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 22),
                                              SizedBox(width: 8),
                                              Text(
                                                DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(item.date)),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                                ),
                                                builder: (context) {
                                                  final dummyEntries = [
                                                    {'in': '09:00 AM', 'out': '11:30 AM', 'worked': '2h 30m'},
                                                    {'in': '12:00 PM', 'out': '02:00 PM', 'worked': '2h 0m'},
                                                    {'in': '02:30 PM', 'out': '06:00 PM', 'worked': '3h 30m'},
                                                  ];
                                                  final totalMinutes = [150, 120, 210].reduce((a, b) => a + b);
                                                  final totalHours = totalMinutes ~/ 60;
                                                  final totalMins = totalMinutes % 60;
                                                  return DraggableScrollableSheet(
                                                    expand: false,
                                                    initialChildSize: 0.5,
                                                    minChildSize: 0.3,
                                                    maxChildSize: 0.95,
                                                    builder: (context, scrollController) {
                                                      return Padding(
                                                        padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
                                                        child: SingleChildScrollView(
                                                          controller: scrollController,
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Center(
                                                                child: Container(
                                                                  width: 40,
                                                                  height: 5,
                                                                  margin: EdgeInsets.only(bottom: 18),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.grey[400],
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                ),
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Icon(Icons.access_time, color: theme.colorScheme.primary, size: 28),
                                                                  SizedBox(width: 8),
                                                                  Text(AppStrings.punchDetails, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                                                  Spacer(),
                                                                  IconButton(
                                                                    icon: Icon(Icons.close, color: theme.colorScheme.primary),
                                                                    onPressed: () => Navigator.of(context).pop(),
                                                                  ),
                                                                ],
                                                              ),
                                                              Divider(height: 24, thickness: 1.3, color: theme.colorScheme.primary.withOpacity(0.15)),
                                                              ...dummyEntries.asMap().entries.map((entry) {
                                                                final idx = entry.key;
                                                                final punch = entry.value;
                                                                return Column(
                                                                  children: [
                                                                    Container(
                                                                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                                      margin: EdgeInsets.only(bottom: 8),
                                                                      decoration: BoxDecoration(
                                                                        color: theme.colorScheme.primary.withOpacity(0.06),
                                                                        borderRadius: BorderRadius.circular(12),
                                                                      ),
                                                                      child: Row(
                                                                        children: [
                                                                          Icon(Icons.login, color: Colors.green, size: 22),
                                                                          SizedBox(width: 8),
                                                                          Text('${AppStrings.inText}: ${punch['in']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                                                          Spacer(),
                                                                          Icon(Icons.logout, color: Colors.red, size: 22),
                                                                          SizedBox(width: 8),
                                                                          Text('${AppStrings.out}: ${punch['out']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets.only(bottom: 8),
                                                                      child: Row(
                                                                        children: [
                                                                          SizedBox(width: 4),
                                                                          Icon(Icons.timer, color: theme.colorScheme.primary, size: 18),
                                                                          SizedBox(width: 6),
                                                                          Text('Worked: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                                          Text(punch['worked']!, style: TextStyle(fontSize: 14, color: theme.colorScheme.primary)),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    if (idx < dummyEntries.length - 1)
                                                                      Padding(
                                                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                                                        child: Row(
                                                                          children: [
                                                                            Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                              child: Text('— Break —', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                                                            ),
                                                                            Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                  ],
                                                                );
                                                              }),
                                                              SizedBox(height: 20),
                                                              Center(
                                                                child: Container(
                                                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                                                  decoration: BoxDecoration(
                                                                    color: theme.colorScheme.primary.withOpacity(0.12),
                                                                    borderRadius: BorderRadius.circular(24),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.timer, color: theme.colorScheme.primary, size: 22),
                                                                      SizedBox(width: 8),
                                                                      Text('Total Worked: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                      Text('$totalHours hrs $totalMins mins', style: TextStyle(fontSize: 16, color: theme.colorScheme.primary)),
                                                                    ],
                                                                  ),
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
                                                Text(AppStrings.viewAll, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14)),
                                                Icon(Icons.expand_more, color: theme.colorScheme.primary, size: 20),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Container(
                                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _ProfileField(label: AppStrings.punchIn, value: _formatTime(item.punchIn), icon: Icons.login,),
                                            ),
                                            Container(width: 1, height: 36, color: Colors.grey.shade300,),
                                            Expanded(
                                              child: _ProfileField(label: AppStrings.punchOut, value: _formatTime(item.punchOut), icon: Icons.logout, iconColor: Colors.red,),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Container(
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        AppStrings.punchInLocation,
                                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface,),
                                                      ),
                                                      Text(
                                                        punchInLoc.formatShort(),
                                                        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6),),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on, color: Colors.red, size: 20),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        AppStrings.punchOutLocation,
                                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface,),
                                                      ),
                                                      Text(
                                                        punchOutLoc.formatShort(),
                                                        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6),),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Container(
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.10),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Icon(Icons.timer, color: theme.colorScheme.primary, size: 20),
                                            SizedBox(width: 6),
                                            Text(
                                              '${AppStrings.activeHours}: ',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            Text(
                                              _calculateWorkedTime(item.punchIn, item.punchOut),
                                              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6),),
                                            ),
                                            SizedBox(width: 14),
                                            Icon(Icons.pause_circle_filled, color: Colors.orange, size: 20),
                                            SizedBox(width: 6),
                                            Text(
                                              '${AppStrings.breaks}: ',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            Text(
                                              '20m',
                                              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6),),
                                            ),
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
                      if (_isLoading && _punchHistory.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 16,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8,),],
                              ),
                              child: const CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _ProfileField({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface,),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6),),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatTime(String? isoTime) {
  if (isoTime == null || isoTime.isEmpty) return '--:--';
  try {
    final dateTime = DateTime.parse(isoTime);
    return DateFormat('hh:mm a').format(dateTime);
  } catch (_) {
    return '--:--';
  }
}

String _calculateWorkedTime(String? punchIn, String? punchOut) {
  if (punchIn == null || punchOut == null) return '--:--';
  try {
    final inTime = DateTime.parse(punchIn);
    final outTime = DateTime.parse(punchOut);
    final diff = outTime.difference(inTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m';
  } catch (_) {
    return '--:--';
  }
}
