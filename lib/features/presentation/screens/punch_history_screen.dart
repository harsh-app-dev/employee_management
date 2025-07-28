import 'package:employee_management/core/configs/strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:get_it/get_it.dart';
import '../../../core/utils/network_result.dart';
import '../../data/models/location/parsed_location.dart';
import 'package:employee_management/core/services/location_services.dart';
import 'package:collection/collection.dart';
import 'package:employee_management/core/utils/util.dart';

enum DateFilter { week, month, custom }

class PunchHistoryScreen extends StatefulWidget {
  const PunchHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PunchHistoryScreen> createState() => _PunchHistoryScreenState();
}

class _PunchHistoryScreenState extends State<PunchHistoryScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<PunchEntry> _punchHistory = [];
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

    final startDateStr =
        "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";
    final endDateStr =
        "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";

    final result = await _useCase(
      startDate: startDateStr,
      endDate: endDateStr,
      page: _currentPage,
      pageSize: _pageSize,
    );

    if (result is NetworkSuccess<PunchHistoryResponse>) {
      setState(() {
        if (isLoadMore) {
          _punchHistory.addAll(result.data.results);
        } else {
          _punchHistory = result.data.results;
        }
        _hasMore = result.data.results.length == _pageSize;
        _isLoading = false;
        if (isLoadMore) _currentPage++;
      });
    } else {
      setState(() => _isLoading = false);
    }
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
                        _startDate = now.subtract(
                          Duration(days: now.weekday - 1),
                        );
                        _endDate = _startDate.add(const Duration(days: 6));
                      } else if (_selectedFilter == DateFilter.month) {
                        _startDate = DateTime(now.year, now.month, 1);
                        _endDate = DateTime(now.year, now.month + 1, 0);
                      } else if (_selectedFilter == DateFilter.custom) {
                        _startDate = now.subtract(
                          Duration(days: now.weekday - 1),
                        );
                        _endDate = _startDate.add(const Duration(days: 6));
                      }
                      _currentPage = 1;
                      _hasMore = true;
                    });
                    _fetchPunchHistory();
                  },
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppStrings.weekly),),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppStrings.monthly),),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppStrings.custom),),
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
                            _startDate = _startDate.subtract(
                              const Duration(days: 7),
                            );
                            _endDate = _endDate.subtract(
                              const Duration(days: 7),
                            );
                          } else if (_selectedFilter == DateFilter.month) {
                            final prevMonth = DateTime(_startDate.year, _startDate.month - 1, 1,);
                            _startDate = prevMonth;
                            _endDate = DateTime(prevMonth.year, prevMonth.month + 1, 0,);
                          } else if (_selectedFilter == DateFilter.custom) {
                            final diff = _endDate.difference(_startDate).inDays;
                            _startDate = _startDate.subtract(Duration(days: diff + 1),);
                            _endDate = _endDate.subtract(Duration(days: diff + 1),);
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
                          padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 1.w,),
                          margin: EdgeInsets.symmetric(horizontal: 0.5.w, vertical: 1.5.h,),
                          decoration: BoxDecoration(
                            color: _selectedFilter == DateFilter.custom ? Colors.green.withOpacity(0.12) : Colors.grey.shade200,
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
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: theme.colorScheme.primary,),
                              ),
                              if (_selectedFilter == DateFilter.custom) ...[
                                SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).colorScheme.primary, size: 28,),
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
                          canGoForward = _endDate.isBefore(
                            DateTime(now.year, now.month, now.day),
                          );
                        } else if (_selectedFilter == DateFilter.month) {
                          canGoForward = _endDate.isBefore(
                            DateTime(now.year, now.month, now.day),
                          );
                        } else if (_selectedFilter == DateFilter.custom) {
                          canGoForward = _endDate.isBefore(
                            DateTime(now.year, now.month, now.day),
                          );
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
                                    _startDate = _startDate.add(
                                      const Duration(days: 7),
                                    );
                                    _endDate = _endDate.add(
                                      const Duration(days: 7),
                                    );
                                  } else if (_selectedFilter ==
                                      DateFilter.month) {
                                    final nextMonth = DateTime(_startDate.year, _startDate.month + 1, 1,);
                                    _startDate = nextMonth;
                                    _endDate = DateTime(nextMonth.year, nextMonth.month + 1, 0,);
                                  } else if (_selectedFilter ==
                                      DateFilter.custom) {
                                    final diff = _endDate.difference(_startDate).inDays;
                                    _startDate = _startDate.add(
                                      Duration(days: diff + 1),
                                    );
                                    _endDate = _endDate.add(
                                      Duration(days: diff + 1),
                                    );
                                  }
                                  _currentPage = 1;
                                  _hasMore = true;
                                });
                                _fetchPunchHistory();
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
                child: _isLoading && _punchHistory.isEmpty
                    ? const Center(child: CircularProgressIndicator()) : _punchHistory.isEmpty
                    ? const Center(child: Text(AppStrings.noPunchEntries)) : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!_isLoading &&
                              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100 && _hasMore) {
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
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final item = _punchHistory[index];

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
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 22,),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      DateFormat('EEE, MMM d, yyyy',).format(DateTime.parse(
                                                          item.date,
                                                        ),
                                                      ),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20,),
                                                    ),
                                                    // if (item.deductionType != null && item.deductionType!.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 8.0),
                                                        // child: Chip(label: Text(getDeductionInitials(item.deductionType!)), backgroundColor: Colors.red,),
                                                        child: Chip(label: Text(getDeductionInitials("half"), style: TextStyle(color: Colors.white),), backgroundColor: Colors.red, ),

                                                      ),
                                                  ],
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.vertical(
                                                              top: Radius.circular(
                                                                    30,
                                                                  ),
                                                            ),
                                                      ),
                                                      builder: (context) {
                                                        return DraggableScrollableSheet(
                                                          expand: false,
                                                          initialChildSize: 0.5,
                                                          minChildSize: 0.3,
                                                          maxChildSize: 0.95,
                                                          builder: (context, scrollController,) {
                                                                return Padding(
                                                                  padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom:
                                                                        MediaQuery.of(context,).viewInsets.bottom + 16,),
                                                                  child: SingleChildScrollView(
                                                                    controller: scrollController,
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Center(
                                                                          child: Container(width: 40, height: 5, margin: EdgeInsets.only(bottom: 18,),
                                                                            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(8,),),
                                                                          ),
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            Icon(Icons.access_time, color: theme.colorScheme.primary, size: 28,),
                                                                            SizedBox(width: 8,),
                                                                            Text(
                                                                              AppStrings.punchDetails,
                                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20,),
                                                                            ),
                                                                            Spacer(),
                                                                            IconButton(
                                                                              icon: Icon(Icons.close, color: theme.colorScheme.primary,),
                                                                              onPressed: () => Navigator.of(context,).pop(),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Divider(height: 24, thickness: 1.3,
                                                                          color: theme.colorScheme.primary.withOpacity(0.15,),
                                                                        ),
                                                                        // Punch In/Out details
                                                                        Padding(padding: const EdgeInsets.only(bottom: 18.0,),
                                                                          child: Column(
                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  Icon(Icons.login, color: Colors.green, size: 22,),
                                                                                  SizedBox(width: 6,),
                                                                                  Text(
                                                                                    '${AppStrings.inText}: ',
                                                                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15,),
                                                                                  ),
                                                                                  Text(
                                                                                    formatTime(punchIn,),
                                                                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15,),
                                                                                  ),
                                                                                  Spacer(),
                                                                                  Icon(Icons.logout, color: Colors.red, size: 22,),
                                                                                  SizedBox(width: 6,),
                                                                                  Text(
                                                                                    '${AppStrings.out}: ',
                                                                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15,),
                                                                                  ),
                                                                                  Text(
                                                                                    formatTime(punchOut,),
                                                                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15,),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              // Break logs
                                                                              if (item.breaks.isNotEmpty) ...[
                                                                                SizedBox(height: 30),
                                                                                Text('Break Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                                Divider(height: 18, thickness: 1.1, color: theme.colorScheme.primary.withOpacity(0.10)),
                                                                                ...item.breaks.asMap().entries.map((bEntry) {
                                                                                  final brk = bEntry.value;
                                                                                  final parentDate = item.date;
                                                                                  return Padding(
                                                                                    padding: const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
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
                                                                                            Text('Break In', style: TextStyle(fontSize: 15, color: Colors.orange, fontWeight: FontWeight.bold)),
                                                                                            SizedBox(height: 2),
                                                                                            Text( brk.breakStart != null
                                                                                  ? formatTime(brk.breakStart, date: parentDate)
                                                                                      : '--:--', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
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
                                                                                            Text('Break Out', style: TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold)),
                                                                                            SizedBox(height: 2),
                                                                                            Text( brk.breakOver != null
                                                                                  ? formatTime(brk.breakOver, date: parentDate)
                                                                                      : '--:--', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                                                                          ],
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  );
                                                                                }).toList(),
                                                                              ],
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Divider(height: 28, thickness: 1.3, color: theme.colorScheme.primary.withOpacity(0.15,),),
                                                                        Row(
                                                                          children: [
                                                                            Icon(Icons.timer, color: theme.colorScheme.primary, size: 22,),
                                                                            SizedBox(width: 3,),
                                                                            Text(
                                                                              'Total Work: ',
                                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,),
                                                                            ),
                                                                            Text(
                                                                              formatDuration(item.totalWorkTime,),
                                                                              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.7,),),
                                                                            ),

                                                                            SizedBox(width: 10,),

                                                                            Icon(Icons.pause_circle_filled, color: Colors.orange, size: 22,),
                                                                            SizedBox(width: 3,),
                                                                            Text(
                                                                              'Total Break: ',
                                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,),
                                                                            ),
                                                                            Text(
                                                                              formatDuration(item.totalBreakTime,),
                                                                              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.7,),
                                                                              ),
                                                                            ),
                                                                          ],
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
                                                  child: Text(
                                                    AppStrings.viewAll,
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary,),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12,),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary.withOpacity(0.03),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
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
                                                                Text(
                                                                  AppStrings.punchIn,
                                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green,),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              punchIn != null && punchIn.isNotEmpty ? formatTime(punchIn) : '--',
                                                              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.8,),),
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
                                                                Text(
                                                                  AppStrings.punchOut,
                                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red,),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              punchOut != null && punchOut.isNotEmpty
                                                                  ? formatTime(punchOut) : '--',
                                                              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.8,),),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 10),
                                                  _PunchLocationColumn(
                                                    punchInLatLong: item.punchedInLatLong ?? item.punchedInLatLong,
                                                    punchOutLatLong: item.punchedOutLatLong ?? item.punchedOutLatLong,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            Container(
                                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10,),
                                              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(16),),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Icon(Icons.timer, color: theme.colorScheme.primary, size: 20,),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    '${AppStrings.activeHours}: ',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,),
                                                  ),
                                                  Text(
                                                    formatDuration(item.totalWorkTime,),
                                                    style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6),),
                                                  ),
                                                  SizedBox(width: 30),
                                                  Icon(Icons.pause_circle_filled, color: Colors.orange, size: 20,),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    '${AppStrings.breaks}: ',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,),
                                                  ),
                                                  Text(
                                                    formatDuration(item.totalBreakTime,),
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
                            if (_isLoading && _hasMore && _punchHistory.isNotEmpty)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 16,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black12, blurRadius: 8,),
                                      ],
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

class _PunchLocationColumn extends StatefulWidget {
  final String? punchInLatLong;
  final String? punchOutLatLong;

  const _PunchLocationColumn({
    Key? key,
    this.punchInLatLong,
    this.punchOutLatLong,
  }) : super(key: key);

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
        child: Text('--:--', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.4),),),
      );
    }
    final parsedIn = ParsedLocation.fromString(punchInAddress);
    final parsedOut = ParsedLocation.fromString(punchOutAddress);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6),),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 12),
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
          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6),),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
