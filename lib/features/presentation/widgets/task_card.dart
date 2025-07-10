import 'package:employee_management/core/configs/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:employee_management/features/data/models/tasks/task_response.dart';
import 'package:employee_management/features/data/models/tasks/task_history_response.dart';
import 'task_detail_modal.dart';
import 'task_extensions.dart';
import 'task_utils.dart';

class TaskCard extends StatelessWidget {
  final dynamic task;
  final bool showTicketId;
  final bool isHistoryTask;

  const TaskCard({
    Key? key,
    required this.task,
    this.showTicketId = true,
    this.isHistoryTask = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
        color: theme.brightness == Brightness.light ? Colors.white : theme.cardColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.confirmation_number, color: theme.colorScheme.primary, size: 24),
                  SizedBox(width: 2.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTaskTitle(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (showTicketId && _getTicketId() != null)
                        Text(
                          '${AppStrings.ticketId}: ${_getTicketId()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        backgroundColor: theme.cardColor,
                        builder: (context) => TaskDetailModal(task: task, isHistoryTask: isHistoryTask),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          AppStrings.viewAll,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.expand_more, color: theme.colorScheme.primary, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                height: 3.h,
                thickness: 1.3,
                color: theme.colorScheme.primary.withOpacity(0.15),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.work, color: theme.colorScheme.primary, size: 20),
                    SizedBox(width: 1.w),
                    Text(
                      '${AppStrings.project}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        _getProjectTitle(),
                        style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 20),
                    SizedBox(width: 1.w),
                    Text(
                      '${AppStrings.date}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _getTaskDate(),
                      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                    ),
                    SizedBox(width: 2.w),
                    Icon(Icons.access_time, color: theme.colorScheme.primary, size: 20),
                    SizedBox(width: 1.w),
                    Text(
                      '${AppStrings.time}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      formatTimeSpent(_getTaskTimeSpend()),
                      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTaskTitle() {
    if (isHistoryTask) {
      final historyTask = task as TaskHistoryData;
      return historyTask.displayTitle;
    } else {
      final dashboardTask = task as Data;
      return dashboardTask.displayTitle;
    }
  }

  String? _getTicketId() {
    if (isHistoryTask) {
      final historyTask = task as TaskHistoryData;
      return historyTask.displayTicketId;
    } else {
      final dashboardTask = task as Data;
      return dashboardTask.displayTicketId;
    }
  }

  String _getProjectTitle() {
    if (isHistoryTask) {
      final historyTask = task as TaskHistoryData;
      return historyTask.displayProjectTitle;
    } else {
      final dashboardTask = task as Data;
      return dashboardTask.displayProjectTitle;
    }
  }

  String _getTaskDate() {
    if (isHistoryTask) {
      final historyTask = task as TaskHistoryData;
      return historyTask.displayDate;
    } else {
      final dashboardTask = task as Data;
      return dashboardTask.displayDate;
    }
  }

  String? _getTaskTimeSpend() {
    if (isHistoryTask) {
      final historyTask = task as TaskHistoryData;
      return historyTask.displayTimeSpend;
    } else {
      final dashboardTask = task as Data;
      return dashboardTask.displayTimeSpend;
    }
  }
} 