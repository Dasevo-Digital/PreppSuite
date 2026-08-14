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
import '../../inventory/models/inventory_item_category.dart' as _i3;
import 'package:preppsuite_client/src/protocol/protocol.dart' as _i4;

/// A single budget/spending entry for a household, optionally linked to an
/// inventory item it paid for.
abstract class BudgetEntry implements _i1.SerializableModel {
  BudgetEntry._({
    this.id,
    required this.clientId,
    required this.householdId,
    this.household,
    required this.label,
    required this.amountCents,
    required this.currency,
    required this.category,
    this.purchaseDate,
    this.linkedInventoryItemId,
    DateTime? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory BudgetEntry({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required String label,
    required int amountCents,
    required String currency,
    required _i3.InventoryItemCategory category,
    DateTime? purchaseDate,
    _i1.UuidValue? linkedInventoryItemId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _BudgetEntryImpl;

  factory BudgetEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return BudgetEntry(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      clientId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientId'],
      ),
      householdId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['householdId'],
      ),
      household: jsonSerialization['household'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Household>(
              jsonSerialization['household'],
            ),
      label: jsonSerialization['label'] as String,
      amountCents: jsonSerialization['amountCents'] as int,
      currency: jsonSerialization['currency'] as String,
      category: _i3.InventoryItemCategory.fromJson(
        (jsonSerialization['category'] as String),
      ),
      purchaseDate: jsonSerialization['purchaseDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['purchaseDate'],
            ),
      linkedInventoryItemId: jsonSerialization['linkedInventoryItemId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['linkedInventoryItemId'],
            ),
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

  _i1.UuidValue householdId;

  _i2.Household? household;

  String label;

  /// Stored as integer cents to avoid floating-point money.
  int amountCents;

  /// ISO 4217 currency code.
  String currency;

  _i3.InventoryItemCategory category;

  DateTime? purchaseDate;

  _i1.UuidValue? linkedInventoryItemId;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [BudgetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BudgetEntry copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? clientId,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    String? label,
    int? amountCents,
    String? currency,
    _i3.InventoryItemCategory? category,
    DateTime? purchaseDate,
    _i1.UuidValue? linkedInventoryItemId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BudgetEntry',
      if (id != null) 'id': id?.toJson(),
      'clientId': clientId.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJson(),
      'label': label,
      'amountCents': amountCents,
      'currency': currency,
      'category': category.toJson(),
      if (purchaseDate != null) 'purchaseDate': purchaseDate?.toJson(),
      if (linkedInventoryItemId != null)
        'linkedInventoryItemId': linkedInventoryItemId?.toJson(),
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

class _BudgetEntryImpl extends BudgetEntry {
  _BudgetEntryImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue clientId,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required String label,
    required int amountCents,
    required String currency,
    required _i3.InventoryItemCategory category,
    DateTime? purchaseDate,
    _i1.UuidValue? linkedInventoryItemId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         clientId: clientId,
         householdId: householdId,
         household: household,
         label: label,
         amountCents: amountCents,
         currency: currency,
         category: category,
         purchaseDate: purchaseDate,
         linkedInventoryItemId: linkedInventoryItemId,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [BudgetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BudgetEntry copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? clientId,
    _i1.UuidValue? householdId,
    Object? household = _Undefined,
    String? label,
    int? amountCents,
    String? currency,
    _i3.InventoryItemCategory? category,
    Object? purchaseDate = _Undefined,
    Object? linkedInventoryItemId = _Undefined,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return BudgetEntry(
      id: id is _i1.UuidValue? ? id : this.id,
      clientId: clientId ?? this.clientId,
      householdId: householdId ?? this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      label: label ?? this.label,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      purchaseDate: purchaseDate is DateTime?
          ? purchaseDate
          : this.purchaseDate,
      linkedInventoryItemId: linkedInventoryItemId is _i1.UuidValue?
          ? linkedInventoryItemId
          : this.linkedInventoryItemId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
