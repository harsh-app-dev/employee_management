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
import '../../../core/widgets/app_side_drawer.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

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
    setState(() {_selectedDate = newDate;});
    _controller.fetchTasks();
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
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
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
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: TabBarView(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Date navigation
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left, size: 35),
                        onPressed: () {
                          _onDateChanged(_selectedDate.subtract(const Duration(days: 1)));
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
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12),),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('E, d MMMM yyyy').format(_selectedDate),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.2, color: theme.colorScheme.primary,),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.primary, size: 26),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right, size: 35),
                        onPressed: () {
                          _onDateChanged(_selectedDate.add(const Duration(days: 1)));
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 1.5.h, left: 2.w),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_turned_in_rounded, color: theme.colorScheme.primary, size: 28),
                      SizedBox(width: 2.w),
                      Text(
                        AppStrings.taskOverview,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5,),
                      ),
                    ],
                  ),
                ),
                Expanded(
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
                              child: TaskCard(task: task, isHistoryTask: false),
                            );
                          },
                        );
                      } else {
                        return Center(
                          child: SizedBox(
                            height: 40.h,
                            child: Center(
                              child: Text('No task found.', style: TextStyle(fontSize: 20.dp), textAlign: TextAlign.center,),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ), const TaskHistoryScreen(),
        ],
      ),

      /// Floating Action Button
      floatingActionButton: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return AnimatedBuilder(
            animation: tabController,
            builder: (context, _) {
              if (tabController.index != 0) return const SizedBox.shrink();

              final now = DateTime.now();
              final isToday = _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;

              return AnimatedScale(
                scale: isToday ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: isToday ? ValueListenableBuilder<ApiState>(
                  valueListenable: _controller.tasksApiState,
                  builder: (context, tasksState, _) {
                    final hasTasks = tasksState.isSuccess && tasksState.data?.data != null && tasksState.data!.data!.isNotEmpty;

                    if (!hasTasks) return const SizedBox.shrink();

                    return ValueListenableBuilder<ApiState<SubmitTasksResponse>>(
                      valueListenable: _controller.submitTasksApiState,
                      builder: (context, submitState, _) {
                        final isLoading = submitState.isLoading;

                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7),],
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
                                        showGlobalSnackBar(_controller.submitTasksApiState.value.error ?? AppStrings.failedSubmission,);
                                      }
                                    } else {
                                      showGlobalSnackBar('You have no pending tasks to submit');
                                    }
                                  });
                                },
                                label: Text(
                                  isLoading ? 'Submitting...' : AppStrings.submit,
                                  style: TextStyle(color: isLoading ? Colors.transparent : theme.colorScheme.surface, fontSize: 14.dp,),
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
                ) : const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
