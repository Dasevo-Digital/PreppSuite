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

/// A single supply/inventory item belonging to a household. Synced across a
/// household's devices via [InventoryEndpoint]'s push/pull pair using a
/// last-write-wins strategy on [updatedAt].
abstract class InventoryItem implements _i1.SerializableModel {
  InventoryItem._({
    this.id,
    required this.householdId,
    this.household,
    required this.clientId,
    required this.name,
    required this.category,
    this.barcode,
    this.offProductId,
    required this.quantity,
    required this.unit,
    required this.storageLocation,
    this.expirationDate,
    this.minQuantity,
    this.notes,
    DateTime? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory InventoryItem({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i1.UuidValue clientId,
    required String name,
    required _i3.InventoryItemCategory category,
    String? barcode,
    String? offProductId,
    required double quantity,
    required String unit,
    required String storageLocation,
    DateTime? expirationDate,
    double? minQuantity,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _InventoryItemImpl;

  factory InventoryItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return InventoryItem(
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
      clientId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientId'],
      ),
      name: jsonSerialization['name'] as String,
      category: _i3.InventoryItemCategory.fromJson(
        (jsonSerialization['category'] as String),
      ),
      barcode: jsonSerialization['barcode'] as String?,
      offProductId: jsonSerialization['offProductId'] as String?,
      quantity: (jsonSerialization['quantity'] as num).toDouble(),
      unit: jsonSerialization['unit'] as String,
      storageLocation: jsonSerialization['storageLocation'] as String,
      expirationDate: jsonSerialization['expirationDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['expirationDate'],
            ),
      minQuantity: (jsonSerialization['minQuantity'] as num?)?.toDouble(),
      notes: jsonSerialization['notes'] as String?,
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

  _i1.UuidValue householdId;

  /// The household this item belongs to.
  _i2.Household? household;

  /// The id the item was created with on its originating device, before it
  /// had ever been synced. Stable for the lifetime of the item; used to
  /// match retried/offline-created rows to the canonical server row.
  _i1.UuidValue clientId;

  String name;

  _i3.InventoryItemCategory category;

  /// EAN/barcode, if the item was added via barcode scan.
  String? barcode;

  /// Open Food Facts product id, if the item was resolved via that lookup.
  String? offProductId;

  double quantity;

  String unit;

  /// Free-text storage location (e.g. "Keller, Regal 2").
  String storageLocation;

  DateTime? expirationDate;

  /// Below this quantity, the item is flagged as low-stock.
  double? minQuantity;

  String? notes;

  /// Server-stamped on every write; the authority for last-write-wins
  /// conflict resolution and for delta-pull ("updatedAt > since") queries.
  DateTime updatedAt;

  /// Soft-delete tombstone. Never hard-deleted so other devices' pulls can
  /// observe the deletion.
  DateTime? deletedAt;

  /// Returns a shallow copy of this [InventoryItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InventoryItem copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? householdId,
    _i2.Household? household,
    _i1.UuidValue? clientId,
    String? name,
    _i3.InventoryItemCategory? category,
    String? barcode,
    String? offProductId,
    double? quantity,
    String? unit,
    String? storageLocation,
    DateTime? expirationDate,
    double? minQuantity,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InventoryItem',
      if (id != null) 'id': id?.toJson(),
      'householdId': householdId.toJson(),
      if (household != null) 'household': household?.toJson(),
      'clientId': clientId.toJson(),
      'name': name,
      'category': category.toJson(),
      if (barcode != null) 'barcode': barcode,
      if (offProductId != null) 'offProductId': offProductId,
      'quantity': quantity,
      'unit': unit,
      'storageLocation': storageLocation,
      if (expirationDate != null) 'expirationDate': expirationDate?.toJson(),
      if (minQuantity != null) 'minQuantity': minQuantity,
      if (notes != null) 'notes': notes,
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

class _InventoryItemImpl extends InventoryItem {
  _InventoryItemImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue householdId,
    _i2.Household? household,
    required _i1.UuidValue clientId,
    required String name,
    required _i3.InventoryItemCategory category,
    String? barcode,
    String? offProductId,
    required double quantity,
    required String unit,
    required String storageLocation,
    DateTime? expirationDate,
    double? minQuantity,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         householdId: householdId,
         household: household,
         clientId: clientId,
         name: name,
         category: category,
         barcode: barcode,
         offProductId: offProductId,
         quantity: quantity,
         unit: unit,
         storageLocation: storageLocation,
         expirationDate: expirationDate,
         minQuantity: minQuantity,
         notes: notes,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [InventoryItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InventoryItem copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? householdId,
    Object? household = _Undefined,
    _i1.UuidValue? clientId,
    String? name,
    _i3.InventoryItemCategory? category,
    Object? barcode = _Undefined,
    Object? offProductId = _Undefined,
    double? quantity,
    String? unit,
    String? storageLocation,
    Object? expirationDate = _Undefined,
    Object? minQuantity = _Undefined,
    Object? notes = _Undefined,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return InventoryItem(
      id: id is _i1.UuidValue? ? id : this.id,
      householdId: householdId ?? this.householdId,
      household: household is _i2.Household?
          ? household
          : this.household?.copyWith(),
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode is String? ? barcode : this.barcode,
      offProductId: offProductId is String? ? offProductId : this.offProductId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      storageLocation: storageLocation ?? this.storageLocation,
      expirationDate: expirationDate is DateTime?
          ? expirationDate
          : this.expirationDate,
      minQuantity: minQuantity is double? ? minQuantity : this.minQuantity,
      notes: notes is String? ? notes : this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
