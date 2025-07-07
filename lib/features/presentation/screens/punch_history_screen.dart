import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:get_it/get_it.dart';

import '../../../core/services/location_services.dart';
import '../../../core/utils/network_result.dart';
import '../../data/models/location/parsed_location.dart';

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Set startDate to Monday of current week
    _startDate = now.subtract(Duration(days: now.weekday - 1));
    // Set endDate to Sunday of current week
    _endDate = _startDate.add(const Duration(days: 6));
    _fetchPunchHistory();
  }

  Future<void> _fetchPunchHistory({bool isLoadMore = false}) async {
    if (_isLoading || (!_hasMore && isLoadMore)) return;
    setState(() => _isLoading = true);
    final result = await _useCase(
      page: _currentPage,
      pageSize: _pageSize,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
    );
    if (result is NetworkSuccess<List<PunchHistoryResponse>>) {
      // Convert locations to readable format if needed
      final newItems = await Future.wait(result.data.map((item) async {
        final punchInLocation = await LocationService.getReadableLocation(item.punchInLocation);
        final punchOutLocation = await LocationService.getReadableLocation(item.punchOutLocation);

        return PunchHistoryResponse(
          id: item.id,
          date: item.date,
          punchIn: item.punchIn,
          punchOut: item.punchOut,
          isPunchedIn: item.isPunchedIn,
          isPunchedOut: item.isPunchedOut,
          employee: item.employee,
          punchInLocation: punchInLocation,
          punchOutLocation: punchOutLocation,
        );
      }));
      setState(() {
        if (isLoadMore) {
          _punchHistory.addAll(newItems);
        } else {
          _punchHistory = newItems;
        }
        _hasMore = newItems.length == _pageSize;
        _isLoading = false;
        if (isLoadMore) _currentPage++;
      });
    } else {
      setState(() => _isLoading = false);
      // handle error
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
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Punch History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            elevation: 0,
            centerTitle: true,
          ),
          backgroundColor: const Color(0xFFF5F7FA),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                child: GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 4.w),
                    margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 24,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date Range",
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${DateFormat('dd MMM yyyy').format(_startDate)} → ${DateFormat('dd MMM yyyy').format(_endDate)}",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Icon(
                        //   Icons.keyboard_arrow_down_rounded,
                        //   size: 24,
                        //   color: theme.colorScheme.onSurface.withOpacity(0.6),
                        // ),
                      ],
                    ),
                  ),
                ),

              ),
              Expanded(
                child: _isLoading && _punchHistory.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _punchHistory.isEmpty
                    ? const Center(child: Text('No punch entries found for selected dates.'))
                    : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!_isLoading &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 100 &&
                        _hasMore) {
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: theme.colorScheme.surface,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(item.date)),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _ProfileField(
                                              label: 'Punch In',
                                              value: _formatTime(item.punchIn),
                                              icon: Icons.login,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _ProfileField(
                                              label: 'Punch Out',
                                              value: _formatTime(item.punchOut),
                                              icon: Icons.logout,
                                              iconColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),

                                      Row(
                                        children: [
                                          Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Punch In Location',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  punchInLoc.formatLong(), // Shows "Street, City, State"
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 8),
// Punch Out Location (formatted)
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, color: Colors.red, size: 20),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Punch Out Location',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  punchOutLoc.formatLong(), // Shows "Street, City, State"
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                  ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
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

