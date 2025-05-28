import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:employee_management/features/presentation/state/dashboard_controller.dart';
import 'package:employee_management/features/presentation/state/punch_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;
  late final PunchController _punchController;

  @override
  void initState() {
    super.initState();
    _controller = getIt<DashboardController>();
    _punchController = getIt<PunchController>();
    _controller.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Dashboard',
            style: TextStyle(color: theme.colorScheme.onPrimary),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.account_circle,
              size: 32,
              color: theme.colorScheme.onPrimary,
            ),
            onPressed: () {
              // Handle profile tap
              showGlobalSnackBar('Profile tapped !');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ValueListenableBuilder(
              valueListenable: _punchController.punchApiState,
              builder: (context, punchState, _) {
                final isLoading = punchState?.isLoading ?? false;
                final isSuccess = punchState?.isSuccess ?? false;
                final isError = punchState?.isError ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isLoading)
                      const CircularProgressIndicator(),
                    if (!isLoading && !isSuccess)
                      ElevatedButton(
                        onPressed: () async {
                          await _punchController.punchInOut();
                        },
                        child: const Text('Punch In'),
                      ),
                    if (!isLoading && isSuccess)
                      ElevatedButton(
                        onPressed: () async {
                          await _punchController.punchInOut();
                        },
                        child: const Text('Punch Out'),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Handle submit action
                      },
                      child: const Text('Submit'),
                    ),
                    if (isError && punchState?.error != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          punchState!.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _controller.tasksApiState,
              builder: (context, taskApiState, _) {
                if (taskApiState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (taskApiState.isError) {
                  return Center(
                    child: Text(
                      taskApiState.error ?? '',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                      ),
                    ),
                  );
                } else if (taskApiState.isSuccess) {
                  final tasks = taskApiState.data?.data ?? [];
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No Result Found.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 24,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: task.isEdited == true
                            ? theme.colorScheme.errorContainer
                            : null,
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Type: ${task.taskPhase}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatTime(task.taskTimeSpend),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Text(
                                'Description:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Html(
                                data:
                                    task.taskDescription?.trim() ?? 'No Description',
                                shrinkWrap: true,
                                style: {
                                  "body": Style(
                                    color: theme.colorScheme.onSurface,
                                    maxLines: 3,
                                    fontSize: FontSize(16),
                                    fontFamily:
                                        theme.textTheme.bodyMedium?.fontFamily,
                                    textOverflow: TextOverflow.ellipsis,
                                    padding: HtmlPaddings.only(
                                      left: 0,
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                    ),
                                    margin: Margins.zero,
                                  ),
                                  "ul": Style(
                                    padding: HtmlPaddings.only(left: 16),
                                    margin: Margins.only(bottom: 8),
                                  ),
                                  "ol": Style(
                                    padding: HtmlPaddings.only(left: 16),
                                    margin: Margins.only(bottom: 8),
                                  ),
                                  "li": Style(
                                    padding: HtmlPaddings.only(left: 8),
                                    margin: Margins.only(bottom: 4),
                                  ),
                                  "p": Style(margin: Margins.only(bottom: 8)),
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
