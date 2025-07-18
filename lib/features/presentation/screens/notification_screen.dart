import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, String>> notifications = [
      {
        'title': 'Leave Approved',
        'message': 'Your casual leave from 10 Jul to 12 Jul has been approved.',
        'date': '09 Jul 2025',
      },
      {
        'title': 'Punch In Reminder',
        'message': 'Don\'t forget to punch in by 10:00 AM today.',
        'date': '08 Jul 2025',
      },
      {
        'title': 'Task Assigned',
        'message': 'A new task has been assigned to you by your manager.',
        'date': '07 Jul 2025',
      },
      {
        'title': 'Leave Rejected',
        'message': 'Your sick leave for 05 Jul 2025 has been rejected.',
        'date': '06 Jul 2025',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.blue),
                    title: Text(notif['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(notif['message'] ?? ''),
                    trailing: Text(notif['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                );
              },
            ),
    );
  }
} 