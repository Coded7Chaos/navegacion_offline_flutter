class RouteSchedule {
  const RouteSchedule({
    required this.dayDescription,
    required this.startTime,
    required this.endTime,
  });

  final String dayDescription;
  final int startTime;
  final int endTime;

  String get formattedRange => '${_formatHour(startTime)} - ${_formatHour(endTime)}';

  static String _formatHour(int raw) {
    final padded = raw.abs().toString().padLeft(4, '0');
    final hour = int.parse(padded.substring(0, padded.length - 2));
    final minute = int.parse(padded.substring(padded.length - 2));
    final h = hour % 24;
    final m = minute % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
