class CalendarEventModel {
  final String id;
  final String title;
  final DateTime? start;
  final DateTime? end;
  final bool isAllDay;
  final String? description;
  final String? location;
  final String? colorHex;

  const CalendarEventModel({
    required this.id,
    required this.title,
    this.start,
    this.end,
    this.isAllDay = false,
    this.description,
    this.location,
    this.colorHex,
  });

  /// Whether this event falls on (or spans across) the given date.
  bool occursOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (start == null) return false;
    final eventStart = DateTime(start!.year, start!.month, start!.day);
    if (end == null) return eventStart == day;
    final eventEnd = DateTime(end!.year, end!.month, end!.day);
    return !day.isBefore(eventStart) && !day.isAfter(eventEnd);
  }
}
