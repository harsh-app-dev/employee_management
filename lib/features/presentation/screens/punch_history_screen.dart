import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

class PunchHistoryScreen extends StatefulWidget {
  const PunchHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PunchHistoryScreen> createState() => _PunchHistoryScreenState();
}

class _PunchHistoryScreenState extends State<PunchHistoryScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  late Map<String, Map<String, String>> _punchData;
  int _visibleCount = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Set startDate to Monday of current week
    _startDate = now.subtract(Duration(days: now.weekday - 1));
    // Set endDate to Sunday of current week
    _endDate = _startDate.add(const Duration(days: 6));
    _punchData = _generateDummyPunchData();
  }

  Map<String, Map<String, String>> _generateDummyPunchData() {
    final Map<String, Map<String, String>> data = {};
    final now = DateTime.now();
    for (int i = 0; i < 100; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final minute = i < 10 ? '0$i' : '$i';
      data[dateStr] = {
        'punchIn': '09:$minute AM',
        'punchOut': '06:$minute PM',
        'address': 'Location $i, New Delhi, India',
      };
    }
    return data;
  }

  List<MapEntry<String, Map<String, String>>> get _filteredPunchEntries {
    return _punchData.entries.where((entry) {
      final entryDate = DateTime.parse(entry.key);
      return entryDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             entryDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => b.key.compareTo(a.key));
  }

  Future<void> _pickDateRange() async {
    DateTime start = _startDate;
    DateTime end = _endDate;
    if (start.isAfter(end)) {
      // Ensure start is not after end
      start = end;
    }
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: start, end: end),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _visibleCount += 10;
      _isLoadingMore = false;
    });
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
                child: _filteredPunchEntries.isEmpty
                    ? const Center(
                  child: Text(
                    'No punch entries found for selected dates.',
                  ),
                )
                    : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!_isLoadingMore &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 100 &&
                        _visibleCount < _filteredPunchEntries.length) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                      ListView.builder(
                        itemCount:
                        (_visibleCount < _filteredPunchEntries.length)
                            ? _visibleCount
                            : _filteredPunchEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredPunchEntries[index];
                          final date = entry.key;
                          final data = entry.value;
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'EEE, MMM d, yyyy',
                                            ).format(
                                              DateTime.parse(date),
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Icon(
                                            Icons.location_on,
                                            color:
                                            theme.colorScheme.primary,
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
                                              value: data['punchIn']!,
                                              icon: Icons.login,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _ProfileField(
                                              label: 'Punch Out',
                                              value: data['punchOut']!,
                                              icon: Icons.logout,
                                              iconColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _ProfileField(
                                        label: 'Address',
                                        value: data['address']!,
                                        icon: Icons.map,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_isLoadingMore)
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
