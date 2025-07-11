import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:employee_management/core/configs/strings.dart';
import 'package:employee_management/features/presentation/state/dashboard_controller.dart';
import 'package:employee_management/features/presentation/widgets/task_card.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_state.dart';
import '../../../core/utils/util.dart';
import '../../../core/widgets/debouncing_state.dart';
import '../../data/models/tasks/submit/submit_tasks_response.dart';
import 'task_history_screen.dart';
import 'app_side_drawer.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({Key? key}) : super(key: key);

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final DashboardController _controller = GetIt.I<DashboardController>();
  DateTime _selectedDate = DateTime.now();
  final Debouncer _submitDebouncer = Debouncer(delay: Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _controller.fetchTasks();
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    _controller.fetchTasks(); // You can pass the date to fetchTasks if your API supports it
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: AppSideDrawer(),
      appBar: AppBar(
        title: const Text('Task Management', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          tabs: const [
            Tab(icon: Icon(Icons.task), text: 'Tasks'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: TabBarView(
        children: [
          // --- Tasks Tab ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_left, size: 35),
                        onPressed: () {
                          _onDateChanged(_selectedDate.subtract(Duration(days: 1)));
                        },
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              _onDateChanged(picked);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  DateFormat('E, d MMMM yyyy').format(_selectedDate),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.primary, size: 28),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_right, size: 35),
                        onPressed: () {
                          _onDateChanged(_selectedDate.add(Duration(days: 1)));
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 1.5.h, left: 2.w),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_turned_in_rounded, color: theme.colorScheme.primary, size: 28,),
                      SizedBox(width: 2.w),
                      Text(
                        AppStrings.taskOverview,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5,),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    child: ValueListenableBuilder(
                      valueListenable: _controller.tasksApiState,
                      builder: (context, apiState, _) {
                        if (apiState.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (apiState.isError) {
                          return Center(
                            child: Text(apiState.error ?? 'Failed to load tasks'),
                          );
                        } else if (apiState.isSuccess && apiState.data?.data != null && apiState.data!.data!.isNotEmpty) {
                          final tasks = apiState.data!.data!;
                          return ListView.separated(
                            itemCount: tasks.length,
                            separatorBuilder: (context, index) => Divider(height: 1.5.h, color: Colors.grey[800]),
                            itemBuilder: (context, taskIndex) {
                              final task = tasks[taskIndex];
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 1.h),
                                child: TaskCard(task: task, isHistoryTask: false,),
                              );
                            },
                          );
                        } else {
                          return Center(
                            child: SizedBox(height: 40.h,
                              child: Center(
                                child: Text(
                                  'No task found.',
                                  style: TextStyle(fontSize: 20.sp),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- History Tab ---
          const TaskHistoryScreen(),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          if (tabController == null) return const SizedBox.shrink();
          return AnimatedBuilder(
            animation: tabController,
            builder: (context, _) {
              if (tabController.index != 0) return const SizedBox.shrink();
              return ValueListenableBuilder<ApiState<SubmitTasksResponse>>(
                valueListenable: _controller.submitTasksApiState,
                builder: (context, submitState, _) {
                  final isLoading = submitState.isLoading;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FloatingActionButton.extended(
                          onPressed: () {
                            _submitDebouncer.run(() async {
                              if (isLoading) return;
                              final tasks = _controller.tasksApiState.value.data;
                              if (tasks != null && tasks.data != null && tasks.data!.isNotEmpty) {
                                await _controller.submitTasks(tasks);
                                if (_controller.submitTasksApiState.value.isSuccess) {
                                  showGlobalSnackBar(AppStrings.successSubmission);
                                } else if (_controller.submitTasksApiState.value.isError) {
                                  showGlobalSnackBar(
                                    _controller.submitTasksApiState.value.error ?? AppStrings.failedSubmission,
                                  );
                                }
                              } else {
                                showGlobalSnackBar('You have no pending tasks to submit');
                              }
                            });
                          },
                          label: Text(
                            isLoading ? 'Submitting...' : AppStrings.submit,
                            style: TextStyle(
                              color: isLoading ? Colors.transparent : theme.colorScheme.surface, fontSize: 14.sp,
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        if (isLoading)
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

