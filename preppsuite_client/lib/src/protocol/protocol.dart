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
import 'budget/models/budget_entry.dart' as _i2;
import 'checklists/models/checklist_category.dart' as _i3;
import 'checklists/models/checklist_item.dart' as _i4;
import 'checklists/models/checklist_template.dart' as _i5;
import 'households/models/household.dart' as _i6;
import 'households/models/household_exception.dart' as _i7;
import 'households/models/household_exception_reason.dart' as _i8;
import 'households/models/household_member.dart' as _i9;
import 'households/models/household_membership_info.dart' as _i10;
import 'households/models/household_role.dart' as _i11;
import 'inventory/models/inventory_item.dart' as _i12;
import 'inventory/models/inventory_item_category.dart' as _i13;
import 'warnings/models/warning.dart' as _i14;
import 'warnings/models/warning_severity.dart' as _i15;
import 'warnings/models/warning_source.dart' as _i16;
import 'package:preppsuite_client/src/protocol/budget/models/budget_entry.dart'
    as _i17;
import 'package:preppsuite_client/src/protocol/checklists/models/checklist_template.dart'
    as _i18;
import 'package:preppsuite_client/src/protocol/checklists/models/checklist_item.dart'
    as _i19;
import 'package:preppsuite_client/src/protocol/households/models/household_member.dart'
    as _i20;
import 'package:preppsuite_client/src/protocol/inventory/models/inventory_item.dart'
    as _i21;
import 'package:preppsuite_client/src/protocol/warnings/models/warning.dart'
    as _i22;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i23;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i24;
