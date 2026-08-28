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
import '../../notifications/models/push_platform.dart' as _i4;
import 'package:preppsuite_server/src/generated/protocol.dart' as _i5;

/// One device that has opted in to warning push notifications.
///
/// Keyed by the FCM registration token, which is the device's identity as
/// far as the push service is concerned. The token is not stable: it
/// rotates on reinstall, on restore-to-a-new-phone, and occasionally on
/// its own, so the client re-registers on every launch and the token — not
/// the user, not the household — carries the uniqueness constraint. A
/// token that reappears under a different account therefore moves rather
/// than duplicating (see `PushDeviceService.register`).
abstract class PushDevice
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  PushDevice._({
    this.id,
    required this.householdId,
    this.household,
    required this.authUserId,
    this.authUser,
    required this.token,
    required this.platform,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) : updatedAt = updatedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  factory PushDevice({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i1.UuidValue authUserId,
    _i3.AuthUser? authUser,
    required String token,
    required _i4.PushPlatform platform,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) = _PushDeviceImpl;

  factory PushDevice.fromJson(Map<String, dynamic> jsonSerialization) {
    return PushDevice(
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
      token: jsonSerialization['token'] as String,
      platform: _i4.PushPlatform.fromJson(
        (jsonSerialization['platform'] as String),
      ),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = PushDeviceTable();

  static const db = PushDeviceRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue householdId;

  /// The household whose warnings this device should receive. Denormalized
  /// onto the device rather than looked up through the membership so the
  /// poller can select recipients in one query.
  _i2.Household? household;

  _i1.UuidValue authUserId;

  /// The user this device registered for. Only used to clean up on sign-out
  /// and to keep one person's tokens attributable; recipients are selected
  /// by household.
  _i3.AuthUser? authUser;

  /// FCM registration token.
  String token;

  _i4.PushPlatform platform;

  /// Set every time the client re-registers. A token that has not been
  /// refreshed in a long time belongs to an app that is gone; FCM will
  /// reject it and `PushSendResult` has it deleted.
  DateTime updatedAt;

  DateTime createdAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [PushDevice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PushDevice copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    _i1.UuidValue? authUserId,
    _i3.AuthUser? authUser,
    String? token,
    _i4.PushPlatform? platform,
    DateTime? updatedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PushDevice',
      if (id != null) 'id': id?.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'token': token,
      'platform': platform.toJson(),
      'updatedAt': updatedAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PushDevice',
      if (id != null) 'id': id?.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJsonForProtocol(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJsonForProtocol(),
      'token': token,
      'platform': platform.toJson(),
      'updatedAt': updatedAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static PushDeviceInclude include({
    _i2.HouseholdInclude? household,
    _i3.AuthUserInclude? authUser,
  }) {
    return PushDeviceInclude._(
      household: household,
      authUser: authUser,
    );
  }

  static PushDeviceIncludeList includeList({
    _i1.WhereExpressionBuilder<PushDeviceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PushDeviceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PushDeviceTable>? orderByList,
    PushDeviceInclude? include,
  }) {
    return PushDeviceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PushDevice.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PushDevice.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PushDeviceImpl extends PushDevice {
  _PushDeviceImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i1.UuidValue authUserId,
    _i3.AuthUser? authUser,
    required String token,
    required _i4.PushPlatform platform,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) : super._(
         id: id,
         householdId: householdId,
         household: household,
         authUserId: authUserId,
         authUser: authUser,
         token: token,
         platform: platform,
         updatedAt: updatedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PushDevice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PushDevice copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? householdId,
    Object? household = _Undefined,
    _i1.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? token,
    _i4.PushPlatform? platform,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return PushDevice(
      id: id is _i1.UuidValue? ? id : this.id,
      householdId: householdId ?? this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _i3.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      token: token ?? this.token,
      platform: platform ?? this.platform,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PushDeviceUpdateTable extends _i1.UpdateTable<PushDeviceTable> {
  PushDeviceUpdateTable(super.table);

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

  _i1.ColumnValue<String, String> token(String value) => _i1.ColumnValue(
    table.token,
    value,
  );

  _i1.ColumnValue<_i4.PushPlatform, _i4.PushPlatform> platform(
    _i4.PushPlatform value,
  ) => _i1.ColumnValue(
    table.platform,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class PushDeviceTable extends _i1.Table<_i1.UuidValue?> {
  PushDeviceTable({super.tableRelation}) : super(tableName: 'push_device') {
    updateTable = PushDeviceUpdateTable(this);
    householdId = _i1.ColumnUuid(
      'householdId',
      this,
    );
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    token = _i1.ColumnString(
      'token',
      this,
    );
    platform = _i1.ColumnEnum(
      'platform',
      this,
      _i1.EnumSerialization.byName,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final PushDeviceUpdateTable updateTable;

  late final _i1.ColumnUuid householdId;

  /// The household whose warnings this device should receive. Denormalized
  /// onto the device rather than looked up through the membership so the
  /// poller can select recipients in one query.
  _i2.HouseholdTable? _household;

  late final _i1.ColumnUuid authUserId;

  /// The user this device registered for. Only used to clean up on sign-out
  /// and to keep one person's tokens attributable; recipients are selected
  /// by household.
  _i3.AuthUserTable? _authUser;

  /// FCM registration token.
  late final _i1.ColumnString token;

  late final _i1.ColumnEnum<_i4.PushPlatform> platform;

  /// Set every time the client re-registers. A token that has not been
  /// refreshed in a long time belongs to an app that is gone; FCM will
  /// reject it and `PushSendResult` has it deleted.
  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnDateTime createdAt;

  _i2.HouseholdTable get household {
    if (_household != null) return _household!;
    _household = _i1.createRelationTable(
      relationFieldName: 'household',
      field: PushDevice.t.householdId,
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
      field: PushDevice.t.authUserId,
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
    token,
    platform,
    updatedAt,
    createdAt,
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

class PushDeviceInclude extends _i1.IncludeObject {
  PushDeviceInclude._({
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
  _i1.Table<_i1.UuidValue?> get table => PushDevice.t;
}

class PushDeviceIncludeList extends _i1.IncludeList {
  PushDeviceIncludeList._({
    _i1.WhereExpressionBuilder<PushDeviceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PushDevice.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => PushDevice.t;
}

class PushDeviceRepository {
  const PushDeviceRepository._();

  final attachRow = const PushDeviceAttachRowRepository._();

  /// Returns a list of [PushDevice]s matching the given query parameters.
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
  Future<List<PushDevice>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PushDeviceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PushDeviceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PushDeviceTable>? orderByList,
    _i1.Transaction? transaction,
    PushDeviceInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PushDevice>(
      where: where?.call(PushDevice.t),
      orderBy: orderBy?.call(PushDevice.t),
      orderByList: orderByList?.call(PushDevice.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PushDevice] matching the given query parameters.
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
  Future<PushDevice?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PushDeviceTable>? where,
    int? offset,
    _i1.OrderByBuilder<PushDeviceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PushDeviceTable>? orderByList,
    _i1.Transaction? transaction,
    PushDeviceInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PushDevice>(
      where: where?.call(PushDevice.t),
      orderBy: orderBy?.call(PushDevice.t),
      orderByList: orderByList?.call(PushDevice.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PushDevice] by its [id] or null if no such row exists.
  Future<PushDevice?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    PushDeviceInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PushDevice>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PushDevice]s in the list and returns the inserted rows.
  ///
  /// The returned [PushDevice]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<PushDevice>> insert(
    _i1.DatabaseSession session,
    List<PushDevice> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<PushDevice>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [PushDevice] and returns the inserted row.
  ///
  /// The returned [PushDevice] will have its `id` field set.
  Future<PushDevice> insertRow(
    _i1.DatabaseSession session,
    PushDevice row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PushDevice>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PushDevice]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PushDevice>> update(
    _i1.DatabaseSession session,
    List<PushDevice> rows, {
    _i1.ColumnSelections<PushDeviceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PushDevice>(
      rows,
      columns: columns?.call(PushDevice.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PushDevice]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PushDevice> updateRow(
    _i1.DatabaseSession session,
    PushDevice row, {
    _i1.ColumnSelections<PushDeviceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PushDevice>(
      row,
      columns: columns?.call(PushDevice.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PushDevice] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PushDevice?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<PushDeviceUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<PushDevice>(
      id,
      columnValues: columnValues(PushDevice.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PushDevice]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<PushDevice>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<PushDeviceUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<PushDeviceTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PushDeviceTable>? orderBy,
    _i1.OrderByListBuilder<PushDeviceTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<PushDevice>(
      columnValues: columnValues(PushDevice.t.updateTable),
      where: where(PushDevice.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PushDevice.t),
      orderByList: orderByList?.call(PushDevice.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [PushDevice]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PushDevice>> delete(
    _i1.DatabaseSession session,
    List<PushDevice> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PushDevice>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PushDevice].
  Future<PushDevice> deleteRow(
    _i1.DatabaseSession session,
    PushDevice row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PushDevice>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PushDevice>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PushDeviceTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PushDevice>(
      where: where(PushDevice.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PushDeviceTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PushDevice>(
      where: where?.call(PushDevice.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PushDevice] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PushDeviceTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PushDevice>(
      where: where(PushDevice.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PushDeviceAttachRowRepository {
  const PushDeviceAttachRowRepository._();

  /// Creates a relation between the given [PushDevice] and [Household]
  /// by setting the [PushDevice]'s foreign key `householdId` to refer to the [Household].
  Future<void> household(
    _i1.DatabaseSession session,
    PushDevice pushDevice,
    _i2.Household household, {
    _i1.Transaction? transaction,
  }) async {
    if (pushDevice.id == null) {
      throw ArgumentError.notNull('pushDevice.id');
    }
    if (household.id == null) {
      throw ArgumentError.notNull('household.id');
    }

    var $pushDevice = pushDevice.copyWith(householdId: household.id);
    await session.db.updateRow<PushDevice>(
      $pushDevice,
      columns: [PushDevice.t.householdId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [PushDevice] and [AuthUser]
  /// by setting the [PushDevice]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _i1.DatabaseSession session,
    PushDevice pushDevice,
    _i3.AuthUser authUser, {
    _i1.Transaction? transaction,
  }) async {
    if (pushDevice.id == null) {
      throw ArgumentError.notNull('pushDevice.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $pushDevice = pushDevice.copyWith(authUserId: authUser.id);
    await session.db.updateRow<PushDevice>(
      $pushDevice,
      columns: [PushDevice.t.authUserId],
      transaction: transaction,
    );
  }
}
