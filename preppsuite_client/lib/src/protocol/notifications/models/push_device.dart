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
import '../../notifications/models/push_platform.dart' as _i4;
import 'package:preppsuite_client/src/protocol/protocol.dart' as _i5;

/// One device that has opted in to warning push notifications.
///
/// Keyed by the FCM registration token, which is the device's identity as
/// far as the push service is concerned. The token is not stable: it
/// rotates on reinstall, on restore-to-a-new-phone, and occasionally on
/// its own, so the client re-registers on every launch and the token — not
/// the user, not the household — carries the uniqueness constraint. A
/// token that reappears under a different account therefore moves rather
/// than duplicating (see `PushDeviceService.register`).
abstract class PushDevice implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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
