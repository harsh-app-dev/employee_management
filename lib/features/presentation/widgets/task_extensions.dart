import 'package:employee_management/features/data/models/tasks/task_response.dart';
import 'package:employee_management/features/data/models/tasks/task_history_response.dart';

extension TaskDataExtension on Data {
  String get displayTitle => ticket?.title ?? ticketTitle ?? '';
  String? get displayTicketId => ticketId?.toString();
  String get displayProjectTitle => ticket?.project?.title ?? projectTitle ?? '';
  String get displayDate => createdAt?.substring(0, 10) ?? taskCreatedDate ?? '';
  String? get displayTimeSpend => taskTimeSpend;
  String get displayDescription => _cleanHtmlDescription(taskDescription);
  String get displayPhase => taskPhase ?? '';
}

extension TaskHistoryDataExtension on TaskHistoryData {
  String get displayTitle => ticketTitle ?? '';
  String? get displayTicketId => ticket?.toString();
  String get displayProjectTitle => projectTitle ?? '';
  String get displayDate => createdAt?.substring(0, 10) ?? taskCreatedDate ?? '';
  String? get displayTimeSpend => taskTimeSpend;
  String get displayDescription => _cleanHtmlDescription(taskDescription);
  String get displayPhase => taskPhase ?? '';
}

String _cleanHtmlDescription(String? htmlText) {
  if (htmlText == null || htmlText.isEmpty) return '';
  // Replace <br> tags with newlines
  String cleaned = htmlText
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<br\s+[^>]*/?>', caseSensitive: false), '\n');
  // Remove all other HTML tags
  cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
  // Replace common HTML entities
  cleaned = cleaned
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  // Remove any remaining HTML entities
  cleaned = cleaned.replaceAll(RegExp(r'&[^;]+;'), '');
  // Trim whitespace
  cleaned = cleaned.trim();
  return cleaned;
} 