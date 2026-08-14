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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import '../../households/models/household.dart' as _i2;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i3;
import '../../households/models/household_role.dart' as _i4;
import 'package:preppsuite_client/src/protocol/protocol.dart' as _i5;

/// Links an authenticated user to a household they belong to.
abstract class HouseholdMember implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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
