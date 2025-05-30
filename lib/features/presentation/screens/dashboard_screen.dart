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
    _punchController.getPunchState();
    _controller.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
          ValueListenableBuilder(
            valueListenable: _punchController.nameInitials,
            builder: (context, initials, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0, top: 8, bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    getIt<GlobalKey<NavigatorState>>().currentState?.pushNamed(
                      '/profile',
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      (initials.isNotEmpty ? initials : '?'),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _controller.fetchTasks();
        },
        child: ValueListenableBuilder(
          valueListenable: _controller.tasksApiState,
          builder: (context, taskApiState, _) {
            final tasks = taskApiState.data?.data ?? [];
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Punch In/Out buttons container (takes full width except for submit)
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _punchController.punchStateApiState,
                          builder: (context, punchState, _) {
                            final isLoading = punchState?.isLoading ?? false;
                            final isPunchedIn =
                                _punchController.isPunchedIn.value;
                            final isPunchedOut =
                                _punchController.isPunchedOut.value;
                            final showPunchIn =
                                !isPunchedIn && !isPunchedOut && !isLoading;
                            final showPunchOut =
                                isPunchedIn && !isPunchedOut && !isLoading;
                            if (showPunchIn) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await _punchController.punchInOut('In');
                                    if (_punchController
                                            .punchInOutApiState
                                            .value
                                            ?.isSuccess ??
                                        false) {
                                      showGlobalSnackBar(
                                        'Punch In successful!',
                                      );
                                    } else if (_punchController
                                            .punchInOutApiState
                                            .value
                                            ?.isError ??
                                        false) {
                                      showGlobalSnackBar(
                                        _punchController
                                                .punchInOutApiState
                                                .value
                                                ?.error ??
                                            'Punch In failed!',
                                      );
                                    }
                                  },
                                  child: const Text('Punch In'),
                                ),
                              );
                            } else if (showPunchOut) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await _punchController.punchInOut('out');
                                    if (_punchController
                                            .punchInOutApiState
                                            .value
                                            ?.isSuccess ??
                                        false) {
                                      showGlobalSnackBar(
                                        'Punch Out successful!',
                                      );
                                    } else if (_punchController
                                            .punchInOutApiState
                                            .value
                                            ?.isError ??
                                        false) {
                                      showGlobalSnackBar(
                                        _punchController
                                                .punchInOutApiState
                                                .value
                                                ?.error ??
                                            'Punch Out failed!',
                                      );
                                    }
                                  },
                                  child: const Text('Punch Out'),
                                ),
                              );
                            } else {
                              // Empty container to keep space when both are done
                              return SizedBox(height: 48); // Height of button
                            }
                          },
                        ),
                      ),
                      // Submit button (always on the right)
                      ValueListenableBuilder(
                        valueListenable: _controller.submitTasksApiState,
                        builder: (context, submitState, __) {
                          final showSubmit =
                              tasks.isNotEmpty &&
                              !(submitState.isSuccess || submitState.isLoading);
                          if (!showSubmit) {
                            return const SizedBox.shrink();
                          }
                          return ElevatedButton(
                            onPressed: () async {
                              final tasksResponse =
                                  _controller.tasksApiState.value.data;
                              if (tasksResponse != null) {
                                await _controller.submitTasks(tasksResponse);
                                final submitState =
                                    _controller.submitTasksApiState.value;
                                if (submitState.isSuccess) {
                                  showGlobalSnackBar(
                                    'Tasks submitted successfully!',
                                  );
                                } else if (submitState.isError) {
                                  showGlobalSnackBar(
                                    submitState.error ??
                                        'Task submission failed!',
                                  );
                                }
                              } else {
                                showGlobalSnackBar('No tasks to submit!');
                              }
                            },
                            child: submitState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Submit'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (taskApiState.isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (taskApiState.isError)
                  Center(
                    child: Text(
                      taskApiState.error ?? '',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                      ),
                    ),
                  ),
                if (taskApiState.isSuccess && tasks.isEmpty)
                  Center(
                    child: Text(
                      'No Result Found.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                      ),
                    ),
                  ),
                if (taskApiState.isSuccess && tasks.isNotEmpty)
                  ...tasks.map(
                    (task) => Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        : theme.colorScheme.primary.withValues(
                                            alpha: 0.6,
                                          ),
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
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
