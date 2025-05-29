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
    _punchController.initPunchStatus(); // Initialize punch status
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
              getIt<GlobalKey<NavigatorState>>().currentState?.pushNamed(
                '/profile',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ValueListenableBuilder<bool>(
              valueListenable: _punchController.isPunchedIn,
              builder: (context, punchedIn, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _punchController.isPunchedOut,
                  builder: (context, punchedOut, __) {
                    return ValueListenableBuilder(
                      valueListenable: _punchController.punchApiState,
                      builder: (context, punchState, ___) {
                        final isLoading = punchState?.isLoading ?? false;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isLoading) const CircularProgressIndicator(),
                            if (!isLoading && !punchedIn)
                              ElevatedButton(
                                onPressed: () async {
                                  await _punchController.punchInOut('In');
                                  if (_punchController
                                          .punchApiState
                                          .value
                                          ?.isSuccess ??
                                      false) {
                                    showGlobalSnackBar('Punch In successful!');
                                  } else if (_punchController
                                          .punchApiState
                                          .value
                                          ?.isError ??
                                      false) {
                                    showGlobalSnackBar(
                                      _punchController
                                              .punchApiState
                                              .value
                                              ?.error ??
                                          'Punch In failed!',
                                    );
                                  }
                                },
                                child: const Text('Punch In'),
                              ),
                            if (!isLoading && punchedIn && !punchedOut)
                              ElevatedButton(
                                onPressed: () async {
                                  await _punchController.punchInOut('out');
                                  if (_punchController
                                          .punchApiState
                                          .value
                                          ?.isSuccess ??
                                      false) {
                                    showGlobalSnackBar('Punch Out successful!');
                                  } else if (_punchController
                                          .punchApiState
                                          .value
                                          ?.isError ??
                                      false) {
                                    showGlobalSnackBar(
                                      _punchController
                                              .punchApiState
                                              .value
                                              ?.error ??
                                          'Punch Out failed!',
                                    );
                                  }
                                },
                                child: const Text('Punch Out'),
                              ),
                            ElevatedButton(
                              onPressed: () {
                                showGlobalSnackBar('Coming soon....');
                              },
                              child: const Text('Submit'),
                            ),
                          ],
                        );
                      },
                    );
                  },
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: task.isEdited == true
                            ? theme.colorScheme.errorContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.ticket?.title ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatTime(task.taskTimeSpend),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Description',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth,
                                    ),
                                    child: Html(
                                      data:
                                          task.taskDescription ??
                                          'No Description',
                                      shrinkWrap: true,
                                      style: {
                                        "body": Style(
                                          color: theme.colorScheme.onSurface,
                                          maxLines: 3,
                                          fontSize: FontSize(14),
                                          fontFamily: theme
                                              .textTheme
                                              .bodyMedium
                                              ?.fontFamily,
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
                                        "p": Style(
                                          margin: Margins.only(bottom: 8),
                                        ),
                                      },
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: Container()),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: task.isEdited == true
                                          ? theme.colorScheme.onErrorContainer
                                                .withValues(alpha: 0.6)
                                          : theme.colorScheme.primary
                                                .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      task.taskPhase ?? '',
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 1,
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
