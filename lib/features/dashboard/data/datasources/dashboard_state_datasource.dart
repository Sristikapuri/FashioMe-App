abstract interface class IDashboardStateDataSource {
  Map<String, dynamic> read();
  Future<void> write(Map<String, dynamic> payload);
}
