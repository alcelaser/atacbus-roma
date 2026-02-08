class CalendarModel {
  final String serviceId;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;
  final String startDate;
  final String endDate;

  const CalendarModel({
    required this.serviceId,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.startDate,
    required this.endDate,
  });

  factory CalendarModel.fromCsvRow(Map<String, String> row) {
    return CalendarModel(
      serviceId: row['service_id'] ?? '',
      monday: row['monday'] == '1',
      tuesday: row['tuesday'] == '1',
      wednesday: row['wednesday'] == '1',
      thursday: row['thursday'] == '1',
      friday: row['friday'] == '1',
      saturday: row['saturday'] == '1',
      sunday: row['sunday'] == '1',
      startDate: row['start_date'] ?? '',
      endDate: row['end_date'] ?? '',
    );
  }

  bool isActiveOnWeekday(int weekday) {
    switch (weekday) {
      case 1: return monday;
      case 2: return tuesday;
      case 3: return wednesday;
      case 4: return thursday;
      case 5: return friday;
      case 6: return saturday;
      case 7: return sunday;
      default: return false;
    }
  }
}
