import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:get_it/get_it.dart';

import '../../../core/utils/network_result.dart';

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
      final newItems = result.data;
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                    padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.date_range,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Icon(
                                            item.isPunchedIn && item.isPunchedOut ? Icons.check_circle : Icons.error,
                                            color: item.isPunchedIn && item.isPunchedOut ? Colors.green : Colors.red,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _ProfileField(
                                              label: 'Punch In',
                                              value: item.punchIn ?? '-',
                                              icon: Icons.login,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _ProfileField(
                                              label: 'Punch Out',
                                              value: item.punchOut ?? '-',
                                              icon: Icons.logout,
                                              iconColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _ProfileField(
                                        label: 'Punch In Location',
                                        value: item.punchInLocation ?? '-',
                                        icon: Icons.location_on,
                                      ),
                                      const SizedBox(height: 4),
                                      _ProfileField(
                                        label: 'Punch Out Location',
                                        value: item.punchOutLocation ?? '-',
                                        icon: Icons.location_on,
                                        iconColor: Colors.red,
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
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
