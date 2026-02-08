// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GtfsStopsTable extends GtfsStops
    with TableInfo<$GtfsStopsTable, GtfsStop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GtfsStopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stopIdMeta = const VerificationMeta('stopId');
  @override
  late final GeneratedColumn<String> stopId = GeneratedColumn<String>(
      'stop_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stopCodeMeta =
      const VerificationMeta('stopCode');
  @override
  late final GeneratedColumn<String> stopCode = GeneratedColumn<String>(
      'stop_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stopNameMeta =
      const VerificationMeta('stopName');
  @override
  late final GeneratedColumn<String> stopName = GeneratedColumn<String>(
      'stop_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stopDescMeta =
      const VerificationMeta('stopDesc');
  @override
  late final GeneratedColumn<String> stopDesc = GeneratedColumn<String>(
      'stop_desc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stopLatMeta =
      const VerificationMeta('stopLat');
  @override
  late final GeneratedColumn<double> stopLat = GeneratedColumn<double>(
      'stop_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stopLonMeta =
      const VerificationMeta('stopLon');
  @override
  late final GeneratedColumn<double> stopLon = GeneratedColumn<double>(
      'stop_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _locationTypeMeta =
      const VerificationMeta('locationType');
  @override
  late final GeneratedColumn<int> locationType = GeneratedColumn<int>(
      'location_type', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _parentStationMeta =
      const VerificationMeta('parentStation');
  @override
  late final GeneratedColumn<String> parentStation = GeneratedColumn<String>(
      'parent_station', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        stopId,
        stopCode,
        stopName,
        stopDesc,
        stopLat,
        stopLon,
        locationType,
        parentStation
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gtfs_stops';
  @override
  VerificationContext validateIntegrity(Insertable<GtfsStop> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stop_id')) {
      context.handle(_stopIdMeta,
          stopId.isAcceptableOrUnknown(data['stop_id']!, _stopIdMeta));
    } else if (isInserting) {
      context.missing(_stopIdMeta);
    }
    if (data.containsKey('stop_code')) {
      context.handle(_stopCodeMeta,
          stopCode.isAcceptableOrUnknown(data['stop_code']!, _stopCodeMeta));
    }
    if (data.containsKey('stop_name')) {
      context.handle(_stopNameMeta,
          stopName.isAcceptableOrUnknown(data['stop_name']!, _stopNameMeta));
    } else if (isInserting) {
      context.missing(_stopNameMeta);
    }
    if (data.containsKey('stop_desc')) {
      context.handle(_stopDescMeta,
          stopDesc.isAcceptableOrUnknown(data['stop_desc']!, _stopDescMeta));
    }
    if (data.containsKey('stop_lat')) {
      context.handle(_stopLatMeta,
          stopLat.isAcceptableOrUnknown(data['stop_lat']!, _stopLatMeta));
    } else if (isInserting) {
      context.missing(_stopLatMeta);
    }
    if (data.containsKey('stop_lon')) {
      context.handle(_stopLonMeta,
          stopLon.isAcceptableOrUnknown(data['stop_lon']!, _stopLonMeta));
    } else if (isInserting) {
      context.missing(_stopLonMeta);
    }
    if (data.containsKey('location_type')) {
      context.handle(
          _locationTypeMeta,
          locationType.isAcceptableOrUnknown(
              data['location_type']!, _locationTypeMeta));
    }
    if (data.containsKey('parent_station')) {
      context.handle(
          _parentStationMeta,
          parentStation.isAcceptableOrUnknown(
              data['parent_station']!, _parentStationMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stopId};
  @override
  GtfsStop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GtfsStop(
      stopId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stop_id'])!,
      stopCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stop_code']),
      stopName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stop_name'])!,
      stopDesc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stop_desc']),
      stopLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stop_lat'])!,
      stopLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stop_lon'])!,
      locationType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}location_type']),
      parentStation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_station']),
    );
  }

  @override
  $GtfsStopsTable createAlias(String alias) {
    return $GtfsStopsTable(attachedDatabase, alias);
  }
}

class GtfsStop extends DataClass implements Insertable<GtfsStop> {
  final String stopId;
  final String? stopCode;
  final String stopName;
  final String? stopDesc;
  final double stopLat;
  final double stopLon;
  final int? locationType;
  final String? parentStation;
  const GtfsStop(
      {required this.stopId,
      this.stopCode,
      required this.stopName,
      this.stopDesc,
      required this.stopLat,
      required this.stopLon,
      this.locationType,
      this.parentStation});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stop_id'] = Variable<String>(stopId);
    if (!nullToAbsent || stopCode != null) {
      map['stop_code'] = Variable<String>(stopCode);
    }
    map['stop_name'] = Variable<String>(stopName);
    if (!nullToAbsent || stopDesc != null) {
      map['stop_desc'] = Variable<String>(stopDesc);
    }
    map['stop_lat'] = Variable<double>(stopLat);
    map['stop_lon'] = Variable<double>(stopLon);
    if (!nullToAbsent || locationType != null) {
      map['location_type'] = Variable<int>(locationType);
    }
    if (!nullToAbsent || parentStation != null) {
      map['parent_station'] = Variable<String>(parentStation);
    }
    return map;
  }

  GtfsStopsCompanion toCompanion(bool nullToAbsent) {
    return GtfsStopsCompanion(
      stopId: Value(stopId),
      stopCode: stopCode == null && nullToAbsent
          ? const Value.absent()
          : Value(stopCode),
      stopName: Value(stopName),
      stopDesc: stopDesc == null && nullToAbsent
          ? const Value.absent()
          : Value(stopDesc),
      stopLat: Value(stopLat),
      stopLon: Value(stopLon),
      locationType: locationType == null && nullToAbsent
          ? const Value.absent()
          : Value(locationType),
      parentStation: parentStation == null && nullToAbsent
          ? const Value.absent()
          : Value(parentStation),
    );
  }

  factory GtfsStop.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GtfsStop(
      stopId: serializer.fromJson<String>(json['stopId']),
      stopCode: serializer.fromJson<String?>(json['stopCode']),
      stopName: serializer.fromJson<String>(json['stopName']),
      stopDesc: serializer.fromJson<String?>(json['stopDesc']),
      stopLat: serializer.fromJson<double>(json['stopLat']),
      stopLon: serializer.fromJson<double>(json['stopLon']),
      locationType: serializer.fromJson<int?>(json['locationType']),
      parentStation: serializer.fromJson<String?>(json['parentStation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stopId': serializer.toJson<String>(stopId),
      'stopCode': serializer.toJson<String?>(stopCode),
      'stopName': serializer.toJson<String>(stopName),
      'stopDesc': serializer.toJson<String?>(stopDesc),
      'stopLat': serializer.toJson<double>(stopLat),
      'stopLon': serializer.toJson<double>(stopLon),
      'locationType': serializer.toJson<int?>(locationType),
      'parentStation': serializer.toJson<String?>(parentStation),
    };
  }

  GtfsStop copyWith(
          {String? stopId,
          Value<String?> stopCode = const Value.absent(),
          String? stopName,
          Value<String?> stopDesc = const Value.absent(),
          double? stopLat,
          double? stopLon,
          Value<int?> locationType = const Value.absent(),
          Value<String?> parentStation = const Value.absent()}) =>
      GtfsStop(
        stopId: stopId ?? this.stopId,
        stopCode: stopCode.present ? stopCode.value : this.stopCode,
        stopName: stopName ?? this.stopName,
        stopDesc: stopDesc.present ? stopDesc.value : this.stopDesc,
        stopLat: stopLat ?? this.stopLat,
        stopLon: stopLon ?? this.stopLon,
        locationType:
            locationType.present ? locationType.value : this.locationType,
        parentStation:
            parentStation.present ? parentStation.value : this.parentStation,
      );
  @override
  String toString() {
    return (StringBuffer('GtfsStop(')
          ..write('stopId: $stopId, ')
          ..write('stopCode: $stopCode, ')
          ..write('stopName: $stopName, ')
          ..write('stopDesc: $stopDesc, ')
          ..write('stopLat: $stopLat, ')
          ..write('stopLon: $stopLon, ')
          ..write('locationType: $locationType, ')
          ..write('parentStation: $parentStation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stopId, stopCode, stopName, stopDesc, stopLat,
      stopLon, locationType, parentStation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GtfsStop &&
          other.stopId == this.stopId &&
          other.stopCode == this.stopCode &&
          other.stopName == this.stopName &&
          other.stopDesc == this.stopDesc &&
          other.stopLat == this.stopLat &&
          other.stopLon == this.stopLon &&
          other.locationType == this.locationType &&
          other.parentStation == this.parentStation);
}

class GtfsStopsCompanion extends UpdateCompanion<GtfsStop> {
  final Value<String> stopId;
  final Value<String?> stopCode;
  final Value<String> stopName;
  final Value<String?> stopDesc;
  final Value<double> stopLat;
  final Value<double> stopLon;
  final Value<int?> locationType;
  final Value<String?> parentStation;
  final Value<int> rowid;
  const GtfsStopsCompanion({
    this.stopId = const Value.absent(),
    this.stopCode = const Value.absent(),
    this.stopName = const Value.absent(),
    this.stopDesc = const Value.absent(),
    this.stopLat = const Value.absent(),
    this.stopLon = const Value.absent(),
    this.locationType = const Value.absent(),
    this.parentStation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GtfsStopsCompanion.insert({
    required String stopId,
    this.stopCode = const Value.absent(),
    required String stopName,
    this.stopDesc = const Value.absent(),
    required double stopLat,
    required double stopLon,
    this.locationType = const Value.absent(),
    this.parentStation = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : stopId = Value(stopId),
        stopName = Value(stopName),
        stopLat = Value(stopLat),
        stopLon = Value(stopLon);
  static Insertable<GtfsStop> custom({
    Expression<String>? stopId,
    Expression<String>? stopCode,
    Expression<String>? stopName,
    Expression<String>? stopDesc,
    Expression<double>? stopLat,
    Expression<double>? stopLon,
    Expression<int>? locationType,
    Expression<String>? parentStation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stopId != null) 'stop_id': stopId,
      if (stopCode != null) 'stop_code': stopCode,
      if (stopName != null) 'stop_name': stopName,
      if (stopDesc != null) 'stop_desc': stopDesc,
      if (stopLat != null) 'stop_lat': stopLat,
      if (stopLon != null) 'stop_lon': stopLon,
      if (locationType != null) 'location_type': locationType,
      if (parentStation != null) 'parent_station': parentStation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GtfsStopsCompanion copyWith(
      {Value<String>? stopId,
      Value<String?>? stopCode,
      Value<String>? stopName,
      Value<String?>? stopDesc,
      Value<double>? stopLat,
      Value<double>? stopLon,
      Value<int?>? locationType,
      Value<String?>? parentStation,
      Value<int>? rowid}) {
    return GtfsStopsCompanion(
      stopId: stopId ?? this.stopId,
      stopCode: stopCode ?? this.stopCode,
      stopName: stopName ?? this.stopName,
      stopDesc: stopDesc ?? this.stopDesc,
      stopLat: stopLat ?? this.stopLat,
      stopLon: stopLon ?? this.stopLon,
      locationType: locationType ?? this.locationType,
      parentStation: parentStation ?? this.parentStation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stopId.present) {
      map['stop_id'] = Variable<String>(stopId.value);
    }
    if (stopCode.present) {
      map['stop_code'] = Variable<String>(stopCode.value);
    }
    if (stopName.present) {
      map['stop_name'] = Variable<String>(stopName.value);
    }
    if (stopDesc.present) {
      map['stop_desc'] = Variable<String>(stopDesc.value);
    }
    if (stopLat.present) {
      map['stop_lat'] = Variable<double>(stopLat.value);
    }
    if (stopLon.present) {
      map['stop_lon'] = Variable<double>(stopLon.value);
    }
    if (locationType.present) {
      map['location_type'] = Variable<int>(locationType.value);
    }
    if (parentStation.present) {
      map['parent_station'] = Variable<String>(parentStation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GtfsStopsCompanion(')
          ..write('stopId: $stopId, ')
          ..write('stopCode: $stopCode, ')
          ..write('stopName: $stopName, ')
          ..write('stopDesc: $stopDesc, ')
          ..write('stopLat: $stopLat, ')
          ..write('stopLon: $stopLon, ')
          ..write('locationType: $locationType, ')
          ..write('parentStation: $parentStation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GtfsRoutesTable extends GtfsRoutes
    with TableInfo<$GtfsRoutesTable, GtfsRoute> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GtfsRoutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routeIdMeta =
      const VerificationMeta('routeId');
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
      'route_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agencyIdMeta =
      const VerificationMeta('agencyId');
  @override
  late final GeneratedColumn<String> agencyId = GeneratedColumn<String>(
      'agency_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _routeShortNameMeta =
      const VerificationMeta('routeShortName');
  @override
  late final GeneratedColumn<String> routeShortName = GeneratedColumn<String>(
      'route_short_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _routeLongNameMeta =
      const VerificationMeta('routeLongName');
  @override
  late final GeneratedColumn<String> routeLongName = GeneratedColumn<String>(
      'route_long_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _routeTypeMeta =
      const VerificationMeta('routeType');
  @override
  late final GeneratedColumn<int> routeType = GeneratedColumn<int>(
      'route_type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _routeColorMeta =
      const VerificationMeta('routeColor');
  @override
  late final GeneratedColumn<String> routeColor = GeneratedColumn<String>(
      'route_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _routeTextColorMeta =
      const VerificationMeta('routeTextColor');
  @override
  late final GeneratedColumn<String> routeTextColor = GeneratedColumn<String>(
      'route_text_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _routeDescMeta =
      const VerificationMeta('routeDesc');
  @override
  late final GeneratedColumn<String> routeDesc = GeneratedColumn<String>(
      'route_desc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        routeId,
        agencyId,
        routeShortName,
        routeLongName,
        routeType,
        routeColor,
        routeTextColor,
        routeDesc
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gtfs_routes';
  @override
  VerificationContext validateIntegrity(Insertable<GtfsRoute> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('route_id')) {
      context.handle(_routeIdMeta,
          routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta));
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('agency_id')) {
      context.handle(_agencyIdMeta,
          agencyId.isAcceptableOrUnknown(data['agency_id']!, _agencyIdMeta));
    }
    if (data.containsKey('route_short_name')) {
      context.handle(
          _routeShortNameMeta,
          routeShortName.isAcceptableOrUnknown(
              data['route_short_name']!, _routeShortNameMeta));
    } else if (isInserting) {
      context.missing(_routeShortNameMeta);
    }
    if (data.containsKey('route_long_name')) {
      context.handle(
          _routeLongNameMeta,
          routeLongName.isAcceptableOrUnknown(
              data['route_long_name']!, _routeLongNameMeta));
    } else if (isInserting) {
      context.missing(_routeLongNameMeta);
    }
    if (data.containsKey('route_type')) {
      context.handle(_routeTypeMeta,
          routeType.isAcceptableOrUnknown(data['route_type']!, _routeTypeMeta));
    } else if (isInserting) {
      context.missing(_routeTypeMeta);
    }
    if (data.containsKey('route_color')) {
      context.handle(
          _routeColorMeta,
          routeColor.isAcceptableOrUnknown(
              data['route_color']!, _routeColorMeta));
    }
    if (data.containsKey('route_text_color')) {
      context.handle(
          _routeTextColorMeta,
          routeTextColor.isAcceptableOrUnknown(
              data['route_text_color']!, _routeTextColorMeta));
    }
    if (data.containsKey('route_desc')) {
      context.handle(_routeDescMeta,
          routeDesc.isAcceptableOrUnknown(data['route_desc']!, _routeDescMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routeId};
  @override
  GtfsRoute map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GtfsRoute(
      routeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_id'])!,
      agencyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agency_id']),
      routeShortName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}route_short_name'])!,
      routeLongName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}route_long_name'])!,
      routeType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}route_type'])!,
      routeColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_color']),
      routeTextColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}route_text_color']),
      routeDesc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_desc']),
    );
  }

  @override
  $GtfsRoutesTable createAlias(String alias) {
    return $GtfsRoutesTable(attachedDatabase, alias);
  }
}

class GtfsRoute extends DataClass implements Insertable<GtfsRoute> {
  final String routeId;
  final String? agencyId;
  final String routeShortName;
  final String routeLongName;
  final int routeType;
  final String? routeColor;
  final String? routeTextColor;
  final String? routeDesc;
  const GtfsRoute(
      {required this.routeId,
      this.agencyId,
      required this.routeShortName,
      required this.routeLongName,
      required this.routeType,
      this.routeColor,
      this.routeTextColor,
      this.routeDesc});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['route_id'] = Variable<String>(routeId);
    if (!nullToAbsent || agencyId != null) {
      map['agency_id'] = Variable<String>(agencyId);
    }
    map['route_short_name'] = Variable<String>(routeShortName);
    map['route_long_name'] = Variable<String>(routeLongName);
    map['route_type'] = Variable<int>(routeType);
    if (!nullToAbsent || routeColor != null) {
      map['route_color'] = Variable<String>(routeColor);
    }
    if (!nullToAbsent || routeTextColor != null) {
      map['route_text_color'] = Variable<String>(routeTextColor);
    }
    if (!nullToAbsent || routeDesc != null) {
      map['route_desc'] = Variable<String>(routeDesc);
    }
    return map;
  }

  GtfsRoutesCompanion toCompanion(bool nullToAbsent) {
    return GtfsRoutesCompanion(
      routeId: Value(routeId),
      agencyId: agencyId == null && nullToAbsent
          ? const Value.absent()
          : Value(agencyId),
      routeShortName: Value(routeShortName),
      routeLongName: Value(routeLongName),
      routeType: Value(routeType),
      routeColor: routeColor == null && nullToAbsent
          ? const Value.absent()
          : Value(routeColor),
      routeTextColor: routeTextColor == null && nullToAbsent
          ? const Value.absent()
          : Value(routeTextColor),
      routeDesc: routeDesc == null && nullToAbsent
          ? const Value.absent()
          : Value(routeDesc),
    );
  }

  factory GtfsRoute.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GtfsRoute(
      routeId: serializer.fromJson<String>(json['routeId']),
      agencyId: serializer.fromJson<String?>(json['agencyId']),
      routeShortName: serializer.fromJson<String>(json['routeShortName']),
      routeLongName: serializer.fromJson<String>(json['routeLongName']),
      routeType: serializer.fromJson<int>(json['routeType']),
      routeColor: serializer.fromJson<String?>(json['routeColor']),
      routeTextColor: serializer.fromJson<String?>(json['routeTextColor']),
      routeDesc: serializer.fromJson<String?>(json['routeDesc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routeId': serializer.toJson<String>(routeId),
      'agencyId': serializer.toJson<String?>(agencyId),
      'routeShortName': serializer.toJson<String>(routeShortName),
      'routeLongName': serializer.toJson<String>(routeLongName),
      'routeType': serializer.toJson<int>(routeType),
      'routeColor': serializer.toJson<String?>(routeColor),
      'routeTextColor': serializer.toJson<String?>(routeTextColor),
      'routeDesc': serializer.toJson<String?>(routeDesc),
    };
  }

  GtfsRoute copyWith(
          {String? routeId,
          Value<String?> agencyId = const Value.absent(),
          String? routeShortName,
          String? routeLongName,
          int? routeType,
          Value<String?> routeColor = const Value.absent(),
          Value<String?> routeTextColor = const Value.absent(),
          Value<String?> routeDesc = const Value.absent()}) =>
      GtfsRoute(
        routeId: routeId ?? this.routeId,
        agencyId: agencyId.present ? agencyId.value : this.agencyId,
        routeShortName: routeShortName ?? this.routeShortName,
        routeLongName: routeLongName ?? this.routeLongName,
        routeType: routeType ?? this.routeType,
        routeColor: routeColor.present ? routeColor.value : this.routeColor,
        routeTextColor:
            routeTextColor.present ? routeTextColor.value : this.routeTextColor,
        routeDesc: routeDesc.present ? routeDesc.value : this.routeDesc,
      );
  @override
  String toString() {
    return (StringBuffer('GtfsRoute(')
          ..write('routeId: $routeId, ')
          ..write('agencyId: $agencyId, ')
          ..write('routeShortName: $routeShortName, ')
          ..write('routeLongName: $routeLongName, ')
          ..write('routeType: $routeType, ')
          ..write('routeColor: $routeColor, ')
          ..write('routeTextColor: $routeTextColor, ')
          ..write('routeDesc: $routeDesc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(routeId, agencyId, routeShortName,
      routeLongName, routeType, routeColor, routeTextColor, routeDesc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GtfsRoute &&
          other.routeId == this.routeId &&
          other.agencyId == this.agencyId &&
          other.routeShortName == this.routeShortName &&
          other.routeLongName == this.routeLongName &&
          other.routeType == this.routeType &&
          other.routeColor == this.routeColor &&
          other.routeTextColor == this.routeTextColor &&
          other.routeDesc == this.routeDesc);
}

class GtfsRoutesCompanion extends UpdateCompanion<GtfsRoute> {
  final Value<String> routeId;
  final Value<String?> agencyId;
  final Value<String> routeShortName;
  final Value<String> routeLongName;
  final Value<int> routeType;
  final Value<String?> routeColor;
  final Value<String?> routeTextColor;
  final Value<String?> routeDesc;
  final Value<int> rowid;
  const GtfsRoutesCompanion({
    this.routeId = const Value.absent(),
    this.agencyId = const Value.absent(),
    this.routeShortName = const Value.absent(),
    this.routeLongName = const Value.absent(),
    this.routeType = const Value.absent(),
    this.routeColor = const Value.absent(),
    this.routeTextColor = const Value.absent(),
    this.routeDesc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GtfsRoutesCompanion.insert({
    required String routeId,
    this.agencyId = const Value.absent(),
    required String routeShortName,
    required String routeLongName,
    required int routeType,
    this.routeColor = const Value.absent(),
    this.routeTextColor = const Value.absent(),
    this.routeDesc = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : routeId = Value(routeId),
        routeShortName = Value(routeShortName),
        routeLongName = Value(routeLongName),
        routeType = Value(routeType);
  static Insertable<GtfsRoute> custom({
    Expression<String>? routeId,
    Expression<String>? agencyId,
    Expression<String>? routeShortName,
    Expression<String>? routeLongName,
    Expression<int>? routeType,
    Expression<String>? routeColor,
    Expression<String>? routeTextColor,
    Expression<String>? routeDesc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routeId != null) 'route_id': routeId,
      if (agencyId != null) 'agency_id': agencyId,
      if (routeShortName != null) 'route_short_name': routeShortName,
      if (routeLongName != null) 'route_long_name': routeLongName,
      if (routeType != null) 'route_type': routeType,
      if (routeColor != null) 'route_color': routeColor,
      if (routeTextColor != null) 'route_text_color': routeTextColor,
      if (routeDesc != null) 'route_desc': routeDesc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GtfsRoutesCompanion copyWith(
      {Value<String>? routeId,
      Value<String?>? agencyId,
      Value<String>? routeShortName,
      Value<String>? routeLongName,
      Value<int>? routeType,
      Value<String?>? routeColor,
      Value<String?>? routeTextColor,
      Value<String?>? routeDesc,
      Value<int>? rowid}) {
    return GtfsRoutesCompanion(
      routeId: routeId ?? this.routeId,
      agencyId: agencyId ?? this.agencyId,
      routeShortName: routeShortName ?? this.routeShortName,
      routeLongName: routeLongName ?? this.routeLongName,
      routeType: routeType ?? this.routeType,
      routeColor: routeColor ?? this.routeColor,
      routeTextColor: routeTextColor ?? this.routeTextColor,
      routeDesc: routeDesc ?? this.routeDesc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (agencyId.present) {
      map['agency_id'] = Variable<String>(agencyId.value);
    }
    if (routeShortName.present) {
      map['route_short_name'] = Variable<String>(routeShortName.value);
    }
    if (routeLongName.present) {
      map['route_long_name'] = Variable<String>(routeLongName.value);
    }
    if (routeType.present) {
      map['route_type'] = Variable<int>(routeType.value);
    }
    if (routeColor.present) {
      map['route_color'] = Variable<String>(routeColor.value);
    }
    if (routeTextColor.present) {
      map['route_text_color'] = Variable<String>(routeTextColor.value);
    }
    if (routeDesc.present) {
      map['route_desc'] = Variable<String>(routeDesc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GtfsRoutesCompanion(')
          ..write('routeId: $routeId, ')
          ..write('agencyId: $agencyId, ')
          ..write('routeShortName: $routeShortName, ')
          ..write('routeLongName: $routeLongName, ')
          ..write('routeType: $routeType, ')
          ..write('routeColor: $routeColor, ')
          ..write('routeTextColor: $routeTextColor, ')
          ..write('routeDesc: $routeDesc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GtfsTripsTable extends GtfsTrips
    with TableInfo<$GtfsTripsTable, GtfsTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GtfsTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _routeIdMeta =
      const VerificationMeta('routeId');
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
      'route_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serviceIdMeta =
      const VerificationMeta('serviceId');
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
      'service_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tripHeadsignMeta =
      const VerificationMeta('tripHeadsign');
  @override
  late final GeneratedColumn<String> tripHeadsign = GeneratedColumn<String>(
      'trip_headsign', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tripShortNameMeta =
      const VerificationMeta('tripShortName');
  @override
  late final GeneratedColumn<String> tripShortName = GeneratedColumn<String>(
      'trip_short_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _directionIdMeta =
      const VerificationMeta('directionId');
  @override
  late final GeneratedColumn<int> directionId = GeneratedColumn<int>(
      'direction_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _shapeIdMeta =
      const VerificationMeta('shapeId');
  @override
  late final GeneratedColumn<String> shapeId = GeneratedColumn<String>(
      'shape_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        tripId,
        routeId,
        serviceId,
        tripHeadsign,
        tripShortName,
        directionId,
        shapeId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gtfs_trips';
  @override
  VerificationContext validateIntegrity(Insertable<GtfsTrip> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('route_id')) {
      context.handle(_routeIdMeta,
          routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta));
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(_serviceIdMeta,
          serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta));
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('trip_headsign')) {
      context.handle(
          _tripHeadsignMeta,
          tripHeadsign.isAcceptableOrUnknown(
              data['trip_headsign']!, _tripHeadsignMeta));
    }
    if (data.containsKey('trip_short_name')) {
      context.handle(
          _tripShortNameMeta,
          tripShortName.isAcceptableOrUnknown(
              data['trip_short_name']!, _tripShortNameMeta));
    }
    if (data.containsKey('direction_id')) {
      context.handle(
          _directionIdMeta,
          directionId.isAcceptableOrUnknown(
              data['direction_id']!, _directionIdMeta));
    }
    if (data.containsKey('shape_id')) {
      context.handle(_shapeIdMeta,
          shapeId.isAcceptableOrUnknown(data['shape_id']!, _shapeIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tripId};
  @override
  GtfsTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GtfsTrip(
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trip_id'])!,
      routeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_id'])!,
      serviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}service_id'])!,
      tripHeadsign: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trip_headsign']),
      tripShortName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trip_short_name']),
      directionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}direction_id']),
      shapeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shape_id']),
    );
  }

  @override
  $GtfsTripsTable createAlias(String alias) {
    return $GtfsTripsTable(attachedDatabase, alias);
  }
}

class GtfsTrip extends DataClass implements Insertable<GtfsTrip> {
  final String tripId;
  final String routeId;
  final String serviceId;
  final String? tripHeadsign;
  final String? tripShortName;
  final int? directionId;
  final String? shapeId;
  const GtfsTrip(
      {required this.tripId,
      required this.routeId,
      required this.serviceId,
      this.tripHeadsign,
      this.tripShortName,
      this.directionId,
      this.shapeId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    map['route_id'] = Variable<String>(routeId);
    map['service_id'] = Variable<String>(serviceId);
    if (!nullToAbsent || tripHeadsign != null) {
      map['trip_headsign'] = Variable<String>(tripHeadsign);
    }
    if (!nullToAbsent || tripShortName != null) {
      map['trip_short_name'] = Variable<String>(tripShortName);
    }
    if (!nullToAbsent || directionId != null) {
      map['direction_id'] = Variable<int>(directionId);
    }
    if (!nullToAbsent || shapeId != null) {
      map['shape_id'] = Variable<String>(shapeId);
    }
    return map;
  }

  GtfsTripsCompanion toCompanion(bool nullToAbsent) {
    return GtfsTripsCompanion(
      tripId: Value(tripId),
      routeId: Value(routeId),
      serviceId: Value(serviceId),
      tripHeadsign: tripHeadsign == null && nullToAbsent
          ? const Value.absent()
          : Value(tripHeadsign),
      tripShortName: tripShortName == null && nullToAbsent
          ? const Value.absent()
          : Value(tripShortName),
      directionId: directionId == null && nullToAbsent
          ? const Value.absent()
          : Value(directionId),
      shapeId: shapeId == null && nullToAbsent
          ? const Value.absent()
          : Value(shapeId),
    );
  }

  factory GtfsTrip.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GtfsTrip(
      tripId: serializer.fromJson<String>(json['tripId']),
      routeId: serializer.fromJson<String>(json['routeId']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      tripHeadsign: serializer.fromJson<String?>(json['tripHeadsign']),
      tripShortName: serializer.fromJson<String?>(json['tripShortName']),
      directionId: serializer.fromJson<int?>(json['directionId']),
      shapeId: serializer.fromJson<String?>(json['shapeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'routeId': serializer.toJson<String>(routeId),
      'serviceId': serializer.toJson<String>(serviceId),
      'tripHeadsign': serializer.toJson<String?>(tripHeadsign),
      'tripShortName': serializer.toJson<String?>(tripShortName),
      'directionId': serializer.toJson<int?>(directionId),
      'shapeId': serializer.toJson<String?>(shapeId),
    };
  }

  GtfsTrip copyWith(
          {String? tripId,
          String? routeId,
          String? serviceId,
          Value<String?> tripHeadsign = const Value.absent(),
          Value<String?> tripShortName = const Value.absent(),
          Value<int?> directionId = const Value.absent(),
          Value<String?> shapeId = const Value.absent()}) =>
      GtfsTrip(
        tripId: tripId ?? this.tripId,
        routeId: routeId ?? this.routeId,
        serviceId: serviceId ?? this.serviceId,
        tripHeadsign:
            tripHeadsign.present ? tripHeadsign.value : this.tripHeadsign,
        tripShortName:
            tripShortName.present ? tripShortName.value : this.tripShortName,
        directionId: directionId.present ? directionId.value : this.directionId,
        shapeId: shapeId.present ? shapeId.value : this.shapeId,
      );
  @override
  String toString() {
    return (StringBuffer('GtfsTrip(')
          ..write('tripId: $tripId, ')
          ..write('routeId: $routeId, ')
          ..write('serviceId: $serviceId, ')
          ..write('tripHeadsign: $tripHeadsign, ')
          ..write('tripShortName: $tripShortName, ')
          ..write('directionId: $directionId, ')
          ..write('shapeId: $shapeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tripId, routeId, serviceId, tripHeadsign,
      tripShortName, directionId, shapeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GtfsTrip &&
          other.tripId == this.tripId &&
          other.routeId == this.routeId &&
          other.serviceId == this.serviceId &&
          other.tripHeadsign == this.tripHeadsign &&
          other.tripShortName == this.tripShortName &&
          other.directionId == this.directionId &&
          other.shapeId == this.shapeId);
}

class GtfsTripsCompanion extends UpdateCompanion<GtfsTrip> {
  final Value<String> tripId;
  final Value<String> routeId;
  final Value<String> serviceId;
  final Value<String?> tripHeadsign;
  final Value<String?> tripShortName;
  final Value<int?> directionId;
  final Value<String?> shapeId;
  final Value<int> rowid;
  const GtfsTripsCompanion({
    this.tripId = const Value.absent(),
    this.routeId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.tripHeadsign = const Value.absent(),
    this.tripShortName = const Value.absent(),
    this.directionId = const Value.absent(),
    this.shapeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GtfsTripsCompanion.insert({
    required String tripId,
    required String routeId,
    required String serviceId,
    this.tripHeadsign = const Value.absent(),
    this.tripShortName = const Value.absent(),
    this.directionId = const Value.absent(),
    this.shapeId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : tripId = Value(tripId),
        routeId = Value(routeId),
        serviceId = Value(serviceId);
  static Insertable<GtfsTrip> custom({
    Expression<String>? tripId,
    Expression<String>? routeId,
    Expression<String>? serviceId,
    Expression<String>? tripHeadsign,
    Expression<String>? tripShortName,
    Expression<int>? directionId,
    Expression<String>? shapeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (routeId != null) 'route_id': routeId,
      if (serviceId != null) 'service_id': serviceId,
      if (tripHeadsign != null) 'trip_headsign': tripHeadsign,
      if (tripShortName != null) 'trip_short_name': tripShortName,
      if (directionId != null) 'direction_id': directionId,
      if (shapeId != null) 'shape_id': shapeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GtfsTripsCompanion copyWith(
      {Value<String>? tripId,
      Value<String>? routeId,
      Value<String>? serviceId,
      Value<String?>? tripHeadsign,
      Value<String?>? tripShortName,
      Value<int?>? directionId,
      Value<String?>? shapeId,
      Value<int>? rowid}) {
    return GtfsTripsCompanion(
      tripId: tripId ?? this.tripId,
      routeId: routeId ?? this.routeId,
      serviceId: serviceId ?? this.serviceId,
      tripHeadsign: tripHeadsign ?? this.tripHeadsign,
      tripShortName: tripShortName ?? this.tripShortName,
      directionId: directionId ?? this.directionId,
      shapeId: shapeId ?? this.shapeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (tripHeadsign.present) {
      map['trip_headsign'] = Variable<String>(tripHeadsign.value);
    }
    if (tripShortName.present) {
      map['trip_short_name'] = Variable<String>(tripShortName.value);
    }
    if (directionId.present) {
      map['direction_id'] = Variable<int>(directionId.value);
    }
    if (shapeId.present) {
      map['shape_id'] = Variable<String>(shapeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GtfsTripsCompanion(')
          ..write('tripId: $tripId, ')
          ..write('routeId: $routeId, ')
          ..write('serviceId: $serviceId, ')
          ..write('tripHeadsign: $tripHeadsign, ')
          ..write('tripShortName: $tripShortName, ')
          ..write('directionId: $directionId, ')
          ..write('shapeId: $shapeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GtfsStopTimesTable extends GtfsStopTimes
    with TableInfo<$GtfsStopTimesTable, GtfsStopTime> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GtfsStopTimesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _arrivalTimeMeta =
      const VerificationMeta('arrivalTime');
  @override
  late final GeneratedColumn<String> arrivalTime = GeneratedColumn<String>(
      'arrival_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _departureTimeMeta =
      const VerificationMeta('departureTime');
  @override
  late final GeneratedColumn<String> departureTime = GeneratedColumn<String>(
      'departure_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stopIdMeta = const VerificationMeta('stopId');
  @override
  late final GeneratedColumn<String> stopId = GeneratedColumn<String>(
      'stop_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stopSequenceMeta =
      const VerificationMeta('stopSequence');
  @override
  late final GeneratedColumn<int> stopSequence = GeneratedColumn<int>(
      'stop_sequence', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stopHeadsignMeta =
      const VerificationMeta('stopHeadsign');
  @override
  late final GeneratedColumn<String> stopHeadsign = GeneratedColumn<String>(
      'stop_headsign', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pickupTypeMeta =
      const VerificationMeta('pickupType');
  @override
  late final GeneratedColumn<int> pickupType = GeneratedColumn<int>(
      'pickup_type', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dropOffTypeMeta =
      const VerificationMeta('dropOffType');
  @override
  late final GeneratedColumn<int> dropOffType = GeneratedColumn<int>(
      'drop_off_type', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        tripId,
        arrivalTime,
        departureTime,
        stopId,
        stopSequence,
        stopHeadsign,
        pickupType,
        dropOffType
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gtfs_stop_times';
  @override
  VerificationContext validateIntegrity(Insertable<GtfsStopTime> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('arrival_time')) {
      context.handle(
          _arrivalTimeMeta,
          arrivalTime.isAcceptableOrUnknown(
              data['arrival_time']!, _arrivalTimeMeta));
    } else if (isInserting) {
      context.missing(_arrivalTimeMeta);
    }
    if (data.containsKey('departure_time')) {
      context.handle(
          _departureTimeMeta,
          departureTime.isAcceptableOrUnknown(
              data['departure_time']!, _departureTimeMeta));
    } else if (isInserting) {
      context.missing(_departureTimeMeta);
    }
    if (data.containsKey('stop_id')) {
      context.handle(_stopIdMeta,
          stopId.isAcceptableOrUnknown(data['stop_id']!, _stopIdMeta));
    } else if (isInserting) {
      context.missing(_stopIdMeta);
    }
    if (data.containsKey('stop_sequence')) {
      context.handle(
          _stopSequenceMeta,
          stopSequence.isAcceptableOrUnknown(
              data['stop_sequence']!, _stopSequenceMeta));
    } else if (isInserting) {
      context.missing(_stopSequenceMeta);
    }
    if (data.containsKey('stop_headsign')) {
      context.handle(
          _stopHeadsignMeta,
          stopHeadsign.isAcceptableOrUnknown(
              data['stop_headsign']!, _stopHeadsignMeta));
    }
    if (data.containsKey('pickup_type')) {
      context.handle(
          _pickupTypeMeta,
          pickupType.isAcceptableOrUnknown(
              data['pickup_type']!, _pickupTypeMeta));
    }
    if (data.containsKey('drop_off_type')) {
      context.handle(
          _dropOffTypeMeta,
          dropOffType.isAcceptableOrUnknown(
              data['drop_off_type']!, _dropOffTypeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tripId, stopSequence};
  @override
  GtfsStopTime map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GtfsStopTime(
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trip_id'])!,
      arrivalTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}arrival_time'])!,
      departureTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}departure_time'])!,
      stopId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stop_id'])!,
      stopSequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stop_sequence'])!,
      stopHeadsign: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stop_headsign']),
      pickupType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pickup_type']),
      dropOffType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}drop_off_type']),
    );
  }

  @override
  $GtfsStopTimesTable createAlias(String alias) {
    return $GtfsStopTimesTable(attachedDatabase, alias);
  }
}

class GtfsStopTime extends DataClass implements Insertable<GtfsStopTime> {
  final String tripId;
  final String arrivalTime;
  final String departureTime;
  final String stopId;
  final int stopSequence;
  final String? stopHeadsign;
  final int? pickupType;
  final int? dropOffType;
  const GtfsStopTime(
      {required this.tripId,
      required this.arrivalTime,
      required this.departureTime,
      required this.stopId,
      required this.stopSequence,
      this.stopHeadsign,
      this.pickupType,
      this.dropOffType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    map['arrival_time'] = Variable<String>(arrivalTime);
    map['departure_time'] = Variable<String>(departureTime);
    map['stop_id'] = Variable<String>(stopId);
    map['stop_sequence'] = Variable<int>(stopSequence);
    if (!nullToAbsent || stopHeadsign != null) {
      map['stop_headsign'] = Variable<String>(stopHeadsign);
    }
    if (!nullToAbsent || pickupType != null) {
      map['pickup_type'] = Variable<int>(pickupType);
    }
    if (!nullToAbsent || dropOffType != null) {
      map['drop_off_type'] = Variable<int>(dropOffType);
    }
    return map;
  }

  GtfsStopTimesCompanion toCompanion(bool nullToAbsent) {
    return GtfsStopTimesCompanion(
      tripId: Value(tripId),
      arrivalTime: Value(arrivalTime),
      departureTime: Value(departureTime),
      stopId: Value(stopId),
      stopSequence: Value(stopSequence),
      stopHeadsign: stopHeadsign == null && nullToAbsent
          ? const Value.absent()
          : Value(stopHeadsign),
      pickupType: pickupType == null && nullToAbsent
          ? const Value.absent()
          : Value(pickupType),
      dropOffType: dropOffType == null && nullToAbsent
          ? const Value.absent()
          : Value(dropOffType),
    );
  }

  factory GtfsStopTime.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GtfsStopTime(
      tripId: serializer.fromJson<String>(json['tripId']),
      arrivalTime: serializer.fromJson<String>(json['arrivalTime']),
      departureTime: serializer.fromJson<String>(json['departureTime']),
      stopId: serializer.fromJson<String>(json['stopId']),
      stopSequence: serializer.fromJson<int>(json['stopSequence']),
      stopHeadsign: serializer.fromJson<String?>(json['stopHeadsign']),
      pickupType: serializer.fromJson<int?>(json['pickupType']),
      dropOffType: serializer.fromJson<int?>(json['dropOffType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'arrivalTime': serializer.toJson<String>(arrivalTime),
      'departureTime': serializer.toJson<String>(departureTime),
      'stopId': serializer.toJson<String>(stopId),
      'stopSequence': serializer.toJson<int>(stopSequence),
      'stopHeadsign': serializer.toJson<String?>(stopHeadsign),
      'pickupType': serializer.toJson<int?>(pickupType),
      'dropOffType': serializer.toJson<int?>(dropOffType),
    };
  }

  GtfsStopTime copyWith(
          {String? tripId,
          String? arrivalTime,
          String? departureTime,
          String? stopId,
          int? stopSequence,
          Value<String?> stopHeadsign = const Value.absent(),
          Value<int?> pickupType = const Value.absent(),
          Value<int?> dropOffType = const Value.absent()}) =>
      GtfsStopTime(
        tripId: tripId ?? this.tripId,
        arrivalTime: arrivalTime ?? this.arrivalTime,
        departureTime: departureTime ?? this.departureTime,
        stopId: stopId ?? this.stopId,
        stopSequence: stopSequence ?? this.stopSequence,
        stopHeadsign:
            stopHeadsign.present ? stopHeadsign.value : this.stopHeadsign,
        pickupType: pickupType.present ? pickupType.value : this.pickupType,
        dropOffType: dropOffType.present ? dropOffType.value : this.dropOffType,
      );
  @override
  String toString() {
    return (StringBuffer('GtfsStopTime(')
          ..write('tripId: $tripId, ')
          ..write('arrivalTime: $arrivalTime, ')
          ..write('departureTime: $departureTime, ')
          ..write('stopId: $stopId, ')
          ..write('stopSequence: $stopSequence, ')
          ..write('stopHeadsign: $stopHeadsign, ')
          ..write('pickupType: $pickupType, ')
          ..write('dropOffType: $dropOffType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tripId, arrivalTime, departureTime, stopId,
      stopSequence, stopHeadsign, pickupType, dropOffType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GtfsStopTime &&
          other.tripId == this.tripId &&
          other.arrivalTime == this.arrivalTime &&
          other.departureTime == this.departureTime &&
          other.stopId == this.stopId &&
          other.stopSequence == this.stopSequence &&
          other.stopHeadsign == this.stopHeadsign &&
          other.pickupType == this.pickupType &&
          other.dropOffType == this.dropOffType);
}

class GtfsStopTimesCompanion extends UpdateCompanion<GtfsStopTime> {
  final Value<String> tripId;
  final Value<String> arrivalTime;
  final Value<String> departureTime;
  final Value<String> stopId;
  final Value<int> stopSequence;
  final Value<String?> stopHeadsign;
  final Value<int?> pickupType;
  final Value<int?> dropOffType;
  final Value<int> rowid;
  const GtfsStopTimesCompanion({
    this.tripId = const Value.absent(),
    this.arrivalTime = const Value.absent(),
    this.departureTime = const Value.absent(),
    this.stopId = const Value.absent(),
    this.stopSequence = const Value.absent(),
    this.stopHeadsign = const Value.absent(),
    this.pickupType = const Value.absent(),
    this.dropOffType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GtfsStopTimesCompanion.insert({
    required String tripId,
    required String arrivalTime,
    required String departureTime,
    required String stopId,
    required int stopSequence,
    this.stopHeadsign = const Value.absent(),
    this.pickupType = const Value.absent(),
    this.dropOffType = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : tripId = Value(tripId),
        arrivalTime = Value(arrivalTime),
        departureTime = Value(departureTime),
        stopId = Value(stopId),
        stopSequence = Value(stopSequence);
  static Insertable<GtfsStopTime> custom({
    Expression<String>? tripId,
    Expression<String>? arrivalTime,
    Expression<String>? departureTime,
    Expression<String>? stopId,
    Expression<int>? stopSequence,
    Expression<String>? stopHeadsign,
    Expression<int>? pickupType,
    Expression<int>? dropOffType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (arrivalTime != null) 'arrival_time': arrivalTime,
      if (departureTime != null) 'departure_time': departureTime,
      if (stopId != null) 'stop_id': stopId,
      if (stopSequence != null) 'stop_sequence': stopSequence,
      if (stopHeadsign != null) 'stop_headsign': stopHeadsign,
      if (pickupType != null) 'pickup_type': pickupType,
      if (dropOffType != null) 'drop_off_type': dropOffType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GtfsStopTimesCompanion copyWith(
      {Value<String>? tripId,
      Value<String>? arrivalTime,
      Value<String>? departureTime,
      Value<String>? stopId,
      Value<int>? stopSequence,
      Value<String?>? stopHeadsign,
      Value<int?>? pickupType,
      Value<int?>? dropOffType,
      Value<int>? rowid}) {
    return GtfsStopTimesCompanion(
      tripId: tripId ?? this.tripId,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      stopId: stopId ?? this.stopId,
      stopSequence: stopSequence ?? this.stopSequence,
      stopHeadsign: stopHeadsign ?? this.stopHeadsign,
      pickupType: pickupType ?? this.pickupType,
      dropOffType: dropOffType ?? this.dropOffType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (arrivalTime.present) {
      map['arrival_time'] = Variable<String>(arrivalTime.value);
    }
    if (departureTime.present) {
      map['departure_time'] = Variable<String>(departureTime.value);
    }
    if (stopId.present) {
      map['stop_id'] = Variable<String>(stopId.value);
    }
    if (stopSequence.present) {
      map['stop_sequence'] = Variable<int>(stopSequence.value);
    }
    if (stopHeadsign.present) {
      map['stop_headsign'] = Variable<String>(stopHeadsign.value);
    }
    if (pickupType.present) {
      map['pickup_type'] = Variable<int>(pickupType.value);
    }
    if (dropOffType.present) {
      map['drop_off_type'] = Variable<int>(dropOffType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GtfsStopTimesCompanion(')
          ..write('tripId: $tripId, ')
          ..write('arrivalTime: $arrivalTime, ')
          ..write('departureTime: $departureTime, ')
          ..write('stopId: $stopId, ')
          ..write('stopSequence: $stopSequence, ')
          ..write('stopHeadsign: $stopHeadsign, ')
          ..write('pickupType: $pickupType, ')
          ..write('dropOffType: $dropOffType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GtfsCalendarTable extends GtfsCalendar
    with TableInfo<$GtfsCalendarTable, GtfsCalendarData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GtfsCalendarTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serviceIdMeta =
      const VerificationMeta('serviceId');
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
      'service_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mondayMeta = const VerificationMeta('monday');
  @override
  late final GeneratedColumn<bool> monday = GeneratedColumn<bool>(
      'monday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("monday" IN (0, 1))'));
  static const VerificationMeta _tuesdayMeta =
      const VerificationMeta('tuesday');
  @override
  late final GeneratedColumn<bool> tuesday = GeneratedColumn<bool>(
      'tuesday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("tuesday" IN (0, 1))'));
  static const VerificationMeta _wednesdayMeta =
      const VerificationMeta('wednesday');
  @override
  late final GeneratedColumn<bool> wednesday = GeneratedColumn<bool>(
      'wednesday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("wednesday" IN (0, 1))'));
  static const VerificationMeta _thursdayMeta =
      const VerificationMeta('thursday');
  @override
  late final GeneratedColumn<bool> thursday = GeneratedColumn<bool>(
      'thursday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("thursday" IN (0, 1))'));
  static const VerificationMeta _fridayMeta = const VerificationMeta('friday');
  @override
  late final GeneratedColumn<bool> friday = GeneratedColumn<bool>(
      'friday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("friday" IN (0, 1))'));
  static const VerificationMeta _saturdayMeta =
      const VerificationMeta('saturday');
  @override
  late final GeneratedColumn<bool> saturday = GeneratedColumn<bool>(
      'saturday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("saturday" IN (0, 1))'));
  static const VerificationMeta _sundayMeta = const VerificationMeta('sunday');
  @override
  late final GeneratedColumn<bool> sunday = GeneratedColumn<bool>(
      'sunday', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("sunday" IN (0, 1))'));
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
      'start_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
      'end_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        serviceId,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        startDate,
        endDate
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gtfs_calendar';
  @override
  VerificationContext validateIntegrity(Insertable<GtfsCalendarData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('service_id')) {
      context.handle(_serviceIdMeta,
          serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta));
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('monday')) {
      context.handle(_mondayMeta,
          monday.isAcceptableOrUnknown(data['monday']!, _mondayMeta));
    } else if (isInserting) {
      context.missing(_mondayMeta);
    }
    if (data.containsKey('tuesday')) {
      context.handle(_tuesdayMeta,
          tuesday.isAcceptableOrUnknown(data['tuesday']!, _tuesdayMeta));
    } else if (isInserting) {
      context.missing(_tuesdayMeta);
    }
    if (data.containsKey('wednesday')) {
      context.handle(_wednesdayMeta,
          wednesday.isAcceptableOrUnknown(data['wednesday']!, _wednesdayMeta));
    } else if (isInserting) {
      context.missing(_wednesdayMeta);
    }
    if (data.containsKey('thursday')) {
      context.handle(_thursdayMeta,
          thursday.isAcceptableOrUnknown(data['thursday']!, _thursdayMeta));
    } else if (isInserting) {
      context.missing(_thursdayMeta);
    }
    if (data.containsKey('friday')) {
      context.handle(_fridayMeta,
          friday.isAcceptableOrUnknown(data['friday']!, _fridayMeta));
    } else if (isInserting) {
      context.missing(_fridayMeta);
    }
    if (data.containsKey('saturday')) {
      context.handle(_saturdayMeta,
          saturday.isAcceptableOrUnknown(data['saturday']!, _saturdayMeta));
    } else if (isInserting) {
      context.missing(_saturdayMeta);
    }
    if (data.containsKey('sunday')) {
      context.handle(_sundayMeta,
          sunday.isAcceptableOrUnknown(data['sunday']!, _sundayMeta));
    } else if (isInserting) {
      context.missing(_sundayMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serviceId};
  @override
  GtfsCalendarData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GtfsCalendarData(
      serviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}service_id'])!,
      monday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}monday'])!,
      tuesday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}tuesday'])!,
      wednesday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}wednesday'])!,
      thursday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}thursday'])!,
      friday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}friday'])!,
      saturday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}saturday'])!,
      sunday: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sunday'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_date'])!,
    );
  }

  @override
  $GtfsCalendarTable createAlias(String alias) {
    return $GtfsCalendarTable(attachedDatabase, alias);
  }
}

class GtfsCalendarData extends DataClass
    implements Insertable<GtfsCalendarData> {
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
  const GtfsCalendarData(
      {required this.serviceId,
      required this.monday,
      required this.tuesday,
      required this.wednesday,
      required this.thursday,
      required this.friday,
      required this.saturday,
      required this.sunday,
      required this.startDate,
      required this.endDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['service_id'] = Variable<String>(serviceId);
    map['monday'] = Variable<bool>(monday);
    map['tuesday'] = Variable<bool>(tuesday);
    map['wednesday'] = Variable<bool>(wednesday);
    map['thursday'] = Variable<bool>(thursday);
    map['friday'] = Variable<bool>(friday);
    map['saturday'] = Variable<bool>(saturday);
    map['sunday'] = Variable<bool>(sunday);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    return map;
  }

  GtfsCalendarCompanion toCompanion(bool nullToAbsent) {
    return GtfsCalendarCompanion(
      serviceId: Value(serviceId),
      monday: Value(monday),
      tuesday: Value(tuesday),
      wednesday: Value(wednesday),
      thursday: Value(thursday),
      friday: Value(friday),
      saturday: Value(saturday),
      sunday: Value(sunday),
      startDate: Value(startDate),
      endDate: Value(endDate),
    );
  }

  factory GtfsCalendarData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GtfsCalendarData(
      serviceId: serializer.fromJson<String>(json['serviceId']),
      monday: serializer.fromJson<bool>(json['monday']),
      tuesday: serializer.fromJson<bool>(json['tuesday']),
      wednesday: serializer.fromJson<bool>(json['wednesday']),
      thursday: serializer.fromJson<bool>(json['thursday']),
      friday: serializer.fromJson<bool>(json['friday']),
      saturday: serializer.fromJson<bool>(json['saturday']),
      sunday: serializer.fromJson<bool>(json['sunday']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serviceId': serializer.toJson<String>(serviceId),
      'monday': serializer.toJson<bool>(monday),
      'tuesday': serializer.toJson<bool>(tuesday),
      'wednesday': serializer.toJson<bool>(wednesday),
      'thursday': serializer.toJson<bool>(thursday),
      'friday': serializer.toJson<bool>(friday),
      'saturday': serializer.toJson<bool>(saturday),
      'sunday': serializer.toJson<bool>(sunday),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
    };
  }

  GtfsCalendarData copyWith(
          {String? serviceId,
          bool? monday,
          bool? tuesday,
          bool? wednesday,
          bool? thursday,
          bool? friday,
          bool? saturday,
          bool? sunday,
          String? startDate,
          String? endDate}) =>
      GtfsCalendarData(
        serviceId: serviceId ?? this.serviceId,
        monday: monday ?? this.monday,
        tuesday: tuesday ?? this.tuesday,
        wednesday: wednesday ?? this.wednesday,
        thursday: thursday ?? this.thursday,
        friday: friday ?? this.friday,
        saturday: saturday ?? this.saturday,
        sunday: sunday ?? this.sunday,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );
  @override
  String toString() {
    return (StringBuffer('GtfsCalendarData(')
          ..write('serviceId: $serviceId, ')
          ..write('monday: $monday, ')
          ..write('tuesday: $tuesday, ')
          ..write('wednesday: $wednesday, ')
          ..write('thursday: $thursday, ')
          ..write('friday: $friday, ')
          ..write('saturday: $saturday, ')
          ..write('sunday: $sunday, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serviceId, monday, tuesday, wednesday,
      thursday, friday, saturday, sunday, startDate, endDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GtfsCalendarData &&
          other.serviceId == this.serviceId &&
          other.monday == this.monday &&
          other.tuesday == this.tuesday &&
          other.wednesday == this.wednesday &&
          other.thursday == this.thursday &&
          other.friday == this.friday &&
          other.saturday == this.saturday &&
          other.sunday == this.sunday &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class GtfsCalendarCompanion extends UpdateCompanion<GtfsCalendarData> {
  final Value<String> serviceId;
  final Value<bool> monday;
  final Value<bool> tuesday;
  final Value<bool> wednesday;
  final Value<bool> thursday;
  final Value<bool> friday;
  final Value<bool> saturday;
  final Value<bool> sunday;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<int> rowid;
  const GtfsCalendarCompanion({
    this.serviceId = const Value.absent(),
    this.monday = const Value.absent(),
    this.tuesday = const Value.absent(),
    this.wednesday = const Value.absent(),
    this.thursday = const Value.absent(),
    this.friday = const Value.absent(),
    this.saturday = const Value.absent(),
    this.sunday = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GtfsCalendarCompanion.insert({
    required String serviceId,
    required bool monday,
    required bool tuesday,
    required bool wednesday,
    required bool thursday,
    required bool friday,
    required bool saturday,
    required bool sunday,
    required String startDate,
    required String endDate,
    this.rowid = const Value.absent(),
  })  : serviceId = Value(serviceId),
        monday = Value(monday),
        tuesday = Value(tuesday),
        wednesday = Value(wednesday),
        thursday = Value(thursday),
        friday = Value(friday),
        saturday = Value(saturday),
        sunday = Value(sunday),
        startDate = Value(startDate),
        endDate = Value(endDate);
  static Insertable<GtfsCalendarData> custom({
    Expression<String>? serviceId,
    Expression<bool>? monday,
    Expression<bool>? tuesday,
    Expression<bool>? wednesday,
    Expression<bool>? thursday,
    Expression<bool>? friday,
    Expression<bool>? saturday,
    Expression<bool>? sunday,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serviceId != null) 'service_id': serviceId,
      if (monday != null) 'monday': monday,
      if (tuesday != null) 'tuesday': tuesday,
      if (wednesday != null) 'wednesday': wednesday,
      if (thursday != null) 'thursday': thursday,
      if (friday != null) 'friday': friday,
      if (saturday != null) 'saturday': saturday,
      if (sunday != null) 'sunday': sunday,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GtfsCalendarCompanion copyWith(
      {Value<String>? serviceId,
      Value<bool>? monday,
      Value<bool>? tuesday,
      Value<bool>? wednesday,
      Value<bool>? thursday,
      Value<bool>? friday,
      Value<bool>? saturday,
      Value<bool>? sunday,
      Value<String>? startDate,
      Value<String>? endDate,
      Value<int>? rowid}) {
    return GtfsCalendarCompanion(
      serviceId: serviceId ?? this.serviceId,
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
      sunday: sunday ?? this.sunday,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (monday.present) {
      map['monday'] = Variable<bool>(monday.value);
    }
    if (tuesday.present) {
      map['tuesday'] = Variable<bool>(tuesday.value);
    }
    if (wednesday.present) {
      map['wednesday'] = Variable<bool>(wednesday.value);
    }
    if (thursday.present) {
      map['thursday'] = Variable<bool>(thursday.value);
    }
    if (friday.present) {
      map['friday'] = Variable<bool>(friday.value);
    }
    if (saturday.present) {
      map['saturday'] = Variable<bool>(saturday.value);
    }
    if (sunday.present) {
      map['sunday'] = Variable<bool>(sunday.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GtfsCalendarCompanion(')
          ..write('serviceId: $serviceId, ')
          ..write('monday: $monday, ')
          ..write('tuesday: $tuesday, ')
          ..write('wednesday: $wednesday, ')
          ..write('thursday: $thursday, ')
          ..write('friday: $friday, ')
          ..write('saturday: $saturday, ')
          ..write('sunday: $sunday, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GtfsCalendarDatesTable extends GtfsCalendarDates
    with TableInfo<$GtfsCalendarDatesTable, GtfsCalendarDate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GtfsCalendarDatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serviceIdMeta =
      const VerificationMeta('serviceId');
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
      'service_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exceptionTypeMeta =
      const VerificationMeta('exceptionType');
  @override
  late final GeneratedColumn<int> exceptionType = GeneratedColumn<int>(
      'exception_type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [serviceId, date, exceptionType];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gtfs_calendar_dates';
  @override
  VerificationContext validateIntegrity(Insertable<GtfsCalendarDate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('service_id')) {
      context.handle(_serviceIdMeta,
          serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta));
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('exception_type')) {
      context.handle(
          _exceptionTypeMeta,
          exceptionType.isAcceptableOrUnknown(
              data['exception_type']!, _exceptionTypeMeta));
    } else if (isInserting) {
      context.missing(_exceptionTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serviceId, date};
  @override
  GtfsCalendarDate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GtfsCalendarDate(
      serviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}service_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      exceptionType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exception_type'])!,
    );
  }

  @override
  $GtfsCalendarDatesTable createAlias(String alias) {
    return $GtfsCalendarDatesTable(attachedDatabase, alias);
  }
}

class GtfsCalendarDate extends DataClass
    implements Insertable<GtfsCalendarDate> {
  final String serviceId;
  final String date;
  final int exceptionType;
  const GtfsCalendarDate(
      {required this.serviceId,
      required this.date,
      required this.exceptionType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['service_id'] = Variable<String>(serviceId);
    map['date'] = Variable<String>(date);
    map['exception_type'] = Variable<int>(exceptionType);
    return map;
  }

  GtfsCalendarDatesCompanion toCompanion(bool nullToAbsent) {
    return GtfsCalendarDatesCompanion(
      serviceId: Value(serviceId),
      date: Value(date),
      exceptionType: Value(exceptionType),
    );
  }

  factory GtfsCalendarDate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GtfsCalendarDate(
      serviceId: serializer.fromJson<String>(json['serviceId']),
      date: serializer.fromJson<String>(json['date']),
      exceptionType: serializer.fromJson<int>(json['exceptionType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serviceId': serializer.toJson<String>(serviceId),
      'date': serializer.toJson<String>(date),
      'exceptionType': serializer.toJson<int>(exceptionType),
    };
  }

  GtfsCalendarDate copyWith(
          {String? serviceId, String? date, int? exceptionType}) =>
      GtfsCalendarDate(
        serviceId: serviceId ?? this.serviceId,
        date: date ?? this.date,
        exceptionType: exceptionType ?? this.exceptionType,
      );
  @override
  String toString() {
    return (StringBuffer('GtfsCalendarDate(')
          ..write('serviceId: $serviceId, ')
          ..write('date: $date, ')
          ..write('exceptionType: $exceptionType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serviceId, date, exceptionType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GtfsCalendarDate &&
          other.serviceId == this.serviceId &&
          other.date == this.date &&
          other.exceptionType == this.exceptionType);
}

class GtfsCalendarDatesCompanion extends UpdateCompanion<GtfsCalendarDate> {
  final Value<String> serviceId;
  final Value<String> date;
  final Value<int> exceptionType;
  final Value<int> rowid;
  const GtfsCalendarDatesCompanion({
    this.serviceId = const Value.absent(),
    this.date = const Value.absent(),
    this.exceptionType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GtfsCalendarDatesCompanion.insert({
    required String serviceId,
    required String date,
    required int exceptionType,
    this.rowid = const Value.absent(),
  })  : serviceId = Value(serviceId),
        date = Value(date),
        exceptionType = Value(exceptionType);
  static Insertable<GtfsCalendarDate> custom({
    Expression<String>? serviceId,
    Expression<String>? date,
    Expression<int>? exceptionType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serviceId != null) 'service_id': serviceId,
      if (date != null) 'date': date,
      if (exceptionType != null) 'exception_type': exceptionType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GtfsCalendarDatesCompanion copyWith(
      {Value<String>? serviceId,
      Value<String>? date,
      Value<int>? exceptionType,
      Value<int>? rowid}) {
    return GtfsCalendarDatesCompanion(
      serviceId: serviceId ?? this.serviceId,
      date: date ?? this.date,
      exceptionType: exceptionType ?? this.exceptionType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (exceptionType.present) {
      map['exception_type'] = Variable<int>(exceptionType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GtfsCalendarDatesCompanion(')
          ..write('serviceId: $serviceId, ')
          ..write('date: $date, ')
          ..write('exceptionType: $exceptionType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GtfsShapesTable extends GtfsShapes
    with TableInfo<$GtfsShapesTable, GtfsShape> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GtfsShapesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shapeIdMeta =
      const VerificationMeta('shapeId');
  @override
  late final GeneratedColumn<String> shapeId = GeneratedColumn<String>(
      'shape_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shapePtLatMeta =
      const VerificationMeta('shapePtLat');
  @override
  late final GeneratedColumn<double> shapePtLat = GeneratedColumn<double>(
      'shape_pt_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _shapePtLonMeta =
      const VerificationMeta('shapePtLon');
  @override
  late final GeneratedColumn<double> shapePtLon = GeneratedColumn<double>(
      'shape_pt_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _shapePtSequenceMeta =
      const VerificationMeta('shapePtSequence');
  @override
  late final GeneratedColumn<int> shapePtSequence = GeneratedColumn<int>(
      'shape_pt_sequence', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [shapeId, shapePtLat, shapePtLon, shapePtSequence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gtfs_shapes';
  @override
  VerificationContext validateIntegrity(Insertable<GtfsShape> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shape_id')) {
      context.handle(_shapeIdMeta,
          shapeId.isAcceptableOrUnknown(data['shape_id']!, _shapeIdMeta));
    } else if (isInserting) {
      context.missing(_shapeIdMeta);
    }
    if (data.containsKey('shape_pt_lat')) {
      context.handle(
          _shapePtLatMeta,
          shapePtLat.isAcceptableOrUnknown(
              data['shape_pt_lat']!, _shapePtLatMeta));
    } else if (isInserting) {
      context.missing(_shapePtLatMeta);
    }
    if (data.containsKey('shape_pt_lon')) {
      context.handle(
          _shapePtLonMeta,
          shapePtLon.isAcceptableOrUnknown(
              data['shape_pt_lon']!, _shapePtLonMeta));
    } else if (isInserting) {
      context.missing(_shapePtLonMeta);
    }
    if (data.containsKey('shape_pt_sequence')) {
      context.handle(
          _shapePtSequenceMeta,
          shapePtSequence.isAcceptableOrUnknown(
              data['shape_pt_sequence']!, _shapePtSequenceMeta));
    } else if (isInserting) {
      context.missing(_shapePtSequenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shapeId, shapePtSequence};
  @override
  GtfsShape map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GtfsShape(
      shapeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shape_id'])!,
      shapePtLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shape_pt_lat'])!,
      shapePtLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shape_pt_lon'])!,
      shapePtSequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shape_pt_sequence'])!,
    );
  }

  @override
  $GtfsShapesTable createAlias(String alias) {
    return $GtfsShapesTable(attachedDatabase, alias);
  }
}

class GtfsShape extends DataClass implements Insertable<GtfsShape> {
  final String shapeId;
  final double shapePtLat;
  final double shapePtLon;
  final int shapePtSequence;
  const GtfsShape(
      {required this.shapeId,
      required this.shapePtLat,
      required this.shapePtLon,
      required this.shapePtSequence});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shape_id'] = Variable<String>(shapeId);
    map['shape_pt_lat'] = Variable<double>(shapePtLat);
    map['shape_pt_lon'] = Variable<double>(shapePtLon);
    map['shape_pt_sequence'] = Variable<int>(shapePtSequence);
    return map;
  }

  GtfsShapesCompanion toCompanion(bool nullToAbsent) {
    return GtfsShapesCompanion(
      shapeId: Value(shapeId),
      shapePtLat: Value(shapePtLat),
      shapePtLon: Value(shapePtLon),
      shapePtSequence: Value(shapePtSequence),
    );
  }

  factory GtfsShape.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GtfsShape(
      shapeId: serializer.fromJson<String>(json['shapeId']),
      shapePtLat: serializer.fromJson<double>(json['shapePtLat']),
      shapePtLon: serializer.fromJson<double>(json['shapePtLon']),
      shapePtSequence: serializer.fromJson<int>(json['shapePtSequence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shapeId': serializer.toJson<String>(shapeId),
      'shapePtLat': serializer.toJson<double>(shapePtLat),
      'shapePtLon': serializer.toJson<double>(shapePtLon),
      'shapePtSequence': serializer.toJson<int>(shapePtSequence),
    };
  }

  GtfsShape copyWith(
          {String? shapeId,
          double? shapePtLat,
          double? shapePtLon,
          int? shapePtSequence}) =>
      GtfsShape(
        shapeId: shapeId ?? this.shapeId,
        shapePtLat: shapePtLat ?? this.shapePtLat,
        shapePtLon: shapePtLon ?? this.shapePtLon,
        shapePtSequence: shapePtSequence ?? this.shapePtSequence,
      );
  @override
  String toString() {
    return (StringBuffer('GtfsShape(')
          ..write('shapeId: $shapeId, ')
          ..write('shapePtLat: $shapePtLat, ')
          ..write('shapePtLon: $shapePtLon, ')
          ..write('shapePtSequence: $shapePtSequence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(shapeId, shapePtLat, shapePtLon, shapePtSequence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GtfsShape &&
          other.shapeId == this.shapeId &&
          other.shapePtLat == this.shapePtLat &&
          other.shapePtLon == this.shapePtLon &&
          other.shapePtSequence == this.shapePtSequence);
}

class GtfsShapesCompanion extends UpdateCompanion<GtfsShape> {
  final Value<String> shapeId;
  final Value<double> shapePtLat;
  final Value<double> shapePtLon;
  final Value<int> shapePtSequence;
  final Value<int> rowid;
  const GtfsShapesCompanion({
    this.shapeId = const Value.absent(),
    this.shapePtLat = const Value.absent(),
    this.shapePtLon = const Value.absent(),
    this.shapePtSequence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GtfsShapesCompanion.insert({
    required String shapeId,
    required double shapePtLat,
    required double shapePtLon,
    required int shapePtSequence,
    this.rowid = const Value.absent(),
  })  : shapeId = Value(shapeId),
        shapePtLat = Value(shapePtLat),
        shapePtLon = Value(shapePtLon),
        shapePtSequence = Value(shapePtSequence);
  static Insertable<GtfsShape> custom({
    Expression<String>? shapeId,
    Expression<double>? shapePtLat,
    Expression<double>? shapePtLon,
    Expression<int>? shapePtSequence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shapeId != null) 'shape_id': shapeId,
      if (shapePtLat != null) 'shape_pt_lat': shapePtLat,
      if (shapePtLon != null) 'shape_pt_lon': shapePtLon,
      if (shapePtSequence != null) 'shape_pt_sequence': shapePtSequence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GtfsShapesCompanion copyWith(
      {Value<String>? shapeId,
      Value<double>? shapePtLat,
      Value<double>? shapePtLon,
      Value<int>? shapePtSequence,
      Value<int>? rowid}) {
    return GtfsShapesCompanion(
      shapeId: shapeId ?? this.shapeId,
      shapePtLat: shapePtLat ?? this.shapePtLat,
      shapePtLon: shapePtLon ?? this.shapePtLon,
      shapePtSequence: shapePtSequence ?? this.shapePtSequence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shapeId.present) {
      map['shape_id'] = Variable<String>(shapeId.value);
    }
    if (shapePtLat.present) {
      map['shape_pt_lat'] = Variable<double>(shapePtLat.value);
    }
    if (shapePtLon.present) {
      map['shape_pt_lon'] = Variable<double>(shapePtLon.value);
    }
    if (shapePtSequence.present) {
      map['shape_pt_sequence'] = Variable<int>(shapePtSequence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GtfsShapesCompanion(')
          ..write('shapeId: $shapeId, ')
          ..write('shapePtLat: $shapePtLat, ')
          ..write('shapePtLon: $shapePtLon, ')
          ..write('shapePtSequence: $shapePtSequence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteStopsTable extends FavoriteStops
    with TableInfo<$FavoriteStopsTable, FavoriteStop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteStopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stopIdMeta = const VerificationMeta('stopId');
  @override
  late final GeneratedColumn<String> stopId = GeneratedColumn<String>(
      'stop_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [stopId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_stops';
  @override
  VerificationContext validateIntegrity(Insertable<FavoriteStop> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stop_id')) {
      context.handle(_stopIdMeta,
          stopId.isAcceptableOrUnknown(data['stop_id']!, _stopIdMeta));
    } else if (isInserting) {
      context.missing(_stopIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stopId};
  @override
  FavoriteStop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteStop(
      stopId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stop_id'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $FavoriteStopsTable createAlias(String alias) {
    return $FavoriteStopsTable(attachedDatabase, alias);
  }
}

class FavoriteStop extends DataClass implements Insertable<FavoriteStop> {
  final String stopId;
  final DateTime addedAt;
  const FavoriteStop({required this.stopId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stop_id'] = Variable<String>(stopId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoriteStopsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteStopsCompanion(
      stopId: Value(stopId),
      addedAt: Value(addedAt),
    );
  }

  factory FavoriteStop.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteStop(
      stopId: serializer.fromJson<String>(json['stopId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stopId': serializer.toJson<String>(stopId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  FavoriteStop copyWith({String? stopId, DateTime? addedAt}) => FavoriteStop(
        stopId: stopId ?? this.stopId,
        addedAt: addedAt ?? this.addedAt,
      );
  @override
  String toString() {
    return (StringBuffer('FavoriteStop(')
          ..write('stopId: $stopId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stopId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteStop &&
          other.stopId == this.stopId &&
          other.addedAt == this.addedAt);
}

class FavoriteStopsCompanion extends UpdateCompanion<FavoriteStop> {
  final Value<String> stopId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const FavoriteStopsCompanion({
    this.stopId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteStopsCompanion.insert({
    required String stopId,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  })  : stopId = Value(stopId),
        addedAt = Value(addedAt);
  static Insertable<FavoriteStop> custom({
    Expression<String>? stopId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stopId != null) 'stop_id': stopId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteStopsCompanion copyWith(
      {Value<String>? stopId, Value<DateTime>? addedAt, Value<int>? rowid}) {
    return FavoriteStopsCompanion(
      stopId: stopId ?? this.stopId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stopId.present) {
      map['stop_id'] = Variable<String>(stopId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteStopsCompanion(')
          ..write('stopId: $stopId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $GtfsStopsTable gtfsStops = $GtfsStopsTable(this);
  late final $GtfsRoutesTable gtfsRoutes = $GtfsRoutesTable(this);
  late final $GtfsTripsTable gtfsTrips = $GtfsTripsTable(this);
  late final $GtfsStopTimesTable gtfsStopTimes = $GtfsStopTimesTable(this);
  late final $GtfsCalendarTable gtfsCalendar = $GtfsCalendarTable(this);
  late final $GtfsCalendarDatesTable gtfsCalendarDates =
      $GtfsCalendarDatesTable(this);
  late final $GtfsShapesTable gtfsShapes = $GtfsShapesTable(this);
  late final $FavoriteStopsTable favoriteStops = $FavoriteStopsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        gtfsStops,
        gtfsRoutes,
        gtfsTrips,
        gtfsStopTimes,
        gtfsCalendar,
        gtfsCalendarDates,
        gtfsShapes,
        favoriteStops
      ];
}
