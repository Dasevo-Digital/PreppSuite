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
import '../../checklists/models/checklist_template.dart' as _i3;
import 'package:preppsuite_client/src/protocol/protocol.dart' as _i4;

/// A single line item within a [ChecklistTemplate]. [household] mirrors
/// its template's household (null for built-in template items) so item
/// sync/authorization doesn't require joining through the template.
abstract class ChecklistItem implements _i1.SerializableModel {
  ChecklistItem._({
    this.id,
    required this.clientId,
    this.householdId,
    this.household,
    required this.templateId,
    this.template,
    required this.title,
    this.targetQuantity,
    bool? isChecked,
    this.linkedInventoryItemId,
    int? sortOrder,
    DateTime? updatedAt,
    this.deletedAt,
  }) : isChecked = isChecked ?? false,
       sortOrder = sortOrder ?? 0,
       updatedAt = updatedAt ?? DateTime.now();

  factory ChecklistItem({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    required _i1.UuidValue templateId,
    _i3.ChecklistTemplate? template,
    required String title,
    double? targetQuantity,
    bool? isChecked,
    _i1.UuidValue? linkedInventoryItemId,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _ChecklistItemImpl;

  factory ChecklistItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChecklistItem(
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
      templateId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['templateId'],
      ),
      template: jsonSerialization['template'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.ChecklistTemplate>(
              jsonSerialization['template'],
            ),
      title: jsonSerialization['title'] as String,
      targetQuantity: (jsonSerialization['targetQuantity'] as num?)?.toDouble(),
      isChecked: jsonSerialization['isChecked'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isChecked']),
      linkedInventoryItemId: jsonSerialization['linkedInventoryItemId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['linkedInventoryItemId'],
            ),
      sortOrder: jsonSerialization['sortOrder'] as int?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i1.UuidValue clientId;

  _i1.UuidValue? householdId;

  _i2.Household? household;

  _i1.UuidValue templateId;

  _i3.ChecklistTemplate? template;

  String title;

  double? targetQuantity;

  bool isChecked;

  /// Optional, manual-only in v1: a future phase may use this to derive
  /// completion from live inventory stock instead.
  _i1.UuidValue? linkedInventoryItemId;

  int sortOrder;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [ChecklistItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChecklistItem copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    _i1.UuidValue? templateId,
    _i3.ChecklistTemplate? template,
    String? title,
    double? targetQuantity,
    bool? isChecked,
    _i1.UuidValue? linkedInventoryItemId,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChecklistItem',
      if (id != null) 'id': id?.toJson(),
      'clientId': clientId.toJson(),
      if (householdId != null) 'householdId': householdId?.toJson(),
      if (household != null) 'household': household?.toJson(),
      'templateId': templateId.toJson(),
      if (template != null) 'template': template?.toJson(),
      'title': title,
      if (targetQuantity != null) 'targetQuantity': targetQuantity,
      'isChecked': isChecked,
      if (linkedInventoryItemId != null)
        'linkedInventoryItemId': linkedInventoryItemId?.toJson(),
      'sortOrder': sortOrder,
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChecklistItemImpl extends ChecklistItem {
  _ChecklistItemImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    required _i1.UuidValue templateId,
    _i3.ChecklistTemplate? template,
    required String title,
    double? targetQuantity,
    bool? isChecked,
    _i1.UuidValue? linkedInventoryItemId,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         clientId: clientId,
         householdId: householdId,
         household: household,
         templateId: templateId,
         template: template,
         title: title,
         targetQuantity: targetQuantity,
         isChecked: isChecked,
         linkedInventoryItemId: linkedInventoryItemId,
         sortOrder: sortOrder,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [ChecklistItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChecklistItem copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? clientId,
    Object? householdId = _Undefined,
    Object? household = _Undefined,
    _i1.UuidValue? templateId,
    Object? template = _Undefined,
    String? title,
    Object? targetQuantity = _Undefined,
    bool? isChecked,
    Object? linkedInventoryItemId = _Undefined,
    int? sortOrder,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return ChecklistItem(
      id: id is _i1.UuidValue? ? id : this.id,
      clientId: clientId ?? this.clientId,
      householdId: householdId is _i1.UuidValue?
          ? householdId
          : this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      templateId: templateId ?? this.templateId,
      template: template is _i3.ChecklistTemplate?
          ? template
          : this.template?.copyWith(),
      title: title ?? this.title,
      targetQuantity: targetQuantity is double?
          ? targetQuantity
          : this.targetQuantity,
      isChecked: isChecked ?? this.isChecked,
      linkedInventoryItemId: linkedInventoryItemId is _i1.UuidValue?
          ? linkedInventoryItemId
          : this.linkedInventoryItemId,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
