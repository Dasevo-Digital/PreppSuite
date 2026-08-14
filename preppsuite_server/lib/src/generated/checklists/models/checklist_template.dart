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
import '../../checklists/models/checklist_category.dart' as _i3;
import 'package:preppsuite_server/src/generated/protocol.dart' as _i4;

/// A checklist a household works through (e.g. "Wasser", "Erste-Hilfe").
///
/// [household] is null for built-in templates shared read-only across all
/// households (seeded once at server startup, see `ChecklistSeeder`).
/// A household that wants to customize a built-in copies it client-side
/// into its own template (copy-on-customize) rather than editing the
/// shared original.
abstract class ChecklistTemplate
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  ChecklistTemplate._({
    this.id,
    required this.clientId,
    this.householdId,
    this.household,
    required this.title,
    required this.category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    this.deletedAt,
  }) : isBuiltIn = isBuiltIn ?? false,
       updatedAt = updatedAt ?? DateTime.now();

  factory ChecklistTemplate({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    required String title,
    required _i3.ChecklistCategory category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _ChecklistTemplateImpl;

  factory ChecklistTemplate.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChecklistTemplate(
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
      title: jsonSerialization['title'] as String,
      category: _i3.ChecklistCategory.fromJson(
        (jsonSerialization['category'] as String),
      ),
      isBuiltIn: jsonSerialization['isBuiltIn'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isBuiltIn']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = ChecklistTemplateTable();

  static const db = ChecklistTemplateRepository._();

  @override
  _i1.UuidValue? id;

  /// The id the template was created with on its originating device, before
  /// it had ever been synced.
  _i1.UuidValue clientId;

  _i1.UuidValue? householdId;

  /// Null for built-in, shared templates.
  _i2.Household? household;

  String title;

  _i3.ChecklistCategory category;

  bool isBuiltIn;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ChecklistTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChecklistTemplate copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    String? title,
    _i3.ChecklistCategory? category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChecklistTemplate',
      if (id != null) 'id': id?.toJson(),
      'clientId': clientId.toJson(),
      if (householdId != null) 'householdId': householdId?.toJson(),
      if (household != null) 'household': household?.toJson(),
      'title': title,
      'category': category.toJson(),
      'isBuiltIn': isBuiltIn,
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ChecklistTemplate',
      if (id != null) 'id': id?.toJson(),
      'clientId': clientId.toJson(),
      if (householdId != null) 'householdId': householdId?.toJson(),
      if (household != null) 'household': household?.toJsonForProtocol(),
      'title': title,
      'category': category.toJson(),
      'isBuiltIn': isBuiltIn,
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static ChecklistTemplateInclude include({_i2.HouseholdInclude? household}) {
    return ChecklistTemplateInclude._(household: household);
  }

  static ChecklistTemplateIncludeList includeList({
    _i1.WhereExpressionBuilder<ChecklistTemplateTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChecklistTemplateTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChecklistTemplateTable>? orderByList,
    ChecklistTemplateInclude? include,
  }) {
    return ChecklistTemplateIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChecklistTemplate.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ChecklistTemplate.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChecklistTemplateImpl extends ChecklistTemplate {
  _ChecklistTemplateImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    required String title,
    required _i3.ChecklistCategory category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         clientId: clientId,
         householdId: householdId,
         household: household,
         title: title,
         category: category,
         isBuiltIn: isBuiltIn,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [ChecklistTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChecklistTemplate copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? clientId,
    Object? householdId = _Undefined,
    Object? household = _Undefined,
    String? title,
    _i3.ChecklistCategory? category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return ChecklistTemplate(
      id: id is _i1.UuidValue? ? id : this.id,
      clientId: clientId ?? this.clientId,
      householdId: householdId is _i1.UuidValue?
          ? householdId
          : this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      title: title ?? this.title,
      category: category ?? this.category,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class ChecklistTemplateUpdateTable
    extends _i1.UpdateTable<ChecklistTemplateTable> {
  ChecklistTemplateUpdateTable(super.table);

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

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<_i3.ChecklistCategory, _i3.ChecklistCategory> category(
    _i3.ChecklistCategory value,
  ) => _i1.ColumnValue(
    table.category,
    value,
  );

  _i1.ColumnValue<bool, bool> isBuiltIn(bool value) => _i1.ColumnValue(
    table.isBuiltIn,
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

class ChecklistTemplateTable extends _i1.Table<_i1.UuidValue?> {
  ChecklistTemplateTable({super.tableRelation})
    : super(tableName: 'checklist_template') {
    updateTable = ChecklistTemplateUpdateTable(this);
    clientId = _i1.ColumnUuid(
      'clientId',
      this,
    );
    householdId = _i1.ColumnUuid(
      'householdId',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    category = _i1.ColumnEnum(
      'category',
      this,
      _i1.EnumSerialization.byName,
    );
    isBuiltIn = _i1.ColumnBool(
      'isBuiltIn',
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

  late final ChecklistTemplateUpdateTable updateTable;

  /// The id the template was created with on its originating device, before
  /// it had ever been synced.
  late final _i1.ColumnUuid clientId;

  late final _i1.ColumnUuid householdId;

  /// Null for built-in, shared templates.
  _i2.HouseholdTable? _household;

  late final _i1.ColumnString title;

  late final _i1.ColumnEnum<_i3.ChecklistCategory> category;

  late final _i1.ColumnBool isBuiltIn;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnDateTime deletedAt;

  _i2.HouseholdTable get household {
    if (_household != null) return _household!;
    _household = _i1.createRelationTable(
      relationFieldName: 'household',
      field: ChecklistTemplate.t.householdId,
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
    title,
    category,
    isBuiltIn,
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

class ChecklistTemplateInclude extends _i1.IncludeObject {
  ChecklistTemplateInclude._({_i2.HouseholdInclude? household}) {
    _household = household;
  }

  _i2.HouseholdInclude? _household;

  @override
  Map<String, _i1.Include?> get includes => {'household': _household};

  @override
  _i1.Table<_i1.UuidValue?> get table => ChecklistTemplate.t;
}

class ChecklistTemplateIncludeList extends _i1.IncludeList {
  ChecklistTemplateIncludeList._({
    _i1.WhereExpressionBuilder<ChecklistTemplateTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ChecklistTemplate.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ChecklistTemplate.t;
}

class ChecklistTemplateRepository {
  const ChecklistTemplateRepository._();

  final attachRow = const ChecklistTemplateAttachRowRepository._();

  final detachRow = const ChecklistTemplateDetachRowRepository._();

  /// Returns a list of [ChecklistTemplate]s matching the given query parameters.
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
  Future<List<ChecklistTemplate>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ChecklistTemplateTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChecklistTemplateTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChecklistTemplateTable>? orderByList,
    _i1.Transaction? transaction,
    ChecklistTemplateInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ChecklistTemplate>(
      where: where?.call(ChecklistTemplate.t),
      orderBy: orderBy?.call(ChecklistTemplate.t),
      orderByList: orderByList?.call(ChecklistTemplate.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ChecklistTemplate] matching the given query parameters.
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
  Future<ChecklistTemplate?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ChecklistTemplateTable>? where,
    int? offset,
    _i1.OrderByBuilder<ChecklistTemplateTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChecklistTemplateTable>? orderByList,
    _i1.Transaction? transaction,
    ChecklistTemplateInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ChecklistTemplate>(
      where: where?.call(ChecklistTemplate.t),
      orderBy: orderBy?.call(ChecklistTemplate.t),
      orderByList: orderByList?.call(ChecklistTemplate.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ChecklistTemplate] by its [id] or null if no such row exists.
  Future<ChecklistTemplate?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    ChecklistTemplateInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ChecklistTemplate>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ChecklistTemplate]s in the list and returns the inserted rows.
  ///
  /// The returned [ChecklistTemplate]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ChecklistTemplate>> insert(
    _i1.DatabaseSession session,
    List<ChecklistTemplate> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ChecklistTemplate>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ChecklistTemplate] and returns the inserted row.
  ///
  /// The returned [ChecklistTemplate] will have its `id` field set.
  Future<ChecklistTemplate> insertRow(
    _i1.DatabaseSession session,
    ChecklistTemplate row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ChecklistTemplate>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ChecklistTemplate]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ChecklistTemplate>> update(
    _i1.DatabaseSession session,
    List<ChecklistTemplate> rows, {
    _i1.ColumnSelections<ChecklistTemplateTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ChecklistTemplate>(
      rows,
      columns: columns?.call(ChecklistTemplate.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ChecklistTemplate]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ChecklistTemplate> updateRow(
    _i1.DatabaseSession session,
    ChecklistTemplate row, {
    _i1.ColumnSelections<ChecklistTemplateTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ChecklistTemplate>(
      row,
      columns: columns?.call(ChecklistTemplate.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ChecklistTemplate] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ChecklistTemplate?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ChecklistTemplateUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ChecklistTemplate>(
      id,
      columnValues: columnValues(ChecklistTemplate.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ChecklistTemplate]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ChecklistTemplate>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ChecklistTemplateUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ChecklistTemplateTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChecklistTemplateTable>? orderBy,
    _i1.OrderByListBuilder<ChecklistTemplateTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ChecklistTemplate>(
      columnValues: columnValues(ChecklistTemplate.t.updateTable),
      where: where(ChecklistTemplate.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChecklistTemplate.t),
      orderByList: orderByList?.call(ChecklistTemplate.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ChecklistTemplate]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ChecklistTemplate>> delete(
    _i1.DatabaseSession session,
    List<ChecklistTemplate> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ChecklistTemplate>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ChecklistTemplate].
  Future<ChecklistTemplate> deleteRow(
    _i1.DatabaseSession session,
    ChecklistTemplate row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ChecklistTemplate>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ChecklistTemplate>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ChecklistTemplateTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ChecklistTemplate>(
      where: where(ChecklistTemplate.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ChecklistTemplateTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ChecklistTemplate>(
      where: where?.call(ChecklistTemplate.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ChecklistTemplate] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ChecklistTemplateTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ChecklistTemplate>(
      where: where(ChecklistTemplate.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ChecklistTemplateAttachRowRepository {
  const ChecklistTemplateAttachRowRepository._();

  /// Creates a relation between the given [ChecklistTemplate] and [Household]
  /// by setting the [ChecklistTemplate]'s foreign key `householdId` to refer to the [Household].
  Future<void> household(
    _i1.DatabaseSession session,
    ChecklistTemplate checklistTemplate,
    _i2.Household household, {
    _i1.Transaction? transaction,
  }) async {
    if (checklistTemplate.id == null) {
      throw ArgumentError.notNull('checklistTemplate.id');
    }
    if (household.id == null) {
      throw ArgumentError.notNull('household.id');
    }

    var $checklistTemplate = checklistTemplate.copyWith(
      householdId: household.id,
    );
    await session.db.updateRow<ChecklistTemplate>(
      $checklistTemplate,
      columns: [ChecklistTemplate.t.householdId],
      transaction: transaction,
    );
  }
}

class ChecklistTemplateDetachRowRepository {
  const ChecklistTemplateDetachRowRepository._();

  /// Detaches the relation between this [ChecklistTemplate] and the [Household] set in `household`
  /// by setting the [ChecklistTemplate]'s foreign key `householdId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> household(
    _i1.DatabaseSession session,
    ChecklistTemplate checklistTemplate, {
    _i1.Transaction? transaction,
  }) async {
    if (checklistTemplate.id == null) {
      throw ArgumentError.notNull('checklistTemplate.id');
    }

    var $checklistTemplate = checklistTemplate.copyWith(householdId: null);
    await session.db.updateRow<ChecklistTemplate>(
      $checklistTemplate,
      columns: [ChecklistTemplate.t.householdId],
      transaction: transaction,
    );
  }
}
