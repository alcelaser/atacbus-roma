class CalendarDateModel {
  final String serviceId;
  final String date;
  final int exceptionType;

  const CalendarDateModel({
    required this.serviceId,
    required this.date,
    required this.exceptionType,
  });

  factory CalendarDateModel.fromCsvRow(Map<String, String> row) {
    return CalendarDateModel(
      serviceId: row['service_id'] ?? '',
      date: row['date'] ?? '',
      exceptionType: int.tryParse(row['exception_type'] ?? '') ?? 0,
    );
  }
}
