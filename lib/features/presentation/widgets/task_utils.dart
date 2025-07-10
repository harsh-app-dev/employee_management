String formatTimeSpent(String? time) {
  if (time == null || time.isEmpty) return '--:--';
  try {
    final t = time.split(':').map(int.parse).toList();
    final h = t[0], m = t[1];
    return h > 0 && m > 0 ? '${h}h ${m}m' : h > 0 ? '${h}h' : m > 0 ? '${m}m' : '<1m';
  } catch (_) {
    return '--:--';
  }
} 