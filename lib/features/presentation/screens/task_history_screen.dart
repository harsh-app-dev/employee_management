import 'package:employee_management/core/configs/strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:employee_management/features/data/models/tasks/task_history_response.dart';
import 'package:employee_management/features/domain/use_cases/task_history_use_case.dart';
import 'package:employee_management/features/presentation/widgets/task_card.dart';
import 'package:get_it/get_it.dart';
import '../../../core/utils/network_result.dart';
import 'package:employee_management/features/presentation/state/profile_controller.dart';

enum DateFilter { week, month, custom }

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<TaskHistoryData> _taskHistory = [];
  bool _isLoading = false;
  final TaskHistoryUseCase _useCase = GetIt.I<TaskHistoryUseCase>();
  String? _userId;
  final ProfileController _profileController = GetIt.I<ProfileController>();
  DateFilter _selectedFilter = DateFilter.week;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final profiles = await _profileController.profileDao.getAllProfiles();
    final profile = profiles.isNotEmpty ? profiles.first : null;
    setState(() {
      _userId = profile?.id;
      final now = DateTime.now();
      _startDate = now.subtract(Duration(days: now.weekday - 1));
      _endDate = _startDate.add(const Duration(days: 6));
    });
    if (_userId != null && _userId!.isNotEmpty) {
      _fetchTaskHistory();
    }
  }

  Future<void> _fetchTaskHistory() async {
    if (_isLoading || _userId == null || _userId!.isEmpty) return;
    setState(() => _isLoading = true);

    final startDateStr = "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";
    final endDateStr = "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";

    final result = await _useCase(
      _userId!,
      startDate: startDateStr,
      endDate: endDateStr,
    );

    if (result is NetworkSuccess<TaskHistoryResponse>) {
      final allTasks = <TaskHistoryData>[];

      if (result.data.data != null) {
        allTasks.addAll(result.data.data!);
      }

      final filteredTasks = allTasks.where((task) {
        return task.isCompleted == true;
      }).toList();

      setState(() {
        _taskHistory = filteredTasks;
        _isLoading = false;
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
      });
      _fetchTaskHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlutterSizer(
      builder: (context, orientation, screenType) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Stack(
            children: [
              Column(
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
                        });
                        _fetchTaskHistory();
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
                        SizedBox(width: 48, height: 48,
                          child: IconButton(
                            padding: EdgeInsets.zero,
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
                              });
                              _fetchTaskHistory();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 70.w,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _selectedFilter == DateFilter.custom ? _pickDateRange : null,
                            splashColor: _selectedFilter == DateFilter.custom ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                            hoverColor: _selectedFilter == DateFilter.custom ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 1.w),
                              margin: EdgeInsets.symmetric(horizontal: 0.5.w, vertical: 1.5.h),
                              decoration: BoxDecoration(
                                color: _selectedFilter == DateFilter.custom
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.grey.shade200,
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
                                    "${DateFormat('dd MMM yyyy').format(_startDate)} → ${DateFormat('dd MMM yyyy').format(_endDate)}",
                                    style: TextStyle(fontSize: 14.dp, fontWeight: FontWeight.w600, color: theme.colorScheme.primary,),
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
                                    });
                                    _fetchTaskHistory();
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
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 28),
                              SizedBox(width: 8),
                              Text(
                                AppStrings.completedTasks,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5,),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _taskHistory.isEmpty
                              ? const Center(child: Text(AppStrings.noCompletionTasks))
                              : ListView.builder(
                                  itemCount: _taskHistory.length,
                                  itemBuilder: (context, taskIndex) {
                                    final task = _taskHistory[taskIndex];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      child: TaskCard(task: task, isHistoryTask: true,),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15),
                    child: const Center(
                      child: CircularProgressIndicator(),
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

