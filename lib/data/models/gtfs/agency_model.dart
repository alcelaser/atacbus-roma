class AgencyModel {
  final String agencyId;
  final String agencyName;
  final String agencyUrl;
  final String agencyTimezone;
  final String? agencyLang;
  final String? agencyPhone;

  const AgencyModel({
    required this.agencyId,
    required this.agencyName,
    required this.agencyUrl,
    required this.agencyTimezone,
    this.agencyLang,
    this.agencyPhone,
  });

  factory AgencyModel.fromCsvRow(Map<String, String> row) {
    return AgencyModel(
      agencyId: row['agency_id'] ?? '',
      agencyName: row['agency_name'] ?? '',
      agencyUrl: row['agency_url'] ?? '',
      agencyTimezone: row['agency_timezone'] ?? '',
      agencyLang: row['agency_lang'],
      agencyPhone: row['agency_phone'],
    );
  }
}
