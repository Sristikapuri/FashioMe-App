const dayAbbreviations = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];


String computeWeekKey(DateTime date) {
  final diff = date.weekday - 1;
  final localMidnight = DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: diff));
  return localMidnight.toUtc().toIso8601String().substring(0, 10);
}

String computeDayAbbrev(DateTime date) => dayAbbreviations[date.weekday - 1];
