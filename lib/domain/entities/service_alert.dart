class ServiceAlert {
  final String? alertId;
  final String? headerText;
  final String? descriptionText;
  final String? url;
  final List<String> routeIds;
  final List<String> stopIds;
  final int? activePeriodStart;
  final int? activePeriodEnd;

  const ServiceAlert({
    this.alertId,
    this.headerText,
    this.descriptionText,
    this.url,
    this.routeIds = const [],
    this.stopIds = const [],
    this.activePeriodStart,
    this.activePeriodEnd,
  });
}
