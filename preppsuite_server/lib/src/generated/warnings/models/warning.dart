/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../../warnings/models/warning_source.dart' as _i2;
import '../../warnings/models/warning_severity.dart' as _i3;

/// A normalized civil-protection/weather warning, upserted by the
/// self-rescheduling poll in `warning_poll_future_call.dart`. Read-only
/// from the client's perspective — delivered via a plain pull, never
/// through the generic push/pull sync used by household-editable entities,
/// since warnings are entirely server-generated.
abstract class Warning
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  Warning._({
    this.id,
    required this.source,
    required this.externalId,
    required this.countryCode,
    this.regionKey,
    required this.severity,
    required this.eventType,
    required this.headline,
    this.description,
    required this.effective,
    this.expires,
    required this.sent,
    required this.rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Warning({
    _i1.UuidValue? id,
    required _i2.WarningSource source,
    required String externalId,
    required String countryCode,
    String? regionKey,
    required _i3.WarningSeverity severity,
    required String eventType,
    required String headline,
    String? description,
    required DateTime effective,
    DateTime? expires,
    required DateTime sent,
    required String rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _WarningImpl;

  factory Warning.fromJson(Map<String, dynamic> jsonSerialization) {
    return Warning(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      source: _i2.WarningSource.fromJson(
        (jsonSerialization['source'] as String),
      ),
      externalId: jsonSerialization['externalId'] as String,
      countryCode: jsonSerialization['countryCode'] as String,
      regionKey: jsonSerialization['regionKey'] as String?,
      severity: _i3.WarningSeverity.fromJson(
        (jsonSerialization['severity'] as String),
      ),
      eventType: jsonSerialization['eventType'] as String,
      headline: jsonSerialization['headline'] as String,
      description: jsonSerialization['description'] as String?,
      effective: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['effective'],
      ),
      expires: jsonSerialization['expires'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expires']),
      sent: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['sent']),
      rawPayload: jsonSerialization['rawPayload'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = WarningTable();

  static const db = WarningRepository._();

  @override
  _i1.UuidValue? id;

  _i2.WarningSource source;

  /// The source's own id for this warning; used with [source] to
  /// deduplicate on upsert.
  String externalId;

  /// ISO 3166-1 alpha-2. Scopes which households see this warning.
  String countryCode;

  /// Free-text area description/code from the source feed (BBK state
  /// code, MeteoAlarm EMMA_ID/areaDesc) — informational, not matched
  /// precisely against a household's `regionKey` in v1.
  String? regionKey;

  _i3.WarningSeverity severity;

  /// Free-text event type/category from the source (not a closed
  /// vocabulary — BBK and MeteoAlarm each use their own).
  String eventType;

  String headline;

  String? description;

  /// When the warning takes/took effect.
  DateTime effective;

  /// Null when the source doesn't report an expiry (e.g. BBK's mapData
  /// feed).
  DateTime? expires;

  /// When the source issued/last updated this warning.
  DateTime sent;

  /// The unprocessed source payload as a JSON string, kept for
  /// debugging/future re-parsing.
  String rawPayload;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Warning]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Warning copyWith({
    _i1.UuidValue? id,
    _i2.WarningSource? source,
    String? externalId,
    String? countryCode,
    String? regionKey,
    _i3.WarningSeverity? severity,
    String? eventType,
    String? headline,
    String? description,
    DateTime? effective,
    DateTime? expires,
    DateTime? sent,
    String? rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Warning',
      if (id != null) 'id': id?.toJson(),
      'source': source.toJson(),
      'externalId': externalId,
      'countryCode': countryCode,
      if (regionKey != null) 'regionKey': regionKey,
      'severity': severity.toJson(),
      'eventType': eventType,
      'headline': headline,
      if (description != null) 'description': description,
      'effective': effective.toJson(),
      if (expires != null) 'expires': expires?.toJson(),
      'sent': sent.toJson(),
      'rawPayload': rawPayload,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Warning',
      if (id != null) 'id': id?.toJson(),
      'source': source.toJson(),
      'externalId': externalId,
      'countryCode': countryCode,
      if (regionKey != null) 'regionKey': regionKey,
      'severity': severity.toJson(),
      'eventType': eventType,
      'headline': headline,
      if (description != null) 'description': description,
      'effective': effective.toJson(),
      if (expires != null) 'expires': expires?.toJson(),
      'sent': sent.toJson(),
      'rawPayload': rawPayload,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static WarningInclude include() {
    return WarningInclude._();
  }

  static WarningIncludeList includeList({
    _i1.WhereExpressionBuilder<WarningTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WarningTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WarningTable>? orderByList,
    WarningInclude? include,
  }) {
    return WarningIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Warning.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Warning.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WarningImpl extends Warning {
  _WarningImpl({
    _i1.UuidValue? id,
    required _i2.WarningSource source,
    required String externalId,
    required String countryCode,
    String? regionKey,
    required _i3.WarningSeverity severity,
    required String eventType,
    required String headline,
    String? description,
    required DateTime effective,
    DateTime? expires,
    required DateTime sent,
    required String rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         source: source,
         externalId: externalId,
         countryCode: countryCode,
         regionKey: regionKey,
         severity: severity,
         eventType: eventType,
         headline: headline,
         description: description,
         effective: effective,
         expires: expires,
         sent: sent,
         rawPayload: rawPayload,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Warning]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Warning copyWith({
    Object? id = _Undefined,
    _i2.WarningSource? source,
    String? externalId,
    String? countryCode,
    Object? regionKey = _Undefined,
    _i3.WarningSeverity? severity,
    String? eventType,
    String? headline,
    Object? description = _Undefined,
    DateTime? effective,
    Object? expires = _Undefined,
    DateTime? sent,
    String? rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Warning(
      id: id is _i1.UuidValue? ? id : this.id,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      countryCode: countryCode ?? this.countryCode,
      regionKey: regionKey is String? ? regionKey : this.regionKey,
      severity: severity ?? this.severity,
      eventType: eventType ?? this.eventType,
      headline: headline ?? this.headline,
      description: description is String? ? description : this.description,
      effective: effective ?? this.effective,
      expires: expires is DateTime? ? expires : this.expires,
      sent: sent ?? this.sent,
      rawPayload: rawPayload ?? this.rawPayload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WarningUpdateTable extends _i1.UpdateTable<WarningTable> {
  WarningUpdateTable(super.table);

  _i1.ColumnValue<_i2.WarningSource, _i2.WarningSource> source(
    _i2.WarningSource value,
  ) => _i1.ColumnValue(
    table.source,
    value,
  );

  _i1.ColumnValue<String, String> externalId(String value) => _i1.ColumnValue(
    table.externalId,
    value,
  );

  _i1.ColumnValue<String, String> countryCode(String value) => _i1.ColumnValue(
    table.countryCode,
    value,
  );

  _i1.ColumnValue<String, String> regionKey(String? value) => _i1.ColumnValue(
    table.regionKey,
    value,
  );

  _i1.ColumnValue<_i3.WarningSeverity, _i3.WarningSeverity> severity(
    _i3.WarningSeverity value,
  ) => _i1.ColumnValue(
    table.severity,
    value,
  );

  _i1.ColumnValue<String, String> eventType(String value) => _i1.ColumnValue(
    table.eventType,
    value,
  );

  _i1.ColumnValue<String, String> headline(String value) => _i1.ColumnValue(
    table.headline,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> effective(DateTime value) =>
      _i1.ColumnValue(
        table.effective,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> expires(DateTime? value) =>
      _i1.ColumnValue(
        table.expires,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> sent(DateTime value) => _i1.ColumnValue(
    table.sent,
    value,
  );

  _i1.ColumnValue<String, String> rawPayload(String value) => _i1.ColumnValue(
    table.rawPayload,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class WarningTable extends _i1.Table<_i1.UuidValue?> {
  WarningTable({super.tableRelation}) : super(tableName: 'warning') {
    updateTable = WarningUpdateTable(this);
    source = _i1.ColumnEnum(
      'source',
      this,
      _i1.EnumSerialization.byName,
    );
    externalId = _i1.ColumnString(
      'externalId',
      this,
    );
    countryCode = _i1.ColumnString(
      'countryCode',
      this,
    );
    regionKey = _i1.ColumnString(
      'regionKey',
      this,
    );
    severity = _i1.ColumnEnum(
      'severity',
      this,
      _i1.EnumSerialization.byName,
    );
    eventType = _i1.ColumnString(
      'eventType',
      this,
    );
    headline = _i1.ColumnString(
      'headline',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    effective = _i1.ColumnDateTime(
      'effective',
      this,
    );
    expires = _i1.ColumnDateTime(
      'expires',
      this,
    );
    sent = _i1.ColumnDateTime(
      'sent',
      this,
    );
    rawPayload = _i1.ColumnString(
      'rawPayload',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final WarningUpdateTable updateTable;

  late final _i1.ColumnEnum<_i2.WarningSource> source;

  /// The source's own id for this warning; used with [source] to
  /// deduplicate on upsert.
  late final _i1.ColumnString externalId;

  /// ISO 3166-1 alpha-2. Scopes which households see this warning.
  late final _i1.ColumnString countryCode;

  /// Free-text area description/code from the source feed (BBK state
  /// code, MeteoAlarm EMMA_ID/areaDesc) — informational, not matched
  /// precisely against a household's `regionKey` in v1.
  late final _i1.ColumnString regionKey;

  late final _i1.ColumnEnum<_i3.WarningSeverity> severity;

  /// Free-text event type/category from the source (not a closed
  /// vocabulary — BBK and MeteoAlarm each use their own).
  late final _i1.ColumnString eventType;

  late final _i1.ColumnString headline;

  late final _i1.ColumnString description;

  /// When the warning takes/took effect.
  late final _i1.ColumnDateTime effective;

  /// Null when the source doesn't report an expiry (e.g. BBK's mapData
  /// feed).
  late final _i1.ColumnDateTime expires;

  /// When the source issued/last updated this warning.
  late final _i1.ColumnDateTime sent;

  /// The unprocessed source payload as a JSON string, kept for
  /// debugging/future re-parsing.
  late final _i1.ColumnString rawPayload;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    source,
    externalId,
    countryCode,
    regionKey,
    severity,
    eventType,
    headline,
    description,
    effective,
    expires,
    sent,
    rawPayload,
    createdAt,
    updatedAt,
  ];
}

class WarningInclude extends _i1.IncludeObject {
  WarningInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => Warning.t;
}

class WarningIncludeList extends _i1.IncludeList {
  WarningIncludeList._({
    _i1.WhereExpressionBuilder<WarningTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Warning.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => Warning.t;
}

class WarningRepository {
  const WarningRepository._();

  /// Returns a list of [Warning]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Warning>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WarningTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WarningTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WarningTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Warning>(
      where: where?.call(Warning.t),
      orderBy: orderBy?.call(Warning.t),
      orderByList: orderByList?.call(Warning.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Warning] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Warning?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WarningTable>? where,
    int? offset,
    _i1.OrderByBuilder<WarningTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WarningTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Warning>(
      where: where?.call(Warning.t),
      orderBy: orderBy?.call(Warning.t),
      orderByList: orderByList?.call(Warning.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Warning] by its [id] or null if no such row exists.
  Future<Warning?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Warning>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Warning]s in the list and returns the inserted rows.
  ///
  /// The returned [Warning]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Warning>> insert(
    _i1.DatabaseSession session,
    List<Warning> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Warning>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Warning] and returns the inserted row.
  ///
  /// The returned [Warning] will have its `id` field set.
  Future<Warning> insertRow(
    _i1.DatabaseSession session,
    Warning row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Warning>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Warning]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Warning>> update(
    _i1.DatabaseSession session,
    List<Warning> rows, {
    _i1.ColumnSelections<WarningTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Warning>(
      rows,
      columns: columns?.call(Warning.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Warning]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Warning> updateRow(
    _i1.DatabaseSession session,
    Warning row, {
    _i1.ColumnSelections<WarningTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Warning>(
      row,
      columns: columns?.call(Warning.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Warning] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Warning?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<WarningUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Warning>(
      id,
      columnValues: columnValues(Warning.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Warning]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Warning>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WarningUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<WarningTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WarningTable>? orderBy,
    _i1.OrderByListBuilder<WarningTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Warning>(
      columnValues: columnValues(Warning.t.updateTable),
      where: where(Warning.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Warning.t),
      orderByList: orderByList?.call(Warning.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Warning]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Warning>> delete(
    _i1.DatabaseSession session,
    List<Warning> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Warning>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Warning].
  Future<Warning> deleteRow(
    _i1.DatabaseSession session,
    Warning row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Warning>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Warning>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WarningTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Warning>(
      where: where(Warning.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WarningTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Warning>(
      where: where?.call(Warning.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Warning] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WarningTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Warning>(
      where: where(Warning.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
