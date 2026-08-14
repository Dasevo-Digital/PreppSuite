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
import '../../households/models/household_exception_reason.dart' as _i2;

/// Thrown when a household operation can not be completed.
///
/// Inspect the [reason] field to understand why.
abstract class HouseholdException
    implements _i1.SerializableException, _i1.SerializableModel {
  HouseholdException._({required this.reason});

  factory HouseholdException({required _i2.HouseholdExceptionReason reason}) =
      _HouseholdExceptionImpl;

  factory HouseholdException.fromJson(Map<String, dynamic> jsonSerialization) {
    return HouseholdException(
      reason: _i2.HouseholdExceptionReason.fromJson(
        (jsonSerialization['reason'] as String),
      ),
    );
  }

  _i2.HouseholdExceptionReason reason;

  /// Returns a shallow copy of this [HouseholdException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  HouseholdException copyWith({_i2.HouseholdExceptionReason? reason});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HouseholdException',
      'reason': reason.toJson(),
    };
  }

  @override
  String toString() {
    return 'HouseholdException(reason: $reason)';
  }
}

class _HouseholdExceptionImpl extends HouseholdException {
  _HouseholdExceptionImpl({required _i2.HouseholdExceptionReason reason})
    : super._(reason: reason);

  /// Returns a shallow copy of this [HouseholdException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  HouseholdException copyWith({_i2.HouseholdExceptionReason? reason}) {
    return HouseholdException(reason: reason ?? this.reason);
  }
}
