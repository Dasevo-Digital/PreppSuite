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
import '../../checklists/models/checklist_category.dart' as _i3;
import 'package:preppsuite_client/src/protocol/protocol.dart' as _i4;

/// A checklist a household works through (e.g. "Wasser", "Erste-Hilfe").
///
/// [household] is null for built-in templates shared read-only across all
/// households (seeded once at server startup, see `ChecklistSeeder`).
/// A household that wants to customize a built-in copies it client-side
/// into its own template (copy-on-customize) rather than editing the
/// shared original.
abstract class ChecklistTemplate implements _i1.SerializableModel {
  ChecklistTemplate._({
    this.id,
    required this.clientId,
    this.householdId,
    this.household,
    required this.title,
    required this.category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    this.deletedAt,
  }) : isBuiltIn = isBuiltIn ?? false,
       updatedAt = updatedAt ?? DateTime.now();

  factory ChecklistTemplate({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    required String title,
    required _i3.ChecklistCategory category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _ChecklistTemplateImpl;

  factory ChecklistTemplate.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChecklistTemplate(
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
      title: jsonSerialization['title'] as String,
      category: _i3.ChecklistCategory.fromJson(
        (jsonSerialization['category'] as String),
      ),
      isBuiltIn: jsonSerialization['isBuiltIn'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isBuiltIn']),
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

  /// The id the template was created with on its originating device, before
  /// it had ever been synced.
  _i1.UuidValue clientId;

  _i1.UuidValue? householdId;

  /// Null for built-in, shared templates.
  _i2.Household? household;

  String title;

  _i3.ChecklistCategory category;

  bool isBuiltIn;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [ChecklistTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChecklistTemplate copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    String? title,
    _i3.ChecklistCategory? category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChecklistTemplate',
      if (id != null) 'id': id?.toJson(),
      'clientId': clientId.toJson(),
      if (householdId != null) 'householdId': householdId?.toJson(),
      if (household != null) 'household': household?.toJson(),
      'title': title,
      'category': category.toJson(),
      'isBuiltIn': isBuiltIn,
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

class _ChecklistTemplateImpl extends ChecklistTemplate {
  _ChecklistTemplateImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    required String title,
    required _i3.ChecklistCategory category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         clientId: clientId,
         householdId: householdId,
         household: household,
         title: title,
         category: category,
         isBuiltIn: isBuiltIn,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [ChecklistTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChecklistTemplate copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? clientId,
    Object? householdId = _Undefined,
    Object? household = _Undefined,
    String? title,
    _i3.ChecklistCategory? category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return ChecklistTemplate(
      id: id is _i1.UuidValue? ? id : this.id,
      clientId: clientId ?? this.clientId,
      householdId: householdId is _i1.UuidValue?
          ? householdId
          : this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      title: title ?? this.title,
      category: category ?? this.category,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
