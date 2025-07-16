import 'package:employee_management/core/configs/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:employee_management/features/data/models/tasks/task_response.dart';
import 'package:employee_management/features/data/models/tasks/task_history_response.dart';
import '../../../core/utils/util.dart';
import 'task_extensions.dart';

class TaskDetailModal extends StatelessWidget {
  final dynamic task;
  final bool isHistoryTask;

  const TaskDetailModal({
    Key? key,
    required this.task,
    this.isHistoryTask = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 5.w,
            right: 5.w,
            top: 3.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                    Icon(Icons.assignment, color: theme.colorScheme.primary, size: 28),
                    SizedBox(width: 2.w),
                    Text(
                      AppStrings.taskDetails,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.colorScheme.primary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(
                  height: 3.h,
                  thickness: 1.3,
                  color: theme.colorScheme.primary.withOpacity(0.15),
                ),
                _buildDetailRow(
                  context,
                  Icons.work,
                  '${AppStrings.project}:',
                  _getProjectTitle(),
                ),
                _buildDetailRow(
                  context,
                  Icons.confirmation_number,
                  '${AppStrings.ticketTitle}:',
                  _getTaskTitle(),
                ),
                _buildDetailRow(
                  context,
                  Icons.confirmation_number_outlined,
                  '${AppStrings.ticketId}:',
                  _getTicketId() ?? '-',
                ),
                _buildDetailRow(
                  context,
                  Icons.layers,
                  '${AppStrings.phase}:',
                  _getTaskPhase(),
                ),
                _buildDateTimeRow(context),
                _buildDescriptionRow(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.2.h),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          SizedBox(width: 2.w),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.2.h),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 20),
          SizedBox(width: 2.w),
          Text(
            '${AppStrings.date}:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            _getTaskDate(),
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
          ),
          SizedBox(width: 3.w),
          Icon(Icons.access_time, color: theme.colorScheme.primary, size: 20),
          SizedBox(width: 2.w),
          Text(
            '${AppStrings.time}:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            formatTimeSpent(_getTaskTimeSpend()),
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionRow(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.description}:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            _getTaskDescription(),
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.normal,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
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

  String _getTaskPhase() {
    if (isHistoryTask) {
      final historyTask = task as TaskHistoryData;
      return historyTask.displayPhase;
    } else {
      final dashboardTask = task as Data;
      return dashboardTask.displayPhase;
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

  String _getTaskDescription() {
    if (isHistoryTask) {
      final historyTask = task as TaskHistoryData;
      return historyTask.displayDescription;
    } else {
      final dashboardTask = task as Data;
      return dashboardTask.displayDescription;
    }
  }
} 