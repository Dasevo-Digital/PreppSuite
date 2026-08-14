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
import '../../inventory/models/inventory_item_category.dart' as _i3;
import 'package:preppsuite_server/src/generated/protocol.dart' as _i4;

/// A single budget/spending entry for a household, optionally linked to an
/// inventory item it paid for.
abstract class BudgetEntry
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  BudgetEntry._({
    this.id,
    required this.clientId,
    required this.householdId,
    this.household,
    required this.label,
    required this.amountCents,
    required this.currency,
    required this.category,
    this.purchaseDate,
    this.linkedInventoryItemId,
    DateTime? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory BudgetEntry({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required String label,
    required int amountCents,
    required String currency,
    required _i3.InventoryItemCategory category,
    DateTime? purchaseDate,
    _i1.UuidValue? linkedInventoryItemId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _BudgetEntryImpl;

  factory BudgetEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return BudgetEntry(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      clientId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientId'],
      ),
      householdId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['householdId'],
      ),
      household: jsonSerialization['household'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Household>(
              jsonSerialization['household'],
            ),
      label: jsonSerialization['label'] as String,
      amountCents: jsonSerialization['amountCents'] as int,
      currency: jsonSerialization['currency'] as String,
      category: _i3.InventoryItemCategory.fromJson(
        (jsonSerialization['category'] as String),
      ),
      purchaseDate: jsonSerialization['purchaseDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['purchaseDate'],
            ),
      linkedInventoryItemId: jsonSerialization['linkedInventoryItemId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['linkedInventoryItemId'],
            ),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = BudgetEntryTable();

  static const db = BudgetEntryRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue clientId;

  _i1.UuidValue householdId;

  _i2.Household? household;

  String label;

  /// Stored as integer cents to avoid floating-point money.
  int amountCents;

  /// ISO 4217 currency code.
  String currency;

  _i3.InventoryItemCategory category;

  DateTime? purchaseDate;

  _i1.UuidValue? linkedInventoryItemId;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [BudgetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BudgetEntry copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    String? label,
    int? amountCents,
    String? currency,
    _i3.InventoryItemCategory? category,
    DateTime? purchaseDate,
    _i1.UuidValue? linkedInventoryItemId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BudgetEntry',
      if (id != null) 'id': id?.toJson(),
      'clientId': clientId.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJson(),
      'label': label,
      'amountCents': amountCents,
      'currency': currency,
      'category': category.toJson(),
      if (purchaseDate != null) 'purchaseDate': purchaseDate?.toJson(),
      if (linkedInventoryItemId != null)
        'linkedInventoryItemId': linkedInventoryItemId?.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BudgetEntry',
      if (id != null) 'id': id?.toJson(),
      'clientId': clientId.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJsonForProtocol(),
      'label': label,
      'amountCents': amountCents,
      'currency': currency,
      'category': category.toJson(),
      if (purchaseDate != null) 'purchaseDate': purchaseDate?.toJson(),
      if (linkedInventoryItemId != null)
        'linkedInventoryItemId': linkedInventoryItemId?.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static BudgetEntryInclude include({_i2.HouseholdInclude? household}) {
    return BudgetEntryInclude._(household: household);
  }

  static BudgetEntryIncludeList includeList({
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BudgetEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BudgetEntryTable>? orderByList,
    BudgetEntryInclude? include,
  }) {
    return BudgetEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BudgetEntry.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(BudgetEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BudgetEntryImpl extends BudgetEntry {
  _BudgetEntryImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required String label,
    required int amountCents,
    required String currency,
    required _i3.InventoryItemCategory category,
    DateTime? purchaseDate,
    _i1.UuidValue? linkedInventoryItemId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         clientId: clientId,
         householdId: householdId,
         household: household,
         label: label,
         amountCents: amountCents,
         currency: currency,
         category: category,
         purchaseDate: purchaseDate,
         linkedInventoryItemId: linkedInventoryItemId,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [BudgetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BudgetEntry copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? clientId,
    _i1.UuidValue? householdId,
    Object? household = _Undefined,
    String? label,
    int? amountCents,
    String? currency,
    _i3.InventoryItemCategory? category,
    Object? purchaseDate = _Undefined,
    Object? linkedInventoryItemId = _Undefined,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return BudgetEntry(
      id: id is _i1.UuidValue? ? id : this.id,
      clientId: clientId ?? this.clientId,
      householdId: householdId ?? this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      label: label ?? this.label,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      purchaseDate: purchaseDate is DateTime?
          ? purchaseDate
          : this.purchaseDate,
      linkedInventoryItemId: linkedInventoryItemId is _i1.UuidValue?
          ? linkedInventoryItemId
          : this.linkedInventoryItemId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class BudgetEntryUpdateTable extends _i1.UpdateTable<BudgetEntryTable> {
  BudgetEntryUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> clientId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.clientId,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> householdId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.householdId,
    value,
  );

  _i1.ColumnValue<String, String> label(String value) => _i1.ColumnValue(
    table.label,
    value,
  );

  _i1.ColumnValue<int, int> amountCents(int value) => _i1.ColumnValue(
    table.amountCents,
    value,
  );

  _i1.ColumnValue<String, String> currency(String value) => _i1.ColumnValue(
    table.currency,
    value,
  );

  _i1.ColumnValue<_i3.InventoryItemCategory, _i3.InventoryItemCategory>
  category(_i3.InventoryItemCategory value) => _i1.ColumnValue(
    table.category,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> purchaseDate(DateTime? value) =>
      _i1.ColumnValue(
        table.purchaseDate,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> linkedInventoryItemId(
    _i1.UuidValue? value,
  ) => _i1.ColumnValue(
    table.linkedInventoryItemId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.deletedAt,
        value,
      );
}

class BudgetEntryTable extends _i1.Table<_i1.UuidValue?> {
  BudgetEntryTable({super.tableRelation}) : super(tableName: 'budget_entry') {
    updateTable = BudgetEntryUpdateTable(this);
    clientId = _i1.ColumnUuid(
      'clientId',
      this,
    );
    householdId = _i1.ColumnUuid(
      'householdId',
      this,
    );
    label = _i1.ColumnString(
      'label',
      this,
    );
    amountCents = _i1.ColumnInt(
      'amountCents',
      this,
    );
    currency = _i1.ColumnString(
      'currency',
      this,
    );
    category = _i1.ColumnEnum(
      'category',
      this,
      _i1.EnumSerialization.byName,
    );
    purchaseDate = _i1.ColumnDateTime(
      'purchaseDate',
      this,
    );
    linkedInventoryItemId = _i1.ColumnUuid(
      'linkedInventoryItemId',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
    deletedAt = _i1.ColumnDateTime(
      'deletedAt',
      this,
    );
  }

  late final BudgetEntryUpdateTable updateTable;

  late final _i1.ColumnUuid clientId;

  late final _i1.ColumnUuid householdId;

  _i2.HouseholdTable? _household;

  late final _i1.ColumnString label;

  /// Stored as integer cents to avoid floating-point money.
  late final _i1.ColumnInt amountCents;

  /// ISO 4217 currency code.
  late final _i1.ColumnString currency;

  late final _i1.ColumnEnum<_i3.InventoryItemCategory> category;

  late final _i1.ColumnDateTime purchaseDate;

  late final _i1.ColumnUuid linkedInventoryItemId;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnDateTime deletedAt;

  _i2.HouseholdTable get household {
    if (_household != null) return _household!;
    _household = _i1.createRelationTable(
      relationFieldName: 'household',
      field: BudgetEntry.t.householdId,
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
    clientId,
    householdId,
    label,
    amountCents,
    currency,
    category,
    purchaseDate,
    linkedInventoryItemId,
    updatedAt,
    deletedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'household') {
      return household;
    }
    return null;
  }
}

class BudgetEntryInclude extends _i1.IncludeObject {
  BudgetEntryInclude._({_i2.HouseholdInclude? household}) {
    _household = household;
  }

  _i2.HouseholdInclude? _household;

  @override
  Map<String, _i1.Include?> get includes => {'household': _household};

  @override
  _i1.Table<_i1.UuidValue?> get table => BudgetEntry.t;
}

class BudgetEntryIncludeList extends _i1.IncludeList {
  BudgetEntryIncludeList._({
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BudgetEntry.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => BudgetEntry.t;
}

class BudgetEntryRepository {
  const BudgetEntryRepository._();

  final attachRow = const BudgetEntryAttachRowRepository._();

  /// Returns a list of [BudgetEntry]s matching the given query parameters.
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
  Future<List<BudgetEntry>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BudgetEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BudgetEntryTable>? orderByList,
    _i1.Transaction? transaction,
    BudgetEntryInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BudgetEntry>(
      where: where?.call(BudgetEntry.t),
      orderBy: orderBy?.call(BudgetEntry.t),
      orderByList: orderByList?.call(BudgetEntry.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [BudgetEntry] matching the given query parameters.
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
  Future<BudgetEntry?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    int? offset,
    _i1.OrderByBuilder<BudgetEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BudgetEntryTable>? orderByList,
    _i1.Transaction? transaction,
    BudgetEntryInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BudgetEntry>(
      where: where?.call(BudgetEntry.t),
      orderBy: orderBy?.call(BudgetEntry.t),
      orderByList: orderByList?.call(BudgetEntry.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BudgetEntry] by its [id] or null if no such row exists.
  Future<BudgetEntry?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    BudgetEntryInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BudgetEntry>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BudgetEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [BudgetEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<BudgetEntry>> insert(
    _i1.DatabaseSession session,
    List<BudgetEntry> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<BudgetEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [BudgetEntry] and returns the inserted row.
  ///
  /// The returned [BudgetEntry] will have its `id` field set.
  Future<BudgetEntry> insertRow(
    _i1.DatabaseSession session,
    BudgetEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<BudgetEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [BudgetEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<BudgetEntry>> update(
    _i1.DatabaseSession session,
    List<BudgetEntry> rows, {
    _i1.ColumnSelections<BudgetEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<BudgetEntry>(
      rows,
      columns: columns?.call(BudgetEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BudgetEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BudgetEntry> updateRow(
    _i1.DatabaseSession session,
    BudgetEntry row, {
    _i1.ColumnSelections<BudgetEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<BudgetEntry>(
      row,
      columns: columns?.call(BudgetEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BudgetEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BudgetEntry?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<BudgetEntryUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<BudgetEntry>(
      id,
      columnValues: columnValues(BudgetEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BudgetEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<BudgetEntry>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<BudgetEntryUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<BudgetEntryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BudgetEntryTable>? orderBy,
    _i1.OrderByListBuilder<BudgetEntryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<BudgetEntry>(
      columnValues: columnValues(BudgetEntry.t.updateTable),
      where: where(BudgetEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BudgetEntry.t),
      orderByList: orderByList?.call(BudgetEntry.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [BudgetEntry]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<BudgetEntry>> delete(
    _i1.DatabaseSession session,
    List<BudgetEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<BudgetEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [BudgetEntry].
  Future<BudgetEntry> deleteRow(
    _i1.DatabaseSession session,
    BudgetEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BudgetEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<BudgetEntry>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<BudgetEntryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<BudgetEntry>(
      where: where(BudgetEntry.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<BudgetEntry>(
      where: where?.call(BudgetEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BudgetEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<BudgetEntryTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BudgetEntry>(
      where: where(BudgetEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class BudgetEntryAttachRowRepository {
  const BudgetEntryAttachRowRepository._();

  /// Creates a relation between the given [BudgetEntry] and [Household]
  /// by setting the [BudgetEntry]'s foreign key `householdId` to refer to the [Household].
  Future<void> household(
    _i1.DatabaseSession session,
    BudgetEntry budgetEntry,
    _i2.Household household, {
    _i1.Transaction? transaction,
  }) async {
    if (budgetEntry.id == null) {
      throw ArgumentError.notNull('budgetEntry.id');
    }
    if (household.id == null) {
      throw ArgumentError.notNull('household.id');
    }

    var $budgetEntry = budgetEntry.copyWith(householdId: household.id);
    await session.db.updateRow<BudgetEntry>(
      $budgetEntry,
      columns: [BudgetEntry.t.householdId],
      transaction: transaction,
    );
  }
}