export 'budget/models/budget_entry.dart';
export 'checklists/models/checklist_category.dart';
export 'checklists/models/checklist_item.dart';
export 'checklists/models/checklist_template.dart';
export 'households/models/household.dart';
export 'households/models/household_exception.dart';
export 'households/models/household_exception_reason.dart';
export 'households/models/household_member.dart';
export 'households/models/household_membership_info.dart';
export 'households/models/household_role.dart';
export 'inventory/models/inventory_item.dart';
export 'inventory/models/inventory_item_category.dart';
export 'warnings/models/warning.dart';
export 'warnings/models/warning_severity.dart';
export 'warnings/models/warning_source.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.BudgetEntry) {
      return _i2.BudgetEntry.fromJson(data) as T;
    }
    if (t == _i3.ChecklistCategory) {
      return _i3.ChecklistCategory.fromJson(data) as T;
    }
    if (t == _i4.ChecklistItem) {
      return _i4.ChecklistItem.fromJson(data) as T;
    }
    if (t == _i5.ChecklistTemplate) {
      return _i5.ChecklistTemplate.fromJson(data) as T;
    }
    if (t == _i6.Household) {
      return _i6.Household.fromJson(data) as T;
    }
    if (t == _i7.HouseholdException) {
      return _i7.HouseholdException.fromJson(data) as T;
    }
    if (t == _i8.HouseholdExceptionReason) {
      return _i8.HouseholdExceptionReason.fromJson(data) as T;
    }
    if (t == _i9.HouseholdMember) {
      return _i9.HouseholdMember.fromJson(data) as T;
    }
    if (t == _i10.HouseholdMembershipInfo) {
      return _i10.HouseholdMembershipInfo.fromJson(data) as T;
    }
    if (t == _i11.HouseholdRole) {
      return _i11.HouseholdRole.fromJson(data) as T;
    }
    if (t == _i12.InventoryItem) {
      return _i12.InventoryItem.fromJson(data) as T;
    }
    if (t == _i13.InventoryItemCategory) {
      return _i13.InventoryItemCategory.fromJson(data) as T;
    }
    if (t == _i14.Warning) {
      return _i14.Warning.fromJson(data) as T;
    }
    if (t == _i15.WarningSeverity) {
      return _i15.WarningSeverity.fromJson(data) as T;
    }
    if (t == _i16.WarningSource) {
      return _i16.WarningSource.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.BudgetEntry?>()) {
      return (data != null ? _i2.BudgetEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.ChecklistCategory?>()) {
      return (data != null ? _i3.ChecklistCategory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.ChecklistItem?>()) {
      return (data != null ? _i4.ChecklistItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ChecklistTemplate?>()) {
      return (data != null ? _i5.ChecklistTemplate.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Household?>()) {
      return (data != null ? _i6.Household.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.HouseholdException?>()) {
      return (data != null ? _i7.HouseholdException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.HouseholdExceptionReason?>()) {
      return (data != null ? _i8.HouseholdExceptionReason.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.HouseholdMember?>()) {
      return (data != null ? _i9.HouseholdMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.HouseholdMembershipInfo?>()) {
      return (data != null ? _i10.HouseholdMembershipInfo.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.HouseholdRole?>()) {
      return (data != null ? _i11.HouseholdRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.InventoryItem?>()) {
      return (data != null ? _i12.InventoryItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.InventoryItemCategory?>()) {
      return (data != null ? _i13.InventoryItemCategory.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.Warning?>()) {
      return (data != null ? _i14.Warning.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WarningSeverity?>()) {
      return (data != null ? _i15.WarningSeverity.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.WarningSource?>()) {
      return (data != null ? _i16.WarningSource.fromJson(data) : null) as T;
    }
    if (t == List<_i17.BudgetEntry>) {
      return (data as List)
              .map((e) => deserialize<_i17.BudgetEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i18.ChecklistTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i18.ChecklistTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i19.ChecklistItem>) {
      return (data as List)
              .map((e) => deserialize<_i19.ChecklistItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i20.HouseholdMember>) {
      return (data as List)
              .map((e) => deserialize<_i20.HouseholdMember>(e))
              .toList()
          as T;
    }
    if (t == List<_i21.InventoryItem>) {
      return (data as List)
              .map((e) => deserialize<_i21.InventoryItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i22.Warning>) {
      return (data as List).map((e) => deserialize<_i22.Warning>(e)).toList()
          as T;
    }
    try {
      return _i23.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i24.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.BudgetEntry => 'BudgetEntry',
      _i3.ChecklistCategory => 'ChecklistCategory',
      _i4.ChecklistItem => 'ChecklistItem',
      _i5.ChecklistTemplate => 'ChecklistTemplate',
      _i6.Household => 'Household',
      _i7.HouseholdException => 'HouseholdException',
      _i8.HouseholdExceptionReason => 'HouseholdExceptionReason',
      _i9.HouseholdMember => 'HouseholdMember',
      _i10.HouseholdMembershipInfo => 'HouseholdMembershipInfo',
      _i11.HouseholdRole => 'HouseholdRole',
      _i12.InventoryItem => 'InventoryItem',
      _i13.InventoryItemCategory => 'InventoryItemCategory',
      _i14.Warning => 'Warning',
      _i15.WarningSeverity => 'WarningSeverity',
      _i16.WarningSource => 'WarningSource',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('preppsuite.', '');
    }

    switch (data) {
      case _i2.BudgetEntry():
        return 'BudgetEntry';
      case _i3.ChecklistCategory():
        return 'ChecklistCategory';
      case _i4.ChecklistItem():
        return 'ChecklistItem';
      case _i5.ChecklistTemplate():
        return 'ChecklistTemplate';
      case _i6.Household():
        return 'Household';
      case _i7.HouseholdException():
        return 'HouseholdException';
      case _i8.HouseholdExceptionReason():
        return 'HouseholdExceptionReason';
      case _i9.HouseholdMember():
        return 'HouseholdMember';
      case _i10.HouseholdMembershipInfo():
        return 'HouseholdMembershipInfo';
      case _i11.HouseholdRole():
        return 'HouseholdRole';
      case _i12.InventoryItem():
        return 'InventoryItem';
      case _i13.InventoryItemCategory():
        return 'InventoryItemCategory';
      case _i14.Warning():
        return 'Warning';
      case _i15.WarningSeverity():
        return 'WarningSeverity';
      case _i16.WarningSource():
        return 'WarningSource';
    }
    className = _i23.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i24.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'BudgetEntry') {
      return deserialize<_i2.BudgetEntry>(data['data']);
    }
    if (dataClassName == 'ChecklistCategory') {
      return deserialize<_i3.ChecklistCategory>(data['data']);
    }
    if (dataClassName == 'ChecklistItem') {
      return deserialize<_i4.ChecklistItem>(data['data']);
    }
    if (dataClassName == 'ChecklistTemplate') {
      return deserialize<_i5.ChecklistTemplate>(data['data']);
    }
    if (dataClassName == 'Household') {
      return deserialize<_i6.Household>(data['data']);
    }
    if (dataClassName == 'HouseholdException') {
      return deserialize<_i7.HouseholdException>(data['data']);
    }
    if (dataClassName == 'HouseholdExceptionReason') {
      return deserialize<_i8.HouseholdExceptionReason>(data['data']);
    }
    if (dataClassName == 'HouseholdMember') {
      return deserialize<_i9.HouseholdMember>(data['data']);
    }
    if (dataClassName == 'HouseholdMembershipInfo') {
      return deserialize<_i10.HouseholdMembershipInfo>(data['data']);
    }
    if (dataClassName == 'HouseholdRole') {
      return deserialize<_i11.HouseholdRole>(data['data']);
    }
    if (dataClassName == 'InventoryItem') {
      return deserialize<_i12.InventoryItem>(data['data']);
    }
    if (dataClassName == 'InventoryItemCategory') {
      return deserialize<_i13.InventoryItemCategory>(data['data']);
    }
    if (dataClassName == 'Warning') {
      return deserialize<_i14.Warning>(data['data']);
    }
    if (dataClassName == 'WarningSeverity') {
      return deserialize<_i15.WarningSeverity>(data['data']);
    }
    if (dataClassName == 'WarningSource') {
      return deserialize<_i16.WarningSource>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i23.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i24.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i23.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i24.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
