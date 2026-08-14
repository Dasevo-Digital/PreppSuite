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
import 'package:serverpod/serverpod.dart' as _i1;
import '../../households/models/household.dart' as _i2;
import '../../households/models/household_member.dart' as _i3;
import 'package:preppsuite_server/src/generated/protocol.dart' as _i4;

/// Combines a household with the caller's own membership row, returned by
/// [HouseholdEndpoint.getMyHousehold] so the client can complete onboarding
/// without a second round-trip.
abstract class HouseholdMembershipInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  HouseholdMembershipInfo._({
    required this.household,
    required this.member,
  });

  factory HouseholdMembershipInfo({
    required _i2.Household household,
    required _i3.HouseholdMember member,
  }) = _HouseholdMembershipInfoImpl;

  factory HouseholdMembershipInfo.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return HouseholdMembershipInfo(
      household: _i4.Protocol().deserialize<_i2.Household>(
        jsonSerialization['household'],
      ),
      member: _i4.Protocol().deserialize<_i3.HouseholdMember>(
        jsonSerialization['member'],
      ),
    );
  }

  _i2.Household household;

  _i3.HouseholdMember member;

  /// Returns a shallow copy of this [HouseholdMembershipInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  HouseholdMembershipInfo copyWith({
    _i2.Household? household,
    _i3.HouseholdMember? member,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HouseholdMembershipInfo',
      'household': household.toJson(),
      'member': member.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'HouseholdMembershipInfo',
      'household': household.toJsonForProtocol(),
      'member': member.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _HouseholdMembershipInfoImpl extends HouseholdMembershipInfo {
  _HouseholdMembershipInfoImpl({
    required _i2.Household household,
    required _i3.HouseholdMember member,
  }) : super._(
         household: household,
         member: member,
       );

  /// Returns a shallow copy of this [HouseholdMembershipInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  HouseholdMembershipInfo copyWith({
    _i2.Household? household,
    _i3.HouseholdMember? member,
  }) {
    return HouseholdMembershipInfo(
      household: household ?? this.household.copyWith(),
      member: member ?? this.member.copyWith(),
    );
  }
}
