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

/// A single supply/inventory item belonging to a household. Synced across a
/// household's devices via [InventoryEndpoint]'s push/pull pair using a
/// last-write-wins strategy on [updatedAt].
abstract class InventoryItem
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  InventoryItem._({
    this.id,
    required this.householdId,
    this.household,
    required this.clientId,
    required this.name,
    required this.category,
    this.barcode,
    this.offProductId,
    required this.quantity,
    required this.unit,
    required this.storageLocation,
    this.expirationDate,
    this.minQuantity,
    this.calories,
    this.notes,
    DateTime? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory InventoryItem({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i1.UuidValue clientId,
    required String name,
    required _i3.InventoryItemCategory category,
    String? barcode,
    String? offProductId,
    required double quantity,
    required String unit,
    required String storageLocation,
    DateTime? expirationDate,
    double? minQuantity,
    int? calories,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _InventoryItemImpl;

  factory InventoryItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return InventoryItem(
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
      clientId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientId'],
      ),
      name: jsonSerialization['name'] as String,
      category: _i3.InventoryItemCategory.fromJson(
        (jsonSerialization['category'] as String),
      ),
      barcode: jsonSerialization['barcode'] as String?,
      offProductId: jsonSerialization['offProductId'] as String?,
      quantity: (jsonSerialization['quantity'] as num).toDouble(),
      unit: jsonSerialization['unit'] as String,
      storageLocation: jsonSerialization['storageLocation'] as String,
      expirationDate: jsonSerialization['expirationDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['expirationDate'],
            ),
      minQuantity: (jsonSerialization['minQuantity'] as num?)?.toDouble(),
      calories: jsonSerialization['calories'] as int?,
      notes: jsonSerialization['notes'] as String?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = InventoryItemTable();

  static const db = InventoryItemRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue householdId;

  /// The household this item belongs to.
  _i2.Household? household;

  /// The id the item was created with on its originating device, before it
  /// had ever been synced. Stable for the lifetime of the item; used to
  /// match retried/offline-created rows to the canonical server row.
  _i1.UuidValue clientId;

  String name;

  _i3.InventoryItemCategory category;

  /// EAN/barcode, if the item was added via barcode scan.
  String? barcode;

  /// Open Food Facts product id, if the item was resolved via that lookup.
  String? offProductId;

  double quantity;

  String unit;

  /// Free-text storage location (e.g. "Keller, Regal 2").
  String storageLocation;

  DateTime? expirationDate;

  /// Below this quantity, the item is flagged as low-stock.
  double? minQuantity;

  /// Total kcal for the item's current [quantity] (not per-unit) — kept
  /// deliberately optional and only meaningful for `category: food`.
  /// Powers the "Vorräte für X Tage" supply calculator's calorie tally.
  int? calories;

  String? notes;

  /// Server-stamped on every write; the authority for last-write-wins
  /// conflict resolution and for delta-pull ("updatedAt > since") queries.
  DateTime updatedAt;

  /// Soft-delete tombstone. Never hard-deleted so other devices' pulls can
  /// observe the deletion.
  DateTime? deletedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [InventoryItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InventoryItem copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    _i1.UuidValue? clientId,
    String? name,
    _i3.InventoryItemCategory? category,
    String? barcode,
    String? offProductId,
    double? quantity,
    String? unit,
    String? storageLocation,
    DateTime? expirationDate,
    double? minQuantity,
    int? calories,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InventoryItem',
      if (id != null) 'id': id?.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJson(),
      'clientId': clientId.toJson(),
      'name': name,
      'category': category.toJson(),
      if (barcode != null) 'barcode': barcode,
      if (offProductId != null) 'offProductId': offProductId,
      'quantity': quantity,
      'unit': unit,
      'storageLocation': storageLocation,
      if (expirationDate != null) 'expirationDate': expirationDate?.toJson(),
      if (minQuantity != null) 'minQuantity': minQuantity,
      if (calories != null) 'calories': calories,
      if (notes != null) 'notes': notes,
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InventoryItem',
      if (id != null) 'id': id?.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJsonForProtocol(),
      'clientId': clientId.toJson(),
      'name': name,
      'category': category.toJson(),
      if (barcode != null) 'barcode': barcode,
      if (offProductId != null) 'offProductId': offProductId,
      'quantity': quantity,
      'unit': unit,
      'storageLocation': storageLocation,
      if (expirationDate != null) 'expirationDate': expirationDate?.toJson(),
      if (minQuantity != null) 'minQuantity': minQuantity,
      if (calories != null) 'calories': calories,
      if (notes != null) 'notes': notes,
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static InventoryItemInclude include({_i2.HouseholdInclude? household}) {
    return InventoryItemInclude._(household: household);
  }

  static InventoryItemIncludeList includeList({
    _i1.WhereExpressionBuilder<InventoryItemTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<InventoryItemTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<InventoryItemTable>? orderByList,
    InventoryItemInclude? include,
  }) {
    return InventoryItemIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InventoryItem.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(InventoryItem.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InventoryItemImpl extends InventoryItem {
  _InventoryItemImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i1.UuidValue clientId,
    required String name,
    required _i3.InventoryItemCategory category,
    String? barcode,
    String? offProductId,
    required double quantity,
    required String unit,
    required String storageLocation,
    DateTime? expirationDate,
    double? minQuantity,
    int? calories,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         householdId: householdId,
         household: household,
         clientId: clientId,
         name: name,
         category: category,
         barcode: barcode,
         offProductId: offProductId,
         quantity: quantity,
         unit: unit,
         storageLocation: storageLocation,
         expirationDate: expirationDate,
         minQuantity: minQuantity,
         calories: calories,
         notes: notes,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [InventoryItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InventoryItem copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? householdId,
    Object? household = _Undefined,
    _i1.UuidValue? clientId,
    String? name,
    _i3.InventoryItemCategory? category,
    Object? barcode = _Undefined,
    Object? offProductId = _Undefined,
    double? quantity,
    String? unit,
    String? storageLocation,
    Object? expirationDate = _Undefined,
    Object? minQuantity = _Undefined,
    Object? calories = _Undefined,
    Object? notes = _Undefined,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return InventoryItem(
      id: id is _i1.UuidValue? ? id : this.id,
      householdId: householdId ?? this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode is String? ? barcode : this.barcode,
      offProductId: offProductId is String? ? offProductId : this.offProductId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      storageLocation: storageLocation ?? this.storageLocation,
      expirationDate: expirationDate is DateTime?
          ? expirationDate
          : this.expirationDate,
      minQuantity: minQuantity is double? ? minQuantity : this.minQuantity,
      calories: calories is int? ? calories : this.calories,
      notes: notes is String? ? notes : this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class InventoryItemUpdateTable extends _i1.UpdateTable<InventoryItemTable> {
  InventoryItemUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> householdId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.householdId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> clientId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.clientId,
        value,
      );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<_i3.InventoryItemCategory, _i3.InventoryItemCategory>
  category(_i3.InventoryItemCategory value) => _i1.ColumnValue(
    table.category,
    value,
  );

  _i1.ColumnValue<String, String> barcode(String? value) => _i1.ColumnValue(
    table.barcode,
    value,
  );

  _i1.ColumnValue<String, String> offProductId(String? value) =>
      _i1.ColumnValue(
        table.offProductId,
        value,
      );

  _i1.ColumnValue<double, double> quantity(double value) => _i1.ColumnValue(
    table.quantity,
    value,
  );

  _i1.ColumnValue<String, String> unit(String value) => _i1.ColumnValue(
    table.unit,
    value,
  );

  _i1.ColumnValue<String, String> storageLocation(String value) =>
      _i1.ColumnValue(
        table.storageLocation,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> expirationDate(DateTime? value) =>
      _i1.ColumnValue(
        table.expirationDate,
        value,
      );

  _i1.ColumnValue<double, double> minQuantity(double? value) => _i1.ColumnValue(
    table.minQuantity,
    value,
  );

  _i1.ColumnValue<int, int> calories(int? value) => _i1.ColumnValue(
    table.calories,
    value,
  );

  _i1.ColumnValue<String, String> notes(String? value) => _i1.ColumnValue(
    table.notes,
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

class InventoryItemTable extends _i1.Table<_i1.UuidValue?> {
  InventoryItemTable({super.tableRelation})
    : super(tableName: 'inventory_item') {
    updateTable = InventoryItemUpdateTable(this);
    householdId = _i1.ColumnUuid(
      'householdId',
      this,
    );
    clientId = _i1.ColumnUuid(
      'clientId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    category = _i1.ColumnEnum(
      'category',
      this,
      _i1.EnumSerialization.byName,
    );
    barcode = _i1.ColumnString(
      'barcode',
      this,
    );
    offProductId = _i1.ColumnString(
      'offProductId',
      this,
    );
    quantity = _i1.ColumnDouble(
      'quantity',
      this,
    );
    unit = _i1.ColumnString(
      'unit',
      this,
    );
    storageLocation = _i1.ColumnString(
      'storageLocation',
      this,
    );
    expirationDate = _i1.ColumnDateTime(
      'expirationDate',
      this,
    );
    minQuantity = _i1.ColumnDouble(
      'minQuantity',
      this,
    );
    calories = _i1.ColumnInt(
      'calories',
      this,
    );
    notes = _i1.ColumnString(
      'notes',
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

  late final InventoryItemUpdateTable updateTable;

  late final _i1.ColumnUuid householdId;

  /// The household this item belongs to.
  _i2.HouseholdTable? _household;

  /// The id the item was created with on its originating device, before it
  /// had ever been synced. Stable for the lifetime of the item; used to
  /// match retried/offline-created rows to the canonical server row.
  late final _i1.ColumnUuid clientId;

  late final _i1.ColumnString name;

  late final _i1.ColumnEnum<_i3.InventoryItemCategory> category;

  /// EAN/barcode, if the item was added via barcode scan.
  late final _i1.ColumnString barcode;

  /// Open Food Facts product id, if the item was resolved via that lookup.
  late final _i1.ColumnString offProductId;

  late final _i1.ColumnDouble quantity;

  late final _i1.ColumnString unit;

  /// Free-text storage location (e.g. "Keller, Regal 2").
  late final _i1.ColumnString storageLocation;

  late final _i1.ColumnDateTime expirationDate;

  /// Below this quantity, the item is flagged as low-stock.
  late final _i1.ColumnDouble minQuantity;

  /// Total kcal for the item's current [quantity] (not per-unit) — kept
  /// deliberately optional and only meaningful for `category: food`.
  /// Powers the "Vorräte für X Tage" supply calculator's calorie tally.
  late final _i1.ColumnInt calories;

  late final _i1.ColumnString notes;

  /// Server-stamped on every write; the authority for last-write-wins
  /// conflict resolution and for delta-pull ("updatedAt > since") queries.
  late final _i1.ColumnDateTime updatedAt;

  /// Soft-delete tombstone. Never hard-deleted so other devices' pulls can
  /// observe the deletion.
  late final _i1.ColumnDateTime deletedAt;

  _i2.HouseholdTable get household {
    if (_household != null) return _household!;
    _household = _i1.createRelationTable(
      relationFieldName: 'household',
      field: InventoryItem.t.householdId,
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
    clientId,
    name,
    category,
    barcode,
    offProductId,
    quantity,
    unit,
    storageLocation,
    expirationDate,
    minQuantity,
    calories,
    notes,
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

class InventoryItemInclude extends _i1.IncludeObject {
  InventoryItemInclude._({_i2.HouseholdInclude? household}) {
    _household = household;
  }

  _i2.HouseholdInclude? _household;

  @override
  Map<String, _i1.Include?> get includes => {'household': _household};

  @override
  _i1.Table<_i1.UuidValue?> get table => InventoryItem.t;
}

class InventoryItemIncludeList extends _i1.IncludeList {
  InventoryItemIncludeList._({
    _i1.WhereExpressionBuilder<InventoryItemTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(InventoryItem.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => InventoryItem.t;
}

class InventoryItemRepository {
  const InventoryItemRepository._();

  final attachRow = const InventoryItemAttachRowRepository._();

  /// Returns a list of [InventoryItem]s matching the given query parameters.
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
  Future<List<InventoryItem>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<InventoryItemTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<InventoryItemTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<InventoryItemTable>? orderByList,
    _i1.Transaction? transaction,
    InventoryItemInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<InventoryItem>(
      where: where?.call(InventoryItem.t),
      orderBy: orderBy?.call(InventoryItem.t),
      orderByList: orderByList?.call(InventoryItem.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [InventoryItem] matching the given query parameters.
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
  Future<InventoryItem?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<InventoryItemTable>? where,
    int? offset,
    _i1.OrderByBuilder<InventoryItemTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<InventoryItemTable>? orderByList,
    _i1.Transaction? transaction,
    InventoryItemInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<InventoryItem>(
      where: where?.call(InventoryItem.t),
      orderBy: orderBy?.call(InventoryItem.t),
      orderByList: orderByList?.call(InventoryItem.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [InventoryItem] by its [id] or null if no such row exists.
  Future<InventoryItem?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    InventoryItemInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<InventoryItem>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [InventoryItem]s in the list and returns the inserted rows.
  ///
  /// The returned [InventoryItem]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<InventoryItem>> insert(
    _i1.DatabaseSession session,
    List<InventoryItem> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<InventoryItem>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [InventoryItem] and returns the inserted row.
  ///
  /// The returned [InventoryItem] will have its `id` field set.
  Future<InventoryItem> insertRow(
    _i1.DatabaseSession session,
    InventoryItem row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<InventoryItem>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [InventoryItem]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<InventoryItem>> update(
    _i1.DatabaseSession session,
    List<InventoryItem> rows, {
    _i1.ColumnSelections<InventoryItemTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<InventoryItem>(
      rows,
      columns: columns?.call(InventoryItem.t),
      transaction: transaction,
    );
  }

  /// Updates a single [InventoryItem]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<InventoryItem> updateRow(
    _i1.DatabaseSession session,
    InventoryItem row, {
    _i1.ColumnSelections<InventoryItemTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<InventoryItem>(
      row,
      columns: columns?.call(InventoryItem.t),
      transaction: transaction,
    );
  }

  /// Updates a single [InventoryItem] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<InventoryItem?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<InventoryItemUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<InventoryItem>(
      id,
      columnValues: columnValues(InventoryItem.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [InventoryItem]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<InventoryItem>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<InventoryItemUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<InventoryItemTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<InventoryItemTable>? orderBy,
    _i1.OrderByListBuilder<InventoryItemTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<InventoryItem>(
      columnValues: columnValues(InventoryItem.t.updateTable),
      where: where(InventoryItem.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InventoryItem.t),
      orderByList: orderByList?.call(InventoryItem.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [InventoryItem]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<InventoryItem>> delete(
    _i1.DatabaseSession session,
    List<InventoryItem> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<InventoryItem>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [InventoryItem].
  Future<InventoryItem> deleteRow(
    _i1.DatabaseSession session,
    InventoryItem row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<InventoryItem>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<InventoryItem>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<InventoryItemTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<InventoryItem>(
      where: where(InventoryItem.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<InventoryItemTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<InventoryItem>(
      where: where?.call(InventoryItem.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [InventoryItem] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<InventoryItemTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<InventoryItem>(
      where: where(InventoryItem.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class InventoryItemAttachRowRepository {
  const InventoryItemAttachRowRepository._();

  /// Creates a relation between the given [InventoryItem] and [Household]
  /// by setting the [InventoryItem]'s foreign key `householdId` to refer to the [Household].
  Future<void> household(
    _i1.DatabaseSession session,
    InventoryItem inventoryItem,
    _i2.Household household, {
    _i1.Transaction? transaction,
  }) async {
    if (inventoryItem.id == null) {
      throw ArgumentError.notNull('inventoryItem.id');
    }
    if (household.id == null) {
      throw ArgumentError.notNull('household.id');
    }

    var $inventoryItem = inventoryItem.copyWith(householdId: household.id);
    await session.db.updateRow<InventoryItem>(
      $inventoryItem,
      columns: [InventoryItem.t.householdId],
      transaction: transaction,
    );
  }
}
