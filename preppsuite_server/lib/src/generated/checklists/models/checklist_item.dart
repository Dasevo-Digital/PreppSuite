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
import '../../checklists/models/checklist_template.dart' as _i3;
import 'package:preppsuite_server/src/generated/protocol.dart' as _i4;

/// A single line item within a [ChecklistTemplate]. [household] mirrors
/// its template's household (null for built-in template items) so item
/// sync/authorization doesn't require joining through the template.
abstract class ChecklistItem
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  ChecklistItem._({
    this.id,
    required this.clientId,
    this.householdId,
    this.household,
    required this.templateId,
    this.template,
    required this.title,
    this.targetQuantity,
    bool? isChecked,
    this.linkedInventoryItemId,
    int? sortOrder,
    DateTime? updatedAt,
    this.deletedAt,
  }) : isChecked = isChecked ?? false,
       sortOrder = sortOrder ?? 0,
       updatedAt = updatedAt ?? DateTime.now();

  factory ChecklistItem({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    required _i1.UuidValue templateId,
    _i3.ChecklistTemplate? template,
    required String title,
    double? targetQuantity,
    bool? isChecked,
    _i1.UuidValue? linkedInventoryItemId,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _ChecklistItemImpl;

  factory ChecklistItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChecklistItem(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      clientId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientId'],
      ),
      householdId: jsonSerialization['householdId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['householdId'],
            ),
      household: jsonSerialization['household'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Household>(
              jsonSerialization['household'],
            ),
      templateId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['templateId'],
      ),
      template: jsonSerialization['template'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.ChecklistTemplate>(
              jsonSerialization['template'],
            ),
      title: jsonSerialization['title'] as String,
      targetQuantity: (jsonSerialization['targetQuantity'] as num?)?.toDouble(),
      isChecked: jsonSerialization['isChecked'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isChecked']),
      linkedInventoryItemId: jsonSerialization['linkedInventoryItemId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['linkedInventoryItemId'],
            ),
      sortOrder: jsonSerialization['sortOrder'] as int?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = ChecklistItemTable();

  static const db = ChecklistItemRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue clientId;

  _i1.UuidValue? householdId;

  _i2.Household? household;

  _i1.UuidValue templateId;

  _i3.ChecklistTemplate? template;

  String title;

  double? targetQuantity;

  bool isChecked;

  /// Optional, manual-only in v1: a future phase may use this to derive
  /// completion from live inventory stock instead.
  _i1.UuidValue? linkedInventoryItemId;

  int sortOrder;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ChecklistItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChecklistItem copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    _i1.UuidValue? templateId,
    _i3.ChecklistTemplate? template,
    String? title,
    double? targetQuantity,
    bool? isChecked,
    _i1.UuidValue? linkedInventoryItemId,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChecklistItem',
      if (id != null) 'id': id?.toJson(),
      'clientId': clientId.toJson(),
      if (householdId != null) 'householdId': householdId?.toJson(),
      if (household != null) 'household': household?.toJson(),
      'templateId': templateId.toJson(),
      if (template != null) 'template': template?.toJson(),
      'title': title,
      if (targetQuantity != null) 'targetQuantity': targetQuantity,
      'isChecked': isChecked,
      if (linkedInventoryItemId != null)
        'linkedInventoryItemId': linkedInventoryItemId?.toJson(),
      'sortOrder': sortOrder,
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ChecklistItem',
      if (id != null) 'id': id?.toJson(),
      'clientId': clientId.toJson(),
      if (householdId != null) 'householdId': householdId?.toJson(),
      if (household != null) 'household': household?.toJsonForProtocol(),
      'templateId': templateId.toJson(),
      if (template != null) 'template': template?.toJsonForProtocol(),
      'title': title,
      if (targetQuantity != null) 'targetQuantity': targetQuantity,
      'isChecked': isChecked,
      if (linkedInventoryItemId != null)
        'linkedInventoryItemId': linkedInventoryItemId?.toJson(),
      'sortOrder': sortOrder,
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static ChecklistItemInclude include({
    _i2.HouseholdInclude? household,
    _i3.ChecklistTemplateInclude? template,
  }) {
    return ChecklistItemInclude._(
      household: household,
      template: template,
    );
  }

  static ChecklistItemIncludeList includeList({
    _i1.WhereExpressionBuilder<ChecklistItemTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChecklistItemTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChecklistItemTable>? orderByList,
    ChecklistItemInclude? include,
  }) {
    return ChecklistItemIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChecklistItem.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ChecklistItem.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChecklistItemImpl extends ChecklistItem {
  _ChecklistItemImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    required _i1.UuidValue templateId,
    _i3.ChecklistTemplate? template,
    required String title,
    double? targetQuantity,
    bool? isChecked,
    _i1.UuidValue? linkedInventoryItemId,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         clientId: clientId,
         householdId: householdId,
         household: household,
         templateId: templateId,
         template: template,
         title: title,
         targetQuantity: targetQuantity,
         isChecked: isChecked,
         linkedInventoryItemId: linkedInventoryItemId,
         sortOrder: sortOrder,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [ChecklistItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChecklistItem copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? clientId,
    Object? householdId = _Undefined,
    Object? household = _Undefined,
    _i1.UuidValue? templateId,
    Object? template = _Undefined,
    String? title,
    Object? targetQuantity = _Undefined,
    bool? isChecked,
    Object? linkedInventoryItemId = _Undefined,
    int? sortOrder,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return ChecklistItem(
      id: id is _i1.UuidValue? ? id : this.id,
      clientId: clientId ?? this.clientId,
      householdId: householdId is _i1.UuidValue?
          ? householdId
          : this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      templateId: templateId ?? this.templateId,
      template: template is _i3.ChecklistTemplate?
          ? template
          : this.template?.copyWith(),
      title: title ?? this.title,
      targetQuantity: targetQuantity is double?
          ? targetQuantity
          : this.targetQuantity,
      isChecked: isChecked ?? this.isChecked,
      linkedInventoryItemId: linkedInventoryItemId is _i1.UuidValue?
          ? linkedInventoryItemId
          : this.linkedInventoryItemId,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class ChecklistItemUpdateTable extends _i1.UpdateTable<ChecklistItemTable> {
  ChecklistItemUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> clientId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.clientId,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> householdId(
    _i1.UuidValue? value,
  ) => _i1.ColumnValue(
    table.householdId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> templateId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.templateId,
    value,
  );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<double, double> targetQuantity(double? value) =>
      _i1.ColumnValue(
        table.targetQuantity,
        value,
      );

  _i1.ColumnValue<bool, bool> isChecked(bool value) => _i1.ColumnValue(
    table.isChecked,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> linkedInventoryItemId(
    _i1.UuidValue? value,
  ) => _i1.ColumnValue(
    table.linkedInventoryItemId,
    value,
  );

  _i1.ColumnValue<int, int> sortOrder(int value) => _i1.ColumnValue(
    table.sortOrder,
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

class ChecklistItemTable extends _i1.Table<_i1.UuidValue?> {
  ChecklistItemTable({super.tableRelation})
    : super(tableName: 'checklist_item') {
    updateTable = ChecklistItemUpdateTable(this);
    clientId = _i1.ColumnUuid(
      'clientId',
      this,
    );
    householdId = _i1.ColumnUuid(
      'householdId',
      this,
    );
    templateId = _i1.ColumnUuid(
      'templateId',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    targetQuantity = _i1.ColumnDouble(
      'targetQuantity',
      this,
    );
    isChecked = _i1.ColumnBool(
      'isChecked',
      this,
    );
    linkedInventoryItemId = _i1.ColumnUuid(
      'linkedInventoryItemId',
      this,
    );
    sortOrder = _i1.ColumnInt(
      'sortOrder',
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

  late final ChecklistItemUpdateTable updateTable;

  late final _i1.ColumnUuid clientId;

  late final _i1.ColumnUuid householdId;

  _i2.HouseholdTable? _household;

  late final _i1.ColumnUuid templateId;

  _i3.ChecklistTemplateTable? _template;

  late final _i1.ColumnString title;

  late final _i1.ColumnDouble targetQuantity;

  late final _i1.ColumnBool isChecked;

  /// Optional, manual-only in v1: a future phase may use this to derive
  /// completion from live inventory stock instead.
  late final _i1.ColumnUuid linkedInventoryItemId;

  late final _i1.ColumnInt sortOrder;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnDateTime deletedAt;

  _i2.HouseholdTable get household {
    if (_household != null) return _household!;
    _household = _i1.createRelationTable(
      relationFieldName: 'household',
      field: ChecklistItem.t.householdId,
      foreignField: _i2.Household.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.HouseholdTable(tableRelation: foreignTableRelation),
    );
    return _household!;
  }

  _i3.ChecklistTemplateTable get template {
    if (_template != null) return _template!;
    _template = _i1.createRelationTable(
      relationFieldName: 'template',
      field: ChecklistItem.t.templateId,
      foreignField: _i3.ChecklistTemplate.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.ChecklistTemplateTable(tableRelation: foreignTableRelation),
    );
    return _template!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    clientId,
    householdId,
    templateId,
    title,
    targetQuantity,
    isChecked,
    linkedInventoryItemId,
    sortOrder,
    updatedAt,
    deletedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'household') {
      return household;
    }
    if (relationField == 'template') {
      return template;
    }
    return null;
  }
}

class ChecklistItemInclude extends _i1.IncludeObject {
  ChecklistItemInclude._({
    _i2.HouseholdInclude? household,
    _i3.ChecklistTemplateInclude? template,
  }) {
    _household = household;
    _template = template;
  }

  _i2.HouseholdInclude? _household;

  _i3.ChecklistTemplateInclude? _template;

  @override
  Map<String, _i1.Include?> get includes => {
    'household': _household,
    'template': _template,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => ChecklistItem.t;
}

class ChecklistItemIncludeList extends _i1.IncludeList {
  ChecklistItemIncludeList._({
    _i1.WhereExpressionBuilder<ChecklistItemTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ChecklistItem.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ChecklistItem.t;
}

class ChecklistItemRepository {
  const ChecklistItemRepository._();

  final attachRow = const ChecklistItemAttachRowRepository._();

  final detachRow = const ChecklistItemDetachRowRepository._();

  /// Returns a list of [ChecklistItem]s matching the given query parameters.
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
  Future<List<ChecklistItem>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ChecklistItemTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChecklistItemTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChecklistItemTable>? orderByList,
    _i1.Transaction? transaction,
    ChecklistItemInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ChecklistItem>(
      where: where?.call(ChecklistItem.t),
      orderBy: orderBy?.call(ChecklistItem.t),
      orderByList: orderByList?.call(ChecklistItem.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ChecklistItem] matching the given query parameters.
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
  Future<ChecklistItem?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ChecklistItemTable>? where,
    int? offset,
    _i1.OrderByBuilder<ChecklistItemTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChecklistItemTable>? orderByList,
    _i1.Transaction? transaction,
    ChecklistItemInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ChecklistItem>(
      where: where?.call(ChecklistItem.t),
      orderBy: orderBy?.call(ChecklistItem.t),
      orderByList: orderByList?.call(ChecklistItem.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ChecklistItem] by its [id] or null if no such row exists.
  Future<ChecklistItem?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    ChecklistItemInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ChecklistItem>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ChecklistItem]s in the list and returns the inserted rows.
  ///
  /// The returned [ChecklistItem]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ChecklistItem>> insert(
    _i1.DatabaseSession session,
    List<ChecklistItem> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ChecklistItem>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ChecklistItem] and returns the inserted row.
  ///
  /// The returned [ChecklistItem] will have its `id` field set.
  Future<ChecklistItem> insertRow(
    _i1.DatabaseSession session,
    ChecklistItem row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ChecklistItem>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ChecklistItem]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ChecklistItem>> update(
    _i1.DatabaseSession session,
    List<ChecklistItem> rows, {
    _i1.ColumnSelections<ChecklistItemTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ChecklistItem>(
      rows,
      columns: columns?.call(ChecklistItem.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ChecklistItem]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ChecklistItem> updateRow(
    _i1.DatabaseSession session,
    ChecklistItem row, {
    _i1.ColumnSelections<ChecklistItemTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ChecklistItem>(
      row,
      columns: columns?.call(ChecklistItem.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ChecklistItem] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ChecklistItem?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ChecklistItemUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ChecklistItem>(
      id,
      columnValues: columnValues(ChecklistItem.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ChecklistItem]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ChecklistItem>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ChecklistItemUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ChecklistItemTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChecklistItemTable>? orderBy,
    _i1.OrderByListBuilder<ChecklistItemTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ChecklistItem>(
      columnValues: columnValues(ChecklistItem.t.updateTable),
      where: where(ChecklistItem.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChecklistItem.t),
      orderByList: orderByList?.call(ChecklistItem.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ChecklistItem]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ChecklistItem>> delete(
    _i1.DatabaseSession session,
    List<ChecklistItem> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ChecklistItem>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ChecklistItem].
  Future<ChecklistItem> deleteRow(
    _i1.DatabaseSession session,
    ChecklistItem row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ChecklistItem>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ChecklistItem>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ChecklistItemTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ChecklistItem>(
      where: where(ChecklistItem.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ChecklistItemTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ChecklistItem>(
      where: where?.call(ChecklistItem.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ChecklistItem] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ChecklistItemTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ChecklistItem>(
      where: where(ChecklistItem.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ChecklistItemAttachRowRepository {
  const ChecklistItemAttachRowRepository._();

  /// Creates a relation between the given [ChecklistItem] and [Household]
  /// by setting the [ChecklistItem]'s foreign key `householdId` to refer to the [Household].
  Future<void> household(
    _i1.DatabaseSession session,
    ChecklistItem checklistItem,
    _i2.Household household, {
    _i1.Transaction? transaction,
  }) async {
    if (checklistItem.id == null) {
      throw ArgumentError.notNull('checklistItem.id');
    }
    if (household.id == null) {
      throw ArgumentError.notNull('household.id');
    }

    var $checklistItem = checklistItem.copyWith(householdId: household.id);
    await session.db.updateRow<ChecklistItem>(
      $checklistItem,
      columns: [ChecklistItem.t.householdId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ChecklistItem] and [ChecklistTemplate]
  /// by setting the [ChecklistItem]'s foreign key `templateId` to refer to the [ChecklistTemplate].
  Future<void> template(
    _i1.DatabaseSession session,
    ChecklistItem checklistItem,
    _i3.ChecklistTemplate template, {
    _i1.Transaction? transaction,
  }) async {
    if (checklistItem.id == null) {
      throw ArgumentError.notNull('checklistItem.id');
    }
    if (template.id == null) {
      throw ArgumentError.notNull('template.id');
    }

    var $checklistItem = checklistItem.copyWith(templateId: template.id);
    await session.db.updateRow<ChecklistItem>(
      $checklistItem,
      columns: [ChecklistItem.t.templateId],
      transaction: transaction,
    );
  }
}

class ChecklistItemDetachRowRepository {
  const ChecklistItemDetachRowRepository._();

  /// Detaches the relation between this [ChecklistItem] and the [Household] set in `household`
  /// by setting the [ChecklistItem]'s foreign key `householdId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> household(
    _i1.DatabaseSession session,
    ChecklistItem checklistItem, {
    _i1.Transaction? transaction,
  }) async {
    if (checklistItem.id == null) {
      throw ArgumentError.notNull('checklistItem.id');
    }

    var $checklistItem = checklistItem.copyWith(householdId: null);
    await session.db.updateRow<ChecklistItem>(
      $checklistItem,
      columns: [ChecklistItem.t.householdId],
      transaction: transaction,
    );
  }
}
