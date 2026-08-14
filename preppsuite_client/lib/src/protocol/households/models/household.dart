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

/// A household groups the members who share a supply/checklist/budget plan
/// and defines the region used to scope civil-protection warning feeds.
abstract class Household implements _i1.SerializableModel {
  Household._({
    this.id,
    required this.name,
    required this.countryCode,
    this.regionKey,
    required this.inviteCode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Household({
    _i1.UuidValue? id,
    required String name,
    required String countryCode,
    String? regionKey,
    required String inviteCode,
    DateTime? createdAt,
  }) = _HouseholdImpl;

  factory Household.fromJson(Map<String, dynamic> jsonSerialization) {
    return Household(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      countryCode: jsonSerialization['countryCode'] as String,
      regionKey: jsonSerialization['regionKey'] as String?,
      inviteCode: jsonSerialization['inviteCode'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  /// Display name chosen by the household's creator.
  String name;

  /// ISO 3166-1 alpha-2 country code. Drives which warning feeds apply.
  String countryCode;

  /// Optional German "Amtlicher Regionalschlüssel" for fine-grained BBK
  /// warning scoping. Only meaningful when countryCode is "DE".
  String? regionKey;

  /// Short random token used by other users to join this household.
  String inviteCode;

  /// The time when this household was created.
  DateTime createdAt;

  /// Returns a shallow copy of this [Household]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Household copyWith({
    _i1.UuidValue? id,
    String? name,
    String? countryCode,
    String? regionKey,
    String? inviteCode,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Household',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'countryCode': countryCode,
      if (regionKey != null) 'regionKey': regionKey,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HouseholdImpl extends Household {
  _HouseholdImpl({
    _i1.UuidValue? id,
    required String name,
    required String countryCode,
    String? regionKey,
    required String inviteCode,
    DateTime? createdAt,
  }) : super._(
         id: id,
         name: name,
         countryCode: countryCode,
         regionKey: regionKey,
         inviteCode: inviteCode,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Household]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Household copyWith({
    Object? id = _Undefined,
    String? name,
    String? countryCode,
    Object? regionKey = _Undefined,
    String? inviteCode,
    DateTime? createdAt,
  }) {
    return Household(
      id: id is _i1.UuidValue? ? id : this.id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      regionKey: regionKey is String? ? regionKey : this.regionKey,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
