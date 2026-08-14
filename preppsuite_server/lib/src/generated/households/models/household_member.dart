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
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i3;
import '../../households/models/household_role.dart' as _i4;
import 'package:preppsuite_server/src/generated/protocol.dart' as _i5;

/// Links an authenticated user to a household they belong to.
abstract class HouseholdMember
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  HouseholdMember._({
    this.id,
    required this.householdId,
    this.household,
    required this.authUserId,
    this.authUser,
    required this.displayName,
    required this.role,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory HouseholdMember({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i1.UuidValue authUserId,
    _i3.AuthUser? authUser,
    required String displayName,
    required _i4.HouseholdRole role,
    DateTime? joinedAt,
  }) = _HouseholdMemberImpl;

  factory HouseholdMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return HouseholdMember(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      householdId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['householdId'],
      ),
      household: jsonSerialization['household'] == null
          ? null
          : _i5.Protocol().deserialize<_i2.Household>(
              jsonSerialization['household'],
            ),
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _i5.Protocol().deserialize<_i3.AuthUser>(
              jsonSerialization['authUser'],
            ),
      displayName: jsonSerialization['displayName'] as String,
      role: _i4.HouseholdRole.fromJson((jsonSerialization['role'] as String)),
      joinedAt: jsonSerialization['joinedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['joinedAt']),
    );
  }

  static final t = HouseholdMemberTable();

  static const db = HouseholdMemberRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue householdId;

  /// The household this membership belongs to.
  _i2.Household? household;

  _i1.UuidValue authUserId;

  /// The authenticated user this membership belongs to.
  _i3.AuthUser? authUser;

  /// Name shown to other household members.
  String displayName;

  /// Whether this member can rotate the invite code and remove members.
  _i4.HouseholdRole role;

  /// The time when this user joined the household.
  DateTime joinedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [HouseholdMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  HouseholdMember copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    _i1.UuidValue? authUserId,
    _i3.AuthUser? authUser,
    String? displayName,
    _i4.HouseholdRole? role,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HouseholdMember',
      if (id != null) 'id': id?.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'displayName': displayName,
      'role': role.toJson(),
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'HouseholdMember',
      if (id != null) 'id': id?.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJsonForProtocol(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJsonForProtocol(),
      'displayName': displayName,
      'role': role.toJson(),
      'joinedAt': joinedAt.toJson(),
    };
  }

  static HouseholdMemberInclude include({
    _i2.HouseholdInclude? household,
    _i3.AuthUserInclude? authUser,
  }) {
    return HouseholdMemberInclude._(
      household: household,
      authUser: authUser,
    );
  }

  static HouseholdMemberIncludeList includeList({
    _i1.WhereExpressionBuilder<HouseholdMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<HouseholdMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<HouseholdMemberTable>? orderByList,
    HouseholdMemberInclude? include,
  }) {
    return HouseholdMemberIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(HouseholdMember.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(HouseholdMember.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HouseholdMemberImpl extends HouseholdMember {
  _HouseholdMemberImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i1.UuidValue authUserId,
    _i3.AuthUser? authUser,
    required String displayName,
    required _i4.HouseholdRole role,
    DateTime? joinedAt,
  }) : super._(
         id: id,
         householdId: householdId,
         household: household,
         authUserId: authUserId,
         authUser: authUser,
         displayName: displayName,
         role: role,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [HouseholdMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  HouseholdMember copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? householdId,
    Object? household = _Undefined,
    _i1.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? displayName,
    _i4.HouseholdRole? role,
    DateTime? joinedAt,
  }) {
    return HouseholdMember(
      id: id is _i1.UuidValue? ? id : this.id,
      householdId: householdId ?? this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _i3.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class HouseholdMemberUpdateTable extends _i1.UpdateTable<HouseholdMemberTable> {
  HouseholdMemberUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> householdId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.householdId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<String, String> displayName(String value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<_i4.HouseholdRole, _i4.HouseholdRole> role(
    _i4.HouseholdRole value,
  ) => _i1.ColumnValue(
    table.role,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> joinedAt(DateTime value) =>
      _i1.ColumnValue(
        table.joinedAt,
        value,
      );
}

class HouseholdMemberTable extends _i1.Table<_i1.UuidValue?> {
  HouseholdMemberTable({super.tableRelation})
    : super(tableName: 'household_member') {
    updateTable = HouseholdMemberUpdateTable(this);
    householdId = _i1.ColumnUuid(
      'householdId',
      this,
    );
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    displayName = _i1.ColumnString(
      'displayName',
      this,
    );
    role = _i1.ColumnEnum(
      'role',
      this,
      _i1.EnumSerialization.byName,
    );
    joinedAt = _i1.ColumnDateTime(
      'joinedAt',
      this,
    );
  }

  late final HouseholdMemberUpdateTable updateTable;

  late final _i1.ColumnUuid householdId;

  /// The household this membership belongs to.
  _i2.HouseholdTable? _household;

  late final _i1.ColumnUuid authUserId;

  /// The authenticated user this membership belongs to.
  _i3.AuthUserTable? _authUser;

  /// Name shown to other household members.
  late final _i1.ColumnString displayName;

  /// Whether this member can rotate the invite code and remove members.
  late final _i1.ColumnEnum<_i4.HouseholdRole> role;

  /// The time when this user joined the household.
  late final _i1.ColumnDateTime joinedAt;

  _i2.HouseholdTable get household {
    if (_household != null) return _household!;
    _household = _i1.createRelationTable(
      relationFieldName: 'household',
      field: HouseholdMember.t.householdId,
      foreignField: _i2.Household.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.HouseholdTable(tableRelation: foreignTableRelation),
    );
    return _household!;
  }

  _i3.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _i1.createRelationTable(
      relationFieldName: 'authUser',
      field: HouseholdMember.t.authUserId,
      foreignField: _i3.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _authUser!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    householdId,
    authUserId,
    displayName,
    role,
    joinedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'household') {
      return household;
    }
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class HouseholdMemberInclude extends _i1.IncludeObject {
  HouseholdMemberInclude._({
    _i2.HouseholdInclude? household,
    _i3.AuthUserInclude? authUser,
  }) {
    _household = household;
    _authUser = authUser;
  }

  _i2.HouseholdInclude? _household;

  _i3.AuthUserInclude? _authUser;

  @override
  Map<String, _i1.Include?> get includes => {
    'household': _household,
    'authUser': _authUser,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => HouseholdMember.t;
}

class HouseholdMemberIncludeList extends _i1.IncludeList {
  HouseholdMemberIncludeList._({
    _i1.WhereExpressionBuilder<HouseholdMemberTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(HouseholdMember.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => HouseholdMember.t;
}

class HouseholdMemberRepository {
  const HouseholdMemberRepository._();

  final attachRow = const HouseholdMemberAttachRowRepository._();

  /// Returns a list of [HouseholdMember]s matching the given query parameters.
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
  Future<List<HouseholdMember>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<HouseholdMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<HouseholdMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<HouseholdMemberTable>? orderByList,
    _i1.Transaction? transaction,
    HouseholdMemberInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<HouseholdMember>(
      where: where?.call(HouseholdMember.t),
      orderBy: orderBy?.call(HouseholdMember.t),
      orderByList: orderByList?.call(HouseholdMember.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [HouseholdMember] matching the given query parameters.
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
  Future<HouseholdMember?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<HouseholdMemberTable>? where,
    int? offset,
    _i1.OrderByBuilder<HouseholdMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<HouseholdMemberTable>? orderByList,
    _i1.Transaction? transaction,
    HouseholdMemberInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<HouseholdMember>(
      where: where?.call(HouseholdMember.t),
      orderBy: orderBy?.call(HouseholdMember.t),
      orderByList: orderByList?.call(HouseholdMember.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [HouseholdMember] by its [id] or null if no such row exists.
  Future<HouseholdMember?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    HouseholdMemberInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<HouseholdMember>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [HouseholdMember]s in the list and returns the inserted rows.
  ///
  /// The returned [HouseholdMember]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<HouseholdMember>> insert(
    _i1.DatabaseSession session,
    List<HouseholdMember> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<HouseholdMember>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [HouseholdMember] and returns the inserted row.
  ///
  /// The returned [HouseholdMember] will have its `id` field set.
  Future<HouseholdMember> insertRow(
    _i1.DatabaseSession session,
    HouseholdMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<HouseholdMember>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [HouseholdMember]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<HouseholdMember>> update(
    _i1.DatabaseSession session,
    List<HouseholdMember> rows, {
    _i1.ColumnSelections<HouseholdMemberTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<HouseholdMember>(
      rows,
      columns: columns?.call(HouseholdMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [HouseholdMember]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<HouseholdMember> updateRow(
    _i1.DatabaseSession session,
    HouseholdMember row, {
    _i1.ColumnSelections<HouseholdMemberTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<HouseholdMember>(
      row,
      columns: columns?.call(HouseholdMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [HouseholdMember] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<HouseholdMember?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<HouseholdMemberUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<HouseholdMember>(
      id,
      columnValues: columnValues(HouseholdMember.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [HouseholdMember]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<HouseholdMember>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<HouseholdMemberUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<HouseholdMemberTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<HouseholdMemberTable>? orderBy,
    _i1.OrderByListBuilder<HouseholdMemberTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<HouseholdMember>(
      columnValues: columnValues(HouseholdMember.t.updateTable),
      where: where(HouseholdMember.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(HouseholdMember.t),
      orderByList: orderByList?.call(HouseholdMember.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [HouseholdMember]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<HouseholdMember>> delete(
    _i1.DatabaseSession session,
    List<HouseholdMember> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<HouseholdMember>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [HouseholdMember].
  Future<HouseholdMember> deleteRow(
    _i1.DatabaseSession session,
    HouseholdMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<HouseholdMember>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<HouseholdMember>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<HouseholdMemberTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<HouseholdMember>(
      where: where(HouseholdMember.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<HouseholdMemberTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<HouseholdMember>(
      where: where?.call(HouseholdMember.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [HouseholdMember] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<HouseholdMemberTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<HouseholdMember>(
      where: where(HouseholdMember.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class HouseholdMemberAttachRowRepository {
  const HouseholdMemberAttachRowRepository._();

  /// Creates a relation between the given [HouseholdMember] and [Household]
  /// by setting the [HouseholdMember]'s foreign key `householdId` to refer to the [Household].
  Future<void> household(
    _i1.DatabaseSession session,
    HouseholdMember householdMember,
    _i2.Household household, {
    _i1.Transaction? transaction,
  }) async {
    if (householdMember.id == null) {
      throw ArgumentError.notNull('householdMember.id');
    }
    if (household.id == null) {
      throw ArgumentError.notNull('household.id');
    }

    var $householdMember = householdMember.copyWith(householdId: household.id);
    await session.db.updateRow<HouseholdMember>(
      $householdMember,
      columns: [HouseholdMember.t.householdId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [HouseholdMember] and [AuthUser]
  /// by setting the [HouseholdMember]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _i1.DatabaseSession session,
    HouseholdMember householdMember,
    _i3.AuthUser authUser, {
    _i1.Transaction? transaction,
  }) async {
    if (householdMember.id == null) {
      throw ArgumentError.notNull('householdMember.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $householdMember = householdMember.copyWith(authUserId: authUser.id);
    await session.db.updateRow<HouseholdMember>(
      $householdMember,
      columns: [HouseholdMember.t.authUserId],
      transaction: transaction,
    );
  }
}
