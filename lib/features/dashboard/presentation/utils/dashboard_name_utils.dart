String dashboardFirstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Alex';
  return trimmed.split(' ').first;
}

String dashboardInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) return 'AM';
  return parts.map((part) => part[0].toUpperCase()).join();
}
