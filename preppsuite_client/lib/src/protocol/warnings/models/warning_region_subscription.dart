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
import '../../warnings/models/warning_region_kind.dart' as _i3;
import 'package:preppsuite_client/src/protocol/protocol.dart' as _i4;

/// An additional region (beyond a household's own `regionKey`) whose
/// warnings a household wants to see — e.g. a neighboring Kreis, or an
/// entire Bundesland. Purely additive: removing all of a household's
/// subscriptions doesn't affect its own `regionKey`-based relevance.
abstract class WarningRegionSubscription implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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
