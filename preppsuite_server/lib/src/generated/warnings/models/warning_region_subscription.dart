/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../../households/models/household.dart' as _i2;
import '../../warnings/models/warning_region_kind.dart' as _i3;
import 'package:preppsuite_server/src/generated/protocol.dart' as _i4;

/// An additional region (beyond a household's own `regionKey`) whose
/// warnings a household wants to see — e.g. a neighboring Kreis, or an
/// entire Bundesland. Purely additive: removing all of a household's
/// subscriptions doesn't affect its own `regionKey`-based relevance.
abstract class WarningRegionSubscription
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  WarningRegionSubscription._({
    this.id,
    required this.householdId,
    this.household,
    required this.kind,
    required this.value,
    required this.label,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WarningRegionSubscription({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i3.WarningRegionKind kind,
    required String value,
    required String label,
    DateTime? createdAt,
  }) = _WarningRegionSubscriptionImpl;

  factory WarningRegionSubscription.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WarningRegionSubscription(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      householdId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['householdId'],
      ),
      household: jsonSerialization['household'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Household>(
              jsonSerialization['household'],
            ),
      kind: _i3.WarningRegionKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      value: jsonSerialization['value'] as String,
      label: jsonSerialization['label'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = WarningRegionSubscriptionTable();

  static const db = WarningRegionSubscriptionRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue householdId;

  _i2.Household? household;

  _i3.WarningRegionKind kind;

  /// A 5-digit Kreisschlüssel (kind=kreis) or 2-letter state code
  /// (kind=bundesland).
  String value;

  /// Display name the client sent when adding this (Kreis or Bundesland
  /// name) — there's no server-side lookup table for Kreis names, so this
  /// is user/client-supplied rather than derived.
  String label;

  DateTime createdAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [WarningRegionSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WarningRegionSubscription copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    _i3.WarningRegionKind? kind,
    String? value,
    String? label,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WarningRegionSubscription',
      if (id != null) 'id': id?.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJson(),
      'kind': kind.toJson(),
      'value': value,
      'label': label,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WarningRegionSubscription',
      if (id != null) 'id': id?.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJsonForProtocol(),
      'kind': kind.toJson(),
      'value': value,
      'label': label,
      'createdAt': createdAt.toJson(),
    };
  }

  static WarningRegionSubscriptionInclude include({
    _i2.HouseholdInclude? household,
  }) {
    return WarningRegionSubscriptionInclude._(household: household);
  }

  static WarningRegionSubscriptionIncludeList includeList({
    _i1.WhereExpressionBuilder<WarningRegionSubscriptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WarningRegionSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WarningRegionSubscriptionTable>? orderByList,
    WarningRegionSubscriptionInclude? include,
  }) {
    return WarningRegionSubscriptionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WarningRegionSubscription.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(WarningRegionSubscription.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WarningRegionSubscriptionImpl extends WarningRegionSubscription {
  _WarningRegionSubscriptionImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i3.WarningRegionKind kind,
    required String value,
    required String label,
    DateTime? createdAt,
  }) : super._(
         id: id,
         householdId: householdId,
         household: household,
         kind: kind,
         value: value,
         label: label,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WarningRegionSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WarningRegionSubscription copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? householdId,
    Object? household = _Undefined,
    _i3.WarningRegionKind? kind,
    String? value,
    String? label,
    DateTime? createdAt,
  }) {
    return WarningRegionSubscription(
      id: id is _i1.UuidValue? ? id : this.id,
      householdId: householdId ?? this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      kind: kind ?? this.kind,
      value: value ?? this.value,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WarningRegionSubscriptionUpdateTable
    extends _i1.UpdateTable<WarningRegionSubscriptionTable> {
  WarningRegionSubscriptionUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> householdId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.householdId,
    value,
  );

  _i1.ColumnValue<_i3.WarningRegionKind, _i3.WarningRegionKind> kind(
    _i3.WarningRegionKind value,
  ) => _i1.ColumnValue(
    table.kind,
    value,
  );

  _i1.ColumnValue<String, String> value(String value) => _i1.ColumnValue(
    table.value,
    value,
  );

  _i1.ColumnValue<String, String> label(String value) => _i1.ColumnValue(
    table.label,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class WarningRegionSubscriptionTable extends _i1.Table<_i1.UuidValue?> {
  WarningRegionSubscriptionTable({super.tableRelation})
    : super(tableName: 'warning_region_subscription') {
    updateTable = WarningRegionSubscriptionUpdateTable(this);
    householdId = _i1.ColumnUuid(
      'householdId',
      this,
    );
    kind = _i1.ColumnEnum(
      'kind',
      this,
      _i1.EnumSerialization.byName,
    );
    value = _i1.ColumnString(
      'value',
      this,
    );
    label = _i1.ColumnString(
      'label',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final WarningRegionSubscriptionUpdateTable updateTable;

  late final _i1.ColumnUuid householdId;

  _i2.HouseholdTable? _household;

  late final _i1.ColumnEnum<_i3.WarningRegionKind> kind;

  /// A 5-digit Kreisschlüssel (kind=kreis) or 2-letter state code
  /// (kind=bundesland).
  late final _i1.ColumnString value;

  /// Display name the client sent when adding this (Kreis or Bundesland
  /// name) — there's no server-side lookup table for Kreis names, so this
  /// is user/client-supplied rather than derived.
  late final _i1.ColumnString label;

  late final _i1.ColumnDateTime createdAt;

  _i2.HouseholdTable get household {
    if (_household != null) return _household!;
    _household = _i1.createRelationTable(
      relationFieldName: 'household',
      field: WarningRegionSubscription.t.householdId,
      foreignField: _i2.Household.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.HouseholdTable(tableRelation: foreignTableRelation),
    );
    return _household!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    householdId,
    kind,
    value,
    label,
    createdAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'household') {
      return household;
    }
    return null;
  }
}

class WarningRegionSubscriptionInclude extends _i1.IncludeObject {
  WarningRegionSubscriptionInclude._({_i2.HouseholdInclude? household}) {
    _household = household;
  }

  _i2.HouseholdInclude? _household;

  @override
  Map<String, _i1.Include?> get includes => {'household': _household};

  @override
  _i1.Table<_i1.UuidValue?> get table => WarningRegionSubscription.t;
}

class WarningRegionSubscriptionIncludeList extends _i1.IncludeList {
  WarningRegionSubscriptionIncludeList._({
    _i1.WhereExpressionBuilder<WarningRegionSubscriptionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WarningRegionSubscription.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => WarningRegionSubscription.t;
}

class WarningRegionSubscriptionRepository {
  const WarningRegionSubscriptionRepository._();

  final attachRow = const WarningRegionSubscriptionAttachRowRepository._();

  /// Returns a list of [WarningRegionSubscription]s matching the given query parameters.
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
  Future<List<WarningRegionSubscription>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WarningRegionSubscriptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WarningRegionSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WarningRegionSubscriptionTable>? orderByList,
    _i1.Transaction? transaction,
    WarningRegionSubscriptionInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WarningRegionSubscription>(
      where: where?.call(WarningRegionSubscription.t),
      orderBy: orderBy?.call(WarningRegionSubscription.t),
      orderByList: orderByList?.call(WarningRegionSubscription.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WarningRegionSubscription] matching the given query parameters.
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
  Future<WarningRegionSubscription?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WarningRegionSubscriptionTable>? where,
    int? offset,
    _i1.OrderByBuilder<WarningRegionSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WarningRegionSubscriptionTable>? orderByList,
    _i1.Transaction? transaction,
    WarningRegionSubscriptionInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WarningRegionSubscription>(
      where: where?.call(WarningRegionSubscription.t),
      orderBy: orderBy?.call(WarningRegionSubscription.t),
      orderByList: orderByList?.call(WarningRegionSubscription.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WarningRegionSubscription] by its [id] or null if no such row exists.
  Future<WarningRegionSubscription?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    WarningRegionSubscriptionInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WarningRegionSubscription>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WarningRegionSubscription]s in the list and returns the inserted rows.
  ///
  /// The returned [WarningRegionSubscription]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<WarningRegionSubscription>> insert(
    _i1.DatabaseSession session,
    List<WarningRegionSubscription> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<WarningRegionSubscription>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [WarningRegionSubscription] and returns the inserted row.
  ///
  /// The returned [WarningRegionSubscription] will have its `id` field set.
  Future<WarningRegionSubscription> insertRow(
    _i1.DatabaseSession session,
    WarningRegionSubscription row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WarningRegionSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [WarningRegionSubscription]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<WarningRegionSubscription>> update(
    _i1.DatabaseSession session,
    List<WarningRegionSubscription> rows, {
    _i1.ColumnSelections<WarningRegionSubscriptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<WarningRegionSubscription>(
      rows,
      columns: columns?.call(WarningRegionSubscription.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WarningRegionSubscription]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WarningRegionSubscription> updateRow(
    _i1.DatabaseSession session,
    WarningRegionSubscription row, {
    _i1.ColumnSelections<WarningRegionSubscriptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WarningRegionSubscription>(
      row,
      columns: columns?.call(WarningRegionSubscription.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WarningRegionSubscription] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WarningRegionSubscription?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<WarningRegionSubscriptionUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WarningRegionSubscription>(
      id,
      columnValues: columnValues(WarningRegionSubscription.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WarningRegionSubscription]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<WarningRegionSubscription>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WarningRegionSubscriptionUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<WarningRegionSubscriptionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WarningRegionSubscriptionTable>? orderBy,
    _i1.OrderByListBuilder<WarningRegionSubscriptionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<WarningRegionSubscription>(
      columnValues: columnValues(WarningRegionSubscription.t.updateTable),
      where: where(WarningRegionSubscription.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WarningRegionSubscription.t),
      orderByList: orderByList?.call(WarningRegionSubscription.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [WarningRegionSubscription]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<WarningRegionSubscription>> delete(
    _i1.DatabaseSession session,
    List<WarningRegionSubscription> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<WarningRegionSubscription>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [WarningRegionSubscription].
  Future<WarningRegionSubscription> deleteRow(
    _i1.DatabaseSession session,
    WarningRegionSubscription row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WarningRegionSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<WarningRegionSubscription>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WarningRegionSubscriptionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<WarningRegionSubscription>(
      where: where(WarningRegionSubscription.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WarningRegionSubscriptionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WarningRegionSubscription>(
      where: where?.call(WarningRegionSubscription.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WarningRegionSubscription] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WarningRegionSubscriptionTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WarningRegionSubscription>(
      where: where(WarningRegionSubscription.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class WarningRegionSubscriptionAttachRowRepository {
  const WarningRegionSubscriptionAttachRowRepository._();

  /// Creates a relation between the given [WarningRegionSubscription] and [Household]
  /// by setting the [WarningRegionSubscription]'s foreign key `householdId` to refer to the [Household].
  Future<void> household(
    _i1.DatabaseSession session,
    WarningRegionSubscription warningRegionSubscription,
    _i2.Household household, {
    _i1.Transaction? transaction,
  }) async {
    if (warningRegionSubscription.id == null) {
      throw ArgumentError.notNull('warningRegionSubscription.id');
    }
    if (household.id == null) {
      throw ArgumentError.notNull('household.id');
    }

    var $warningRegionSubscription = warningRegionSubscription.copyWith(
      householdId: household.id,
    );
    await session.db.updateRow<WarningRegionSubscription>(
      $warningRegionSubscription,
      columns: [WarningRegionSubscription.t.householdId],
      transaction: transaction,
    );
  }
}
