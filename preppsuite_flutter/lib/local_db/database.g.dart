// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offProductIdMeta = const VerificationMeta(
    'offProductId',
  );
  @override
  late final GeneratedColumn<String> offProductId = GeneratedColumn<String>(
    'off_product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageLocationMeta = const VerificationMeta(
    'storageLocation',
  );
  @override
  late final GeneratedColumn<String> storageLocation = GeneratedColumn<String>(
    'storage_location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expirationDateMeta = const VerificationMeta(
    'expirationDate',
  );
  @override
  late final GeneratedColumn<DateTime> expirationDate =
      GeneratedColumn<DateTime>(
        'expiration_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _minQuantityMeta = const VerificationMeta(
    'minQuantity',
  );
  @override
  late final GeneratedColumn<double> minQuantity = GeneratedColumn<double>(
    'min_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGramsMeta = const VerificationMeta(
    'proteinGrams',
  );
  @override
  late final GeneratedColumn<double> proteinGrams = GeneratedColumn<double>(
    'protein_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbohydrateGramsMeta = const VerificationMeta(
    'carbohydrateGrams',
  );
  @override
  late final GeneratedColumn<double> carbohydrateGrams =
      GeneratedColumn<double>(
        'carbohydrate_grams',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fatGramsMeta = const VerificationMeta(
    'fatGrams',
  );
  @override
  late final GeneratedColumn<double> fatGrams = GeneratedColumn<double>(
    'fat_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiberGramsMeta = const VerificationMeta(
    'fiberGrams',
  );
  @override
  late final GeneratedColumn<double> fiberGrams = GeneratedColumn<double>(
    'fiber_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    householdId,
    name,
    category,
    barcode,
    offProductId,
    quantity,
    unit,
    storageLocation,
    expirationDate,
    minQuantity,
    calories,
    proteinGrams,
    carbohydrateGrams,
    fatGrams,
    fiberGrams,
    notes,
    photoPath,
    updatedAt,
    deletedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('off_product_id')) {
      context.handle(
        _offProductIdMeta,
        offProductId.isAcceptableOrUnknown(
          data['off_product_id']!,
          _offProductIdMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('storage_location')) {
      context.handle(
        _storageLocationMeta,
        storageLocation.isAcceptableOrUnknown(
          data['storage_location']!,
          _storageLocationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storageLocationMeta);
    }
    if (data.containsKey('expiration_date')) {
      context.handle(
        _expirationDateMeta,
        expirationDate.isAcceptableOrUnknown(
          data['expiration_date']!,
          _expirationDateMeta,
        ),
      );
    }
    if (data.containsKey('min_quantity')) {
      context.handle(
        _minQuantityMeta,
        minQuantity.isAcceptableOrUnknown(
          data['min_quantity']!,
          _minQuantityMeta,
        ),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('protein_grams')) {
      context.handle(
        _proteinGramsMeta,
        proteinGrams.isAcceptableOrUnknown(
          data['protein_grams']!,
          _proteinGramsMeta,
        ),
      );
    }
    if (data.containsKey('carbohydrate_grams')) {
      context.handle(
        _carbohydrateGramsMeta,
        carbohydrateGrams.isAcceptableOrUnknown(
          data['carbohydrate_grams']!,
          _carbohydrateGramsMeta,
        ),
      );
    }
    if (data.containsKey('fat_grams')) {
      context.handle(
        _fatGramsMeta,
        fatGrams.isAcceptableOrUnknown(data['fat_grams']!, _fatGramsMeta),
      );
    }
    if (data.containsKey('fiber_grams')) {
      context.handle(
        _fiberGramsMeta,
        fiberGrams.isAcceptableOrUnknown(data['fiber_grams']!, _fiberGramsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  InventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItem(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      offProductId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}off_product_id'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      storageLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_location'],
      )!,
      expirationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiration_date'],
      ),
      minQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_quantity'],
      ),
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      ),
      proteinGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_grams'],
      ),
      carbohydrateGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbohydrate_grams'],
      ),
      fatGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_grams'],
      ),
      fiberGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_grams'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItem extends DataClass implements Insertable<InventoryItem> {
  final String clientId;
  final String householdId;
  final String name;

  /// Stores an `InventoryItemCategory` enum name (see
  /// `lib/model/categories.dart`) as plain text — which is why renaming a
  /// value there silently orphans existing rows.
  final String category;
  final String? barcode;
  final String? offProductId;
  final double quantity;
  final String unit;
  final String storageLocation;
  final DateTime? expirationDate;
  final double? minQuantity;

  /// Total kcal for the item's current [quantity] (not per-unit) — only
  /// meaningful for `category: food`. Powers the "Vorräte für X Tage"
  /// supply calculator (`supply_calculator.dart`).
  final int? calories;

  /// Macronutrients for the item's current [quantity], in grams — the
  /// same "whole item, not per 100 g" convention as [calories], for the
  /// same reason: a shelf is then a sum. Filled in from the barcode (see
  /// `open_food_facts_service.dart`) or by hand, and null wherever the
  /// label does not say, which is most non-food supplies.
  final double? proteinGrams;
  final double? carbohydrateGrams;
  final double? fatGrams;
  final double? fiberGrams;
  final String? notes;

  /// Path to a locally-stored photo of the item (see
  /// `inventory_photo_service.dart`), relative to the app's documents
  /// directory. Device-local and deliberately never shared: the path means
  /// nothing on another device, and the picture itself is not in the
  /// folder. The shared-folder merge leaves this column alone.
  final String? photoPath;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const InventoryItem({
    required this.clientId,
    required this.householdId,
    required this.name,
    required this.category,
    this.barcode,
    this.offProductId,
    required this.quantity,
    required this.unit,
    required this.storageLocation,
    this.expirationDate,
    this.minQuantity,
    this.calories,
    this.proteinGrams,
    this.carbohydrateGrams,
    this.fatGrams,
    this.fiberGrams,
    this.notes,
    this.photoPath,
    required this.updatedAt,
    this.deletedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || offProductId != null) {
      map['off_product_id'] = Variable<String>(offProductId);
    }
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['storage_location'] = Variable<String>(storageLocation);
    if (!nullToAbsent || expirationDate != null) {
      map['expiration_date'] = Variable<DateTime>(expirationDate);
    }
    if (!nullToAbsent || minQuantity != null) {
      map['min_quantity'] = Variable<double>(minQuantity);
    }
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<int>(calories);
    }
    if (!nullToAbsent || proteinGrams != null) {
      map['protein_grams'] = Variable<double>(proteinGrams);
    }
    if (!nullToAbsent || carbohydrateGrams != null) {
      map['carbohydrate_grams'] = Variable<double>(carbohydrateGrams);
    }
    if (!nullToAbsent || fatGrams != null) {
      map['fat_grams'] = Variable<double>(fatGrams);
    }
    if (!nullToAbsent || fiberGrams != null) {
      map['fiber_grams'] = Variable<double>(fiberGrams);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      clientId: Value(clientId),
      householdId: Value(householdId),
      name: Value(name),
      category: Value(category),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      offProductId: offProductId == null && nullToAbsent
          ? const Value.absent()
          : Value(offProductId),
      quantity: Value(quantity),
      unit: Value(unit),
      storageLocation: Value(storageLocation),
      expirationDate: expirationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expirationDate),
      minQuantity: minQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(minQuantity),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      proteinGrams: proteinGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinGrams),
      carbohydrateGrams: carbohydrateGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(carbohydrateGrams),
      fatGrams: fatGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(fatGrams),
      fiberGrams: fiberGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberGrams),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory InventoryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItem(
      clientId: serializer.fromJson<String>(json['clientId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      offProductId: serializer.fromJson<String?>(json['offProductId']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      storageLocation: serializer.fromJson<String>(json['storageLocation']),
      expirationDate: serializer.fromJson<DateTime?>(json['expirationDate']),
      minQuantity: serializer.fromJson<double?>(json['minQuantity']),
      calories: serializer.fromJson<int?>(json['calories']),
      proteinGrams: serializer.fromJson<double?>(json['proteinGrams']),
      carbohydrateGrams: serializer.fromJson<double?>(
        json['carbohydrateGrams'],
      ),
      fatGrams: serializer.fromJson<double?>(json['fatGrams']),
      fiberGrams: serializer.fromJson<double?>(json['fiberGrams']),
      notes: serializer.fromJson<String?>(json['notes']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'barcode': serializer.toJson<String?>(barcode),
      'offProductId': serializer.toJson<String?>(offProductId),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'storageLocation': serializer.toJson<String>(storageLocation),
      'expirationDate': serializer.toJson<DateTime?>(expirationDate),
      'minQuantity': serializer.toJson<double?>(minQuantity),
      'calories': serializer.toJson<int?>(calories),
      'proteinGrams': serializer.toJson<double?>(proteinGrams),
      'carbohydrateGrams': serializer.toJson<double?>(carbohydrateGrams),
      'fatGrams': serializer.toJson<double?>(fatGrams),
      'fiberGrams': serializer.toJson<double?>(fiberGrams),
      'notes': serializer.toJson<String?>(notes),
      'photoPath': serializer.toJson<String?>(photoPath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  InventoryItem copyWith({
    String? clientId,
    String? householdId,
    String? name,
    String? category,
    Value<String?> barcode = const Value.absent(),
    Value<String?> offProductId = const Value.absent(),
    double? quantity,
    String? unit,
    String? storageLocation,
    Value<DateTime?> expirationDate = const Value.absent(),
    Value<double?> minQuantity = const Value.absent(),
    Value<int?> calories = const Value.absent(),
    Value<double?> proteinGrams = const Value.absent(),
    Value<double?> carbohydrateGrams = const Value.absent(),
    Value<double?> fatGrams = const Value.absent(),
    Value<double?> fiberGrams = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? dirty,
  }) => InventoryItem(
    clientId: clientId ?? this.clientId,
    householdId: householdId ?? this.householdId,
    name: name ?? this.name,
    category: category ?? this.category,
    barcode: barcode.present ? barcode.value : this.barcode,
    offProductId: offProductId.present ? offProductId.value : this.offProductId,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    storageLocation: storageLocation ?? this.storageLocation,
    expirationDate: expirationDate.present
        ? expirationDate.value
        : this.expirationDate,
    minQuantity: minQuantity.present ? minQuantity.value : this.minQuantity,
    calories: calories.present ? calories.value : this.calories,
    proteinGrams: proteinGrams.present ? proteinGrams.value : this.proteinGrams,
    carbohydrateGrams: carbohydrateGrams.present
        ? carbohydrateGrams.value
        : this.carbohydrateGrams,
    fatGrams: fatGrams.present ? fatGrams.value : this.fatGrams,
    fiberGrams: fiberGrams.present ? fiberGrams.value : this.fiberGrams,
    notes: notes.present ? notes.value : this.notes,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    dirty: dirty ?? this.dirty,
  );
  InventoryItem copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItem(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      offProductId: data.offProductId.present
          ? data.offProductId.value
          : this.offProductId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      storageLocation: data.storageLocation.present
          ? data.storageLocation.value
          : this.storageLocation,
      expirationDate: data.expirationDate.present
          ? data.expirationDate.value
          : this.expirationDate,
      minQuantity: data.minQuantity.present
          ? data.minQuantity.value
          : this.minQuantity,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinGrams: data.proteinGrams.present
          ? data.proteinGrams.value
          : this.proteinGrams,
      carbohydrateGrams: data.carbohydrateGrams.present
          ? data.carbohydrateGrams.value
          : this.carbohydrateGrams,
      fatGrams: data.fatGrams.present ? data.fatGrams.value : this.fatGrams,
      fiberGrams: data.fiberGrams.present
          ? data.fiberGrams.value
          : this.fiberGrams,
      notes: data.notes.present ? data.notes.value : this.notes,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItem(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('barcode: $barcode, ')
          ..write('offProductId: $offProductId, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('expirationDate: $expirationDate, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('calories: $calories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbohydrateGrams: $carbohydrateGrams, ')
          ..write('fatGrams: $fatGrams, ')
          ..write('fiberGrams: $fiberGrams, ')
          ..write('notes: $notes, ')
          ..write('photoPath: $photoPath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    clientId,
    householdId,
    name,
    category,
    barcode,
    offProductId,
    quantity,
    unit,
    storageLocation,
    expirationDate,
    minQuantity,
    calories,
    proteinGrams,
    carbohydrateGrams,
    fatGrams,
    fiberGrams,
    notes,
    photoPath,
    updatedAt,
    deletedAt,
    dirty,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItem &&
          other.clientId == this.clientId &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.category == this.category &&
          other.barcode == this.barcode &&
          other.offProductId == this.offProductId &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.storageLocation == this.storageLocation &&
          other.expirationDate == this.expirationDate &&
          other.minQuantity == this.minQuantity &&
          other.calories == this.calories &&
          other.proteinGrams == this.proteinGrams &&
          other.carbohydrateGrams == this.carbohydrateGrams &&
          other.fatGrams == this.fatGrams &&
          other.fiberGrams == this.fiberGrams &&
          other.notes == this.notes &&
          other.photoPath == this.photoPath &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItem> {
  final Value<String> clientId;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String> category;
  final Value<String?> barcode;
  final Value<String?> offProductId;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<String> storageLocation;
  final Value<DateTime?> expirationDate;
  final Value<double?> minQuantity;
  final Value<int?> calories;
  final Value<double?> proteinGrams;
  final Value<double?> carbohydrateGrams;
  final Value<double?> fatGrams;
  final Value<double?> fiberGrams;
  final Value<String?> notes;
  final Value<String?> photoPath;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const InventoryItemsCompanion({
    this.clientId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.barcode = const Value.absent(),
    this.offProductId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.storageLocation = const Value.absent(),
    this.expirationDate = const Value.absent(),
    this.minQuantity = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinGrams = const Value.absent(),
    this.carbohydrateGrams = const Value.absent(),
    this.fatGrams = const Value.absent(),
    this.fiberGrams = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    required String clientId,
    required String householdId,
    required String name,
    required String category,
    this.barcode = const Value.absent(),
    this.offProductId = const Value.absent(),
    required double quantity,
    required String unit,
    required String storageLocation,
    this.expirationDate = const Value.absent(),
    this.minQuantity = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinGrams = const Value.absent(),
    this.carbohydrateGrams = const Value.absent(),
    this.fatGrams = const Value.absent(),
    this.fiberGrams = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoPath = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       householdId = Value(householdId),
       name = Value(name),
       category = Value(category),
       quantity = Value(quantity),
       unit = Value(unit),
       storageLocation = Value(storageLocation),
       updatedAt = Value(updatedAt);
  static Insertable<InventoryItem> custom({
    Expression<String>? clientId,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? barcode,
    Expression<String>? offProductId,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? storageLocation,
    Expression<DateTime>? expirationDate,
    Expression<double>? minQuantity,
    Expression<int>? calories,
    Expression<double>? proteinGrams,
    Expression<double>? carbohydrateGrams,
    Expression<double>? fatGrams,
    Expression<double>? fiberGrams,
    Expression<String>? notes,
    Expression<String>? photoPath,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (barcode != null) 'barcode': barcode,
      if (offProductId != null) 'off_product_id': offProductId,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (storageLocation != null) 'storage_location': storageLocation,
      if (expirationDate != null) 'expiration_date': expirationDate,
      if (minQuantity != null) 'min_quantity': minQuantity,
      if (calories != null) 'calories': calories,
      if (proteinGrams != null) 'protein_grams': proteinGrams,
      if (carbohydrateGrams != null) 'carbohydrate_grams': carbohydrateGrams,
      if (fatGrams != null) 'fat_grams': fatGrams,
      if (fiberGrams != null) 'fiber_grams': fiberGrams,
      if (notes != null) 'notes': notes,
      if (photoPath != null) 'photo_path': photoPath,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryItemsCompanion copyWith({
    Value<String>? clientId,
    Value<String>? householdId,
    Value<String>? name,
    Value<String>? category,
    Value<String?>? barcode,
    Value<String?>? offProductId,
    Value<double>? quantity,
    Value<String>? unit,
    Value<String>? storageLocation,
    Value<DateTime?>? expirationDate,
    Value<double?>? minQuantity,
    Value<int?>? calories,
    Value<double?>? proteinGrams,
    Value<double?>? carbohydrateGrams,
    Value<double?>? fatGrams,
    Value<double?>? fiberGrams,
    Value<String?>? notes,
    Value<String?>? photoPath,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return InventoryItemsCompanion(
      clientId: clientId ?? this.clientId,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      offProductId: offProductId ?? this.offProductId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      storageLocation: storageLocation ?? this.storageLocation,
      expirationDate: expirationDate ?? this.expirationDate,
      minQuantity: minQuantity ?? this.minQuantity,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbohydrateGrams: carbohydrateGrams ?? this.carbohydrateGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (offProductId.present) {
      map['off_product_id'] = Variable<String>(offProductId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (storageLocation.present) {
      map['storage_location'] = Variable<String>(storageLocation.value);
    }
    if (expirationDate.present) {
      map['expiration_date'] = Variable<DateTime>(expirationDate.value);
    }
    if (minQuantity.present) {
      map['min_quantity'] = Variable<double>(minQuantity.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (proteinGrams.present) {
      map['protein_grams'] = Variable<double>(proteinGrams.value);
    }
    if (carbohydrateGrams.present) {
      map['carbohydrate_grams'] = Variable<double>(carbohydrateGrams.value);
    }
    if (fatGrams.present) {
      map['fat_grams'] = Variable<double>(fatGrams.value);
    }
    if (fiberGrams.present) {
      map['fiber_grams'] = Variable<double>(fiberGrams.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('barcode: $barcode, ')
          ..write('offProductId: $offProductId, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('expirationDate: $expirationDate, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('calories: $calories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbohydrateGrams: $carbohydrateGrams, ')
          ..write('fatGrams: $fatGrams, ')
          ..write('fiberGrams: $fiberGrams, ')
          ..write('notes: $notes, ')
          ..write('photoPath: $photoPath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistTemplatesTable extends ChecklistTemplates
    with TableInfo<$ChecklistTemplatesTable, ChecklistTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    householdId,
    title,
    category,
    isBuiltIn,
    updatedAt,
    deletedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  ChecklistTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistTemplate(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $ChecklistTemplatesTable createAlias(String alias) {
    return $ChecklistTemplatesTable(attachedDatabase, alias);
  }
}

class ChecklistTemplate extends DataClass
    implements Insertable<ChecklistTemplate> {
  final String clientId;
  final String? householdId;
  final String title;

  /// Stores a `ChecklistCategory` enum name (see
  /// `lib/model/categories.dart`) as plain text.
  final String category;
  final bool isBuiltIn;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const ChecklistTemplate({
    required this.clientId,
    this.householdId,
    required this.title,
    required this.category,
    required this.isBuiltIn,
    required this.updatedAt,
    this.deletedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ChecklistTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ChecklistTemplatesCompanion(
      clientId: Value(clientId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      title: Value(title),
      category: Value(category),
      isBuiltIn: Value(isBuiltIn),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory ChecklistTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistTemplate(
      clientId: serializer.fromJson<String>(json['clientId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'householdId': serializer.toJson<String?>(householdId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  ChecklistTemplate copyWith({
    String? clientId,
    Value<String?> householdId = const Value.absent(),
    String? title,
    String? category,
    bool? isBuiltIn,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? dirty,
  }) => ChecklistTemplate(
    clientId: clientId ?? this.clientId,
    householdId: householdId.present ? householdId.value : this.householdId,
    title: title ?? this.title,
    category: category ?? this.category,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    dirty: dirty ?? this.dirty,
  );
  ChecklistTemplate copyWithCompanion(ChecklistTemplatesCompanion data) {
    return ChecklistTemplate(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistTemplate(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    householdId,
    title,
    category,
    isBuiltIn,
    updatedAt,
    deletedAt,
    dirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistTemplate &&
          other.clientId == this.clientId &&
          other.householdId == this.householdId &&
          other.title == this.title &&
          other.category == this.category &&
          other.isBuiltIn == this.isBuiltIn &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class ChecklistTemplatesCompanion extends UpdateCompanion<ChecklistTemplate> {
  final Value<String> clientId;
  final Value<String?> householdId;
  final Value<String> title;
  final Value<String> category;
  final Value<bool> isBuiltIn;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const ChecklistTemplatesCompanion({
    this.clientId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistTemplatesCompanion.insert({
    required String clientId,
    this.householdId = const Value.absent(),
    required String title,
    required String category,
    this.isBuiltIn = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       title = Value(title),
       category = Value(category),
       updatedAt = Value(updatedAt);
  static Insertable<ChecklistTemplate> custom({
    Expression<String>? clientId,
    Expression<String>? householdId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<bool>? isBuiltIn,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (householdId != null) 'household_id': householdId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistTemplatesCompanion copyWith({
    Value<String>? clientId,
    Value<String?>? householdId,
    Value<String>? title,
    Value<String>? category,
    Value<bool>? isBuiltIn,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return ChecklistTemplatesCompanion(
      clientId: clientId ?? this.clientId,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      category: category ?? this.category,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistTemplatesCompanion(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistItemsTable extends ChecklistItems
    with TableInfo<$ChecklistItemsTable, ChecklistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateClientIdMeta = const VerificationMeta(
    'templateClientId',
  );
  @override
  late final GeneratedColumn<String> templateClientId = GeneratedColumn<String>(
    'template_client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetQuantityMeta = const VerificationMeta(
    'targetQuantity',
  );
  @override
  late final GeneratedColumn<double> targetQuantity = GeneratedColumn<double>(
    'target_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCheckedMeta = const VerificationMeta(
    'isChecked',
  );
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
    'is_checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _linkedInventoryItemIdMeta =
      const VerificationMeta('linkedInventoryItemId');
  @override
  late final GeneratedColumn<String> linkedInventoryItemId =
      GeneratedColumn<String>(
        'linked_inventory_item_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    householdId,
    templateClientId,
    title,
    targetQuantity,
    isChecked,
    linkedInventoryItemId,
    sortOrder,
    updatedAt,
    deletedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    }
    if (data.containsKey('template_client_id')) {
      context.handle(
        _templateClientIdMeta,
        templateClientId.isAcceptableOrUnknown(
          data['template_client_id']!,
          _templateClientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateClientIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_quantity')) {
      context.handle(
        _targetQuantityMeta,
        targetQuantity.isAcceptableOrUnknown(
          data['target_quantity']!,
          _targetQuantityMeta,
        ),
      );
    }
    if (data.containsKey('is_checked')) {
      context.handle(
        _isCheckedMeta,
        isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta),
      );
    }
    if (data.containsKey('linked_inventory_item_id')) {
      context.handle(
        _linkedInventoryItemIdMeta,
        linkedInventoryItemId.isAcceptableOrUnknown(
          data['linked_inventory_item_id']!,
          _linkedInventoryItemIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  ChecklistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItem(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      ),
      templateClientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_client_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_quantity'],
      ),
      isChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_checked'],
      )!,
      linkedInventoryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_inventory_item_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $ChecklistItemsTable createAlias(String alias) {
    return $ChecklistItemsTable(attachedDatabase, alias);
  }
}

class ChecklistItem extends DataClass implements Insertable<ChecklistItem> {
  final String clientId;
  final String? householdId;
  final String templateClientId;
  final String title;
  final double? targetQuantity;
  final bool isChecked;
  final String? linkedInventoryItemId;
  final int sortOrder;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const ChecklistItem({
    required this.clientId,
    this.householdId,
    required this.templateClientId,
    required this.title,
    this.targetQuantity,
    required this.isChecked,
    this.linkedInventoryItemId,
    required this.sortOrder,
    required this.updatedAt,
    this.deletedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    map['template_client_id'] = Variable<String>(templateClientId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || targetQuantity != null) {
      map['target_quantity'] = Variable<double>(targetQuantity);
    }
    map['is_checked'] = Variable<bool>(isChecked);
    if (!nullToAbsent || linkedInventoryItemId != null) {
      map['linked_inventory_item_id'] = Variable<String>(linkedInventoryItemId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ChecklistItemsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistItemsCompanion(
      clientId: Value(clientId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      templateClientId: Value(templateClientId),
      title: Value(title),
      targetQuantity: targetQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(targetQuantity),
      isChecked: Value(isChecked),
      linkedInventoryItemId: linkedInventoryItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedInventoryItemId),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory ChecklistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItem(
      clientId: serializer.fromJson<String>(json['clientId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      templateClientId: serializer.fromJson<String>(json['templateClientId']),
      title: serializer.fromJson<String>(json['title']),
      targetQuantity: serializer.fromJson<double?>(json['targetQuantity']),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      linkedInventoryItemId: serializer.fromJson<String?>(
        json['linkedInventoryItemId'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'householdId': serializer.toJson<String?>(householdId),
      'templateClientId': serializer.toJson<String>(templateClientId),
      'title': serializer.toJson<String>(title),
      'targetQuantity': serializer.toJson<double?>(targetQuantity),
      'isChecked': serializer.toJson<bool>(isChecked),
      'linkedInventoryItemId': serializer.toJson<String?>(
        linkedInventoryItemId,
      ),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  ChecklistItem copyWith({
    String? clientId,
    Value<String?> householdId = const Value.absent(),
    String? templateClientId,
    String? title,
    Value<double?> targetQuantity = const Value.absent(),
    bool? isChecked,
    Value<String?> linkedInventoryItemId = const Value.absent(),
    int? sortOrder,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? dirty,
  }) => ChecklistItem(
    clientId: clientId ?? this.clientId,
    householdId: householdId.present ? householdId.value : this.householdId,
    templateClientId: templateClientId ?? this.templateClientId,
    title: title ?? this.title,
    targetQuantity: targetQuantity.present
        ? targetQuantity.value
        : this.targetQuantity,
    isChecked: isChecked ?? this.isChecked,
    linkedInventoryItemId: linkedInventoryItemId.present
        ? linkedInventoryItemId.value
        : this.linkedInventoryItemId,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    dirty: dirty ?? this.dirty,
  );
  ChecklistItem copyWithCompanion(ChecklistItemsCompanion data) {
    return ChecklistItem(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      templateClientId: data.templateClientId.present
          ? data.templateClientId.value
          : this.templateClientId,
      title: data.title.present ? data.title.value : this.title,
      targetQuantity: data.targetQuantity.present
          ? data.targetQuantity.value
          : this.targetQuantity,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      linkedInventoryItemId: data.linkedInventoryItemId.present
          ? data.linkedInventoryItemId.value
          : this.linkedInventoryItemId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItem(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('templateClientId: $templateClientId, ')
          ..write('title: $title, ')
          ..write('targetQuantity: $targetQuantity, ')
          ..write('isChecked: $isChecked, ')
          ..write('linkedInventoryItemId: $linkedInventoryItemId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    householdId,
    templateClientId,
    title,
    targetQuantity,
    isChecked,
    linkedInventoryItemId,
    sortOrder,
    updatedAt,
    deletedAt,
    dirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItem &&
          other.clientId == this.clientId &&
          other.householdId == this.householdId &&
          other.templateClientId == this.templateClientId &&
          other.title == this.title &&
          other.targetQuantity == this.targetQuantity &&
          other.isChecked == this.isChecked &&
          other.linkedInventoryItemId == this.linkedInventoryItemId &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class ChecklistItemsCompanion extends UpdateCompanion<ChecklistItem> {
  final Value<String> clientId;
  final Value<String?> householdId;
  final Value<String> templateClientId;
  final Value<String> title;
  final Value<double?> targetQuantity;
  final Value<bool> isChecked;
  final Value<String?> linkedInventoryItemId;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const ChecklistItemsCompanion({
    this.clientId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.templateClientId = const Value.absent(),
    this.title = const Value.absent(),
    this.targetQuantity = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.linkedInventoryItemId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistItemsCompanion.insert({
    required String clientId,
    this.householdId = const Value.absent(),
    required String templateClientId,
    required String title,
    this.targetQuantity = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.linkedInventoryItemId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       templateClientId = Value(templateClientId),
       title = Value(title),
       updatedAt = Value(updatedAt);
  static Insertable<ChecklistItem> custom({
    Expression<String>? clientId,
    Expression<String>? householdId,
    Expression<String>? templateClientId,
    Expression<String>? title,
    Expression<double>? targetQuantity,
    Expression<bool>? isChecked,
    Expression<String>? linkedInventoryItemId,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (householdId != null) 'household_id': householdId,
      if (templateClientId != null) 'template_client_id': templateClientId,
      if (title != null) 'title': title,
      if (targetQuantity != null) 'target_quantity': targetQuantity,
      if (isChecked != null) 'is_checked': isChecked,
      if (linkedInventoryItemId != null)
        'linked_inventory_item_id': linkedInventoryItemId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistItemsCompanion copyWith({
    Value<String>? clientId,
    Value<String?>? householdId,
    Value<String>? templateClientId,
    Value<String>? title,
    Value<double?>? targetQuantity,
    Value<bool>? isChecked,
    Value<String?>? linkedInventoryItemId,
    Value<int>? sortOrder,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return ChecklistItemsCompanion(
      clientId: clientId ?? this.clientId,
      householdId: householdId ?? this.householdId,
      templateClientId: templateClientId ?? this.templateClientId,
      title: title ?? this.title,
      targetQuantity: targetQuantity ?? this.targetQuantity,
      isChecked: isChecked ?? this.isChecked,
      linkedInventoryItemId:
          linkedInventoryItemId ?? this.linkedInventoryItemId,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (templateClientId.present) {
      map['template_client_id'] = Variable<String>(templateClientId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetQuantity.present) {
      map['target_quantity'] = Variable<double>(targetQuantity.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (linkedInventoryItemId.present) {
      map['linked_inventory_item_id'] = Variable<String>(
        linkedInventoryItemId.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsCompanion(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('templateClientId: $templateClientId, ')
          ..write('title: $title, ')
          ..write('targetQuantity: $targetQuantity, ')
          ..write('isChecked: $isChecked, ')
          ..write('linkedInventoryItemId: $linkedInventoryItemId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetEntriesTable extends BudgetEntries
    with TableInfo<$BudgetEntriesTable, BudgetEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedInventoryItemIdMeta =
      const VerificationMeta('linkedInventoryItemId');
  @override
  late final GeneratedColumn<String> linkedInventoryItemId =
      GeneratedColumn<String>(
        'linked_inventory_item_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    householdId,
    label,
    amountCents,
    currency,
    category,
    purchaseDate,
    linkedInventoryItemId,
    updatedAt,
    deletedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('linked_inventory_item_id')) {
      context.handle(
        _linkedInventoryItemIdMeta,
        linkedInventoryItemId.isAcceptableOrUnknown(
          data['linked_inventory_item_id']!,
          _linkedInventoryItemIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  BudgetEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetEntry(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      ),
      linkedInventoryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_inventory_item_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $BudgetEntriesTable createAlias(String alias) {
    return $BudgetEntriesTable(attachedDatabase, alias);
  }
}

class BudgetEntry extends DataClass implements Insertable<BudgetEntry> {
  final String clientId;
  final String householdId;
  final String label;

  /// Integer cents, to avoid floating-point money.
  final int amountCents;
  final String currency;

  /// Stores an `InventoryItemCategory` enum name as plain text.
  final String category;
  final DateTime? purchaseDate;
  final String? linkedInventoryItemId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const BudgetEntry({
    required this.clientId,
    required this.householdId,
    required this.label,
    required this.amountCents,
    required this.currency,
    required this.category,
    this.purchaseDate,
    this.linkedInventoryItemId,
    required this.updatedAt,
    this.deletedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['household_id'] = Variable<String>(householdId);
    map['label'] = Variable<String>(label);
    map['amount_cents'] = Variable<int>(amountCents);
    map['currency'] = Variable<String>(currency);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate);
    }
    if (!nullToAbsent || linkedInventoryItemId != null) {
      map['linked_inventory_item_id'] = Variable<String>(linkedInventoryItemId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  BudgetEntriesCompanion toCompanion(bool nullToAbsent) {
    return BudgetEntriesCompanion(
      clientId: Value(clientId),
      householdId: Value(householdId),
      label: Value(label),
      amountCents: Value(amountCents),
      currency: Value(currency),
      category: Value(category),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      linkedInventoryItemId: linkedInventoryItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedInventoryItemId),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory BudgetEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetEntry(
      clientId: serializer.fromJson<String>(json['clientId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      label: serializer.fromJson<String>(json['label']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      currency: serializer.fromJson<String>(json['currency']),
      category: serializer.fromJson<String>(json['category']),
      purchaseDate: serializer.fromJson<DateTime?>(json['purchaseDate']),
      linkedInventoryItemId: serializer.fromJson<String?>(
        json['linkedInventoryItemId'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'householdId': serializer.toJson<String>(householdId),
      'label': serializer.toJson<String>(label),
      'amountCents': serializer.toJson<int>(amountCents),
      'currency': serializer.toJson<String>(currency),
      'category': serializer.toJson<String>(category),
      'purchaseDate': serializer.toJson<DateTime?>(purchaseDate),
      'linkedInventoryItemId': serializer.toJson<String?>(
        linkedInventoryItemId,
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  BudgetEntry copyWith({
    String? clientId,
    String? householdId,
    String? label,
    int? amountCents,
    String? currency,
    String? category,
    Value<DateTime?> purchaseDate = const Value.absent(),
    Value<String?> linkedInventoryItemId = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? dirty,
  }) => BudgetEntry(
    clientId: clientId ?? this.clientId,
    householdId: householdId ?? this.householdId,
    label: label ?? this.label,
    amountCents: amountCents ?? this.amountCents,
    currency: currency ?? this.currency,
    category: category ?? this.category,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    linkedInventoryItemId: linkedInventoryItemId.present
        ? linkedInventoryItemId.value
        : this.linkedInventoryItemId,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    dirty: dirty ?? this.dirty,
  );
  BudgetEntry copyWithCompanion(BudgetEntriesCompanion data) {
    return BudgetEntry(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      label: data.label.present ? data.label.value : this.label,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      currency: data.currency.present ? data.currency.value : this.currency,
      category: data.category.present ? data.category.value : this.category,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      linkedInventoryItemId: data.linkedInventoryItemId.present
          ? data.linkedInventoryItemId.value
          : this.linkedInventoryItemId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetEntry(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('label: $label, ')
          ..write('amountCents: $amountCents, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('linkedInventoryItemId: $linkedInventoryItemId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    householdId,
    label,
    amountCents,
    currency,
    category,
    purchaseDate,
    linkedInventoryItemId,
    updatedAt,
    deletedAt,
    dirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetEntry &&
          other.clientId == this.clientId &&
          other.householdId == this.householdId &&
          other.label == this.label &&
          other.amountCents == this.amountCents &&
          other.currency == this.currency &&
          other.category == this.category &&
          other.purchaseDate == this.purchaseDate &&
          other.linkedInventoryItemId == this.linkedInventoryItemId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class BudgetEntriesCompanion extends UpdateCompanion<BudgetEntry> {
  final Value<String> clientId;
  final Value<String> householdId;
  final Value<String> label;
  final Value<int> amountCents;
  final Value<String> currency;
  final Value<String> category;
  final Value<DateTime?> purchaseDate;
  final Value<String?> linkedInventoryItemId;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const BudgetEntriesCompanion({
    this.clientId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.label = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.linkedInventoryItemId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetEntriesCompanion.insert({
    required String clientId,
    required String householdId,
    required String label,
    required int amountCents,
    required String currency,
    required String category,
    this.purchaseDate = const Value.absent(),
    this.linkedInventoryItemId = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       householdId = Value(householdId),
       label = Value(label),
       amountCents = Value(amountCents),
       currency = Value(currency),
       category = Value(category),
       updatedAt = Value(updatedAt);
  static Insertable<BudgetEntry> custom({
    Expression<String>? clientId,
    Expression<String>? householdId,
    Expression<String>? label,
    Expression<int>? amountCents,
    Expression<String>? currency,
    Expression<String>? category,
    Expression<DateTime>? purchaseDate,
    Expression<String>? linkedInventoryItemId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (householdId != null) 'household_id': householdId,
      if (label != null) 'label': label,
      if (amountCents != null) 'amount_cents': amountCents,
      if (currency != null) 'currency': currency,
      if (category != null) 'category': category,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (linkedInventoryItemId != null)
        'linked_inventory_item_id': linkedInventoryItemId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetEntriesCompanion copyWith({
    Value<String>? clientId,
    Value<String>? householdId,
    Value<String>? label,
    Value<int>? amountCents,
    Value<String>? currency,
    Value<String>? category,
    Value<DateTime?>? purchaseDate,
    Value<String?>? linkedInventoryItemId,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return BudgetEntriesCompanion(
      clientId: clientId ?? this.clientId,
      householdId: householdId ?? this.householdId,
      label: label ?? this.label,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      linkedInventoryItemId:
          linkedInventoryItemId ?? this.linkedInventoryItemId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (linkedInventoryItemId.present) {
      map['linked_inventory_item_id'] = Variable<String>(
        linkedInventoryItemId.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetEntriesCompanion(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('label: $label, ')
          ..write('amountCents: $amountCents, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('linkedInventoryItemId: $linkedInventoryItemId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HouseholdMembersTable extends HouseholdMembers
    with TableInfo<$HouseholdMembersTable, HouseholdMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthYearMeta = const VerificationMeta(
    'birthYear',
  );
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
    'birth_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bloodTypeMeta = const VerificationMeta(
    'bloodType',
  );
  @override
  late final GeneratedColumn<String> bloodType = GeneratedColumn<String>(
    'blood_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allergiesMeta = const VerificationMeta(
    'allergies',
  );
  @override
  late final GeneratedColumn<String> allergies = GeneratedColumn<String>(
    'allergies',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicationMeta = const VerificationMeta(
    'medication',
  );
  @override
  late final GeneratedColumn<String> medication = GeneratedColumn<String>(
    'medication',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionsMeta = const VerificationMeta(
    'conditions',
  );
  @override
  late final GeneratedColumn<String> conditions = GeneratedColumn<String>(
    'conditions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _insuranceMeta = const VerificationMeta(
    'insurance',
  );
  @override
  late final GeneratedColumn<String> insurance = GeneratedColumn<String>(
    'insurance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doctorMeta = const VerificationMeta('doctor');
  @override
  late final GeneratedColumn<String> doctor = GeneratedColumn<String>(
    'doctor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emergencyContactMeta = const VerificationMeta(
    'emergencyContact',
  );
  @override
  late final GeneratedColumn<String> emergencyContact = GeneratedColumn<String>(
    'emergency_contact',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    householdId,
    name,
    birthYear,
    bloodType,
    allergies,
    medication,
    conditions,
    insurance,
    doctor,
    emergencyContact,
    notes,
    sortOrder,
    updatedAt,
    deletedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<HouseholdMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('birth_year')) {
      context.handle(
        _birthYearMeta,
        birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta),
      );
    }
    if (data.containsKey('blood_type')) {
      context.handle(
        _bloodTypeMeta,
        bloodType.isAcceptableOrUnknown(data['blood_type']!, _bloodTypeMeta),
      );
    }
    if (data.containsKey('allergies')) {
      context.handle(
        _allergiesMeta,
        allergies.isAcceptableOrUnknown(data['allergies']!, _allergiesMeta),
      );
    }
    if (data.containsKey('medication')) {
      context.handle(
        _medicationMeta,
        medication.isAcceptableOrUnknown(data['medication']!, _medicationMeta),
      );
    }
    if (data.containsKey('conditions')) {
      context.handle(
        _conditionsMeta,
        conditions.isAcceptableOrUnknown(data['conditions']!, _conditionsMeta),
      );
    }
    if (data.containsKey('insurance')) {
      context.handle(
        _insuranceMeta,
        insurance.isAcceptableOrUnknown(data['insurance']!, _insuranceMeta),
      );
    }
    if (data.containsKey('doctor')) {
      context.handle(
        _doctorMeta,
        doctor.isAcceptableOrUnknown(data['doctor']!, _doctorMeta),
      );
    }
    if (data.containsKey('emergency_contact')) {
      context.handle(
        _emergencyContactMeta,
        emergencyContact.isAcceptableOrUnknown(
          data['emergency_contact']!,
          _emergencyContactMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  HouseholdMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdMember(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      birthYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_year'],
      ),
      bloodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blood_type'],
      ),
      allergies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergies'],
      ),
      medication: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication'],
      ),
      conditions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conditions'],
      ),
      insurance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insurance'],
      ),
      doctor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor'],
      ),
      emergencyContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emergency_contact'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $HouseholdMembersTable createAlias(String alias) {
    return $HouseholdMembersTable(attachedDatabase, alias);
  }
}

class HouseholdMember extends DataClass implements Insertable<HouseholdMember> {
  final String clientId;
  final String householdId;
  final String name;

  /// Year only, not a date. It is asked for so a paramedic knows roughly
  /// who they are treating; a birthday would be more than the reason
  /// needs, and this app does not collect more than it uses.
  final int? birthYear;
  final String? bloodType;
  final String? allergies;

  /// What they take regularly — the thing a household has to keep in the
  /// stores and the thing that must not be guessed at in an emergency.
  final String? medication;
  final String? conditions;
  final String? insurance;
  final String? doctor;

  /// Who to call about this person specifically.
  final String? emergencyContact;
  final String? notes;

  /// Keeps the cards in the order the household put them in rather than
  /// alphabetically, which would put a child before a parent for no
  /// reason anyone chose.
  final int sortOrder;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const HouseholdMember({
    required this.clientId,
    required this.householdId,
    required this.name,
    this.birthYear,
    this.bloodType,
    this.allergies,
    this.medication,
    this.conditions,
    this.insurance,
    this.doctor,
    this.emergencyContact,
    this.notes,
    required this.sortOrder,
    required this.updatedAt,
    this.deletedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || birthYear != null) {
      map['birth_year'] = Variable<int>(birthYear);
    }
    if (!nullToAbsent || bloodType != null) {
      map['blood_type'] = Variable<String>(bloodType);
    }
    if (!nullToAbsent || allergies != null) {
      map['allergies'] = Variable<String>(allergies);
    }
    if (!nullToAbsent || medication != null) {
      map['medication'] = Variable<String>(medication);
    }
    if (!nullToAbsent || conditions != null) {
      map['conditions'] = Variable<String>(conditions);
    }
    if (!nullToAbsent || insurance != null) {
      map['insurance'] = Variable<String>(insurance);
    }
    if (!nullToAbsent || doctor != null) {
      map['doctor'] = Variable<String>(doctor);
    }
    if (!nullToAbsent || emergencyContact != null) {
      map['emergency_contact'] = Variable<String>(emergencyContact);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  HouseholdMembersCompanion toCompanion(bool nullToAbsent) {
    return HouseholdMembersCompanion(
      clientId: Value(clientId),
      householdId: Value(householdId),
      name: Value(name),
      birthYear: birthYear == null && nullToAbsent
          ? const Value.absent()
          : Value(birthYear),
      bloodType: bloodType == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodType),
      allergies: allergies == null && nullToAbsent
          ? const Value.absent()
          : Value(allergies),
      medication: medication == null && nullToAbsent
          ? const Value.absent()
          : Value(medication),
      conditions: conditions == null && nullToAbsent
          ? const Value.absent()
          : Value(conditions),
      insurance: insurance == null && nullToAbsent
          ? const Value.absent()
          : Value(insurance),
      doctor: doctor == null && nullToAbsent
          ? const Value.absent()
          : Value(doctor),
      emergencyContact: emergencyContact == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyContact),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory HouseholdMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdMember(
      clientId: serializer.fromJson<String>(json['clientId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      birthYear: serializer.fromJson<int?>(json['birthYear']),
      bloodType: serializer.fromJson<String?>(json['bloodType']),
      allergies: serializer.fromJson<String?>(json['allergies']),
      medication: serializer.fromJson<String?>(json['medication']),
      conditions: serializer.fromJson<String?>(json['conditions']),
      insurance: serializer.fromJson<String?>(json['insurance']),
      doctor: serializer.fromJson<String?>(json['doctor']),
      emergencyContact: serializer.fromJson<String?>(json['emergencyContact']),
      notes: serializer.fromJson<String?>(json['notes']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'birthYear': serializer.toJson<int?>(birthYear),
      'bloodType': serializer.toJson<String?>(bloodType),
      'allergies': serializer.toJson<String?>(allergies),
      'medication': serializer.toJson<String?>(medication),
      'conditions': serializer.toJson<String?>(conditions),
      'insurance': serializer.toJson<String?>(insurance),
      'doctor': serializer.toJson<String?>(doctor),
      'emergencyContact': serializer.toJson<String?>(emergencyContact),
      'notes': serializer.toJson<String?>(notes),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  HouseholdMember copyWith({
    String? clientId,
    String? householdId,
    String? name,
    Value<int?> birthYear = const Value.absent(),
    Value<String?> bloodType = const Value.absent(),
    Value<String?> allergies = const Value.absent(),
    Value<String?> medication = const Value.absent(),
    Value<String?> conditions = const Value.absent(),
    Value<String?> insurance = const Value.absent(),
    Value<String?> doctor = const Value.absent(),
    Value<String?> emergencyContact = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? sortOrder,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? dirty,
  }) => HouseholdMember(
    clientId: clientId ?? this.clientId,
    householdId: householdId ?? this.householdId,
    name: name ?? this.name,
    birthYear: birthYear.present ? birthYear.value : this.birthYear,
    bloodType: bloodType.present ? bloodType.value : this.bloodType,
    allergies: allergies.present ? allergies.value : this.allergies,
    medication: medication.present ? medication.value : this.medication,
    conditions: conditions.present ? conditions.value : this.conditions,
    insurance: insurance.present ? insurance.value : this.insurance,
    doctor: doctor.present ? doctor.value : this.doctor,
    emergencyContact: emergencyContact.present
        ? emergencyContact.value
        : this.emergencyContact,
    notes: notes.present ? notes.value : this.notes,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    dirty: dirty ?? this.dirty,
  );
  HouseholdMember copyWithCompanion(HouseholdMembersCompanion data) {
    return HouseholdMember(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
      bloodType: data.bloodType.present ? data.bloodType.value : this.bloodType,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      medication: data.medication.present
          ? data.medication.value
          : this.medication,
      conditions: data.conditions.present
          ? data.conditions.value
          : this.conditions,
      insurance: data.insurance.present ? data.insurance.value : this.insurance,
      doctor: data.doctor.present ? data.doctor.value : this.doctor,
      emergencyContact: data.emergencyContact.present
          ? data.emergencyContact.value
          : this.emergencyContact,
      notes: data.notes.present ? data.notes.value : this.notes,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMember(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('birthYear: $birthYear, ')
          ..write('bloodType: $bloodType, ')
          ..write('allergies: $allergies, ')
          ..write('medication: $medication, ')
          ..write('conditions: $conditions, ')
          ..write('insurance: $insurance, ')
          ..write('doctor: $doctor, ')
          ..write('emergencyContact: $emergencyContact, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    householdId,
    name,
    birthYear,
    bloodType,
    allergies,
    medication,
    conditions,
    insurance,
    doctor,
    emergencyContact,
    notes,
    sortOrder,
    updatedAt,
    deletedAt,
    dirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdMember &&
          other.clientId == this.clientId &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.birthYear == this.birthYear &&
          other.bloodType == this.bloodType &&
          other.allergies == this.allergies &&
          other.medication == this.medication &&
          other.conditions == this.conditions &&
          other.insurance == this.insurance &&
          other.doctor == this.doctor &&
          other.emergencyContact == this.emergencyContact &&
          other.notes == this.notes &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class HouseholdMembersCompanion extends UpdateCompanion<HouseholdMember> {
  final Value<String> clientId;
  final Value<String> householdId;
  final Value<String> name;
  final Value<int?> birthYear;
  final Value<String?> bloodType;
  final Value<String?> allergies;
  final Value<String?> medication;
  final Value<String?> conditions;
  final Value<String?> insurance;
  final Value<String?> doctor;
  final Value<String?> emergencyContact;
  final Value<String?> notes;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const HouseholdMembersCompanion({
    this.clientId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.bloodType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.medication = const Value.absent(),
    this.conditions = const Value.absent(),
    this.insurance = const Value.absent(),
    this.doctor = const Value.absent(),
    this.emergencyContact = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdMembersCompanion.insert({
    required String clientId,
    required String householdId,
    required String name,
    this.birthYear = const Value.absent(),
    this.bloodType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.medication = const Value.absent(),
    this.conditions = const Value.absent(),
    this.insurance = const Value.absent(),
    this.doctor = const Value.absent(),
    this.emergencyContact = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       householdId = Value(householdId),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<HouseholdMember> custom({
    Expression<String>? clientId,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<int>? birthYear,
    Expression<String>? bloodType,
    Expression<String>? allergies,
    Expression<String>? medication,
    Expression<String>? conditions,
    Expression<String>? insurance,
    Expression<String>? doctor,
    Expression<String>? emergencyContact,
    Expression<String>? notes,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (birthYear != null) 'birth_year': birthYear,
      if (bloodType != null) 'blood_type': bloodType,
      if (allergies != null) 'allergies': allergies,
      if (medication != null) 'medication': medication,
      if (conditions != null) 'conditions': conditions,
      if (insurance != null) 'insurance': insurance,
      if (doctor != null) 'doctor': doctor,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
      if (notes != null) 'notes': notes,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdMembersCompanion copyWith({
    Value<String>? clientId,
    Value<String>? householdId,
    Value<String>? name,
    Value<int?>? birthYear,
    Value<String?>? bloodType,
    Value<String?>? allergies,
    Value<String?>? medication,
    Value<String?>? conditions,
    Value<String?>? insurance,
    Value<String?>? doctor,
    Value<String?>? emergencyContact,
    Value<String?>? notes,
    Value<int>? sortOrder,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return HouseholdMembersCompanion(
      clientId: clientId ?? this.clientId,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      birthYear: birthYear ?? this.birthYear,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medication: medication ?? this.medication,
      conditions: conditions ?? this.conditions,
      insurance: insurance ?? this.insurance,
      doctor: doctor ?? this.doctor,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (bloodType.present) {
      map['blood_type'] = Variable<String>(bloodType.value);
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(allergies.value);
    }
    if (medication.present) {
      map['medication'] = Variable<String>(medication.value);
    }
    if (conditions.present) {
      map['conditions'] = Variable<String>(conditions.value);
    }
    if (insurance.present) {
      map['insurance'] = Variable<String>(insurance.value);
    }
    if (doctor.present) {
      map['doctor'] = Variable<String>(doctor.value);
    }
    if (emergencyContact.present) {
      map['emergency_contact'] = Variable<String>(emergencyContact.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMembersCompanion(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('birthYear: $birthYear, ')
          ..write('bloodType: $bloodType, ')
          ..write('allergies: $allergies, ')
          ..write('medication: $medication, ')
          ..write('conditions: $conditions, ')
          ..write('insurance: $insurance, ')
          ..write('doctor: $doctor, ')
          ..write('emergencyContact: $emergencyContact, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HouseholdPlansTable extends HouseholdPlans
    with TableInfo<$HouseholdPlansTable, HouseholdPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meetingPointNearMeta = const VerificationMeta(
    'meetingPointNear',
  );
  @override
  late final GeneratedColumn<String> meetingPointNear = GeneratedColumn<String>(
    'meeting_point_near',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meetingPointFarMeta = const VerificationMeta(
    'meetingPointFar',
  );
  @override
  late final GeneratedColumn<String> meetingPointFar = GeneratedColumn<String>(
    'meeting_point_far',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactNameMeta = const VerificationMeta(
    'contactName',
  );
  @override
  late final GeneratedColumn<String> contactName = GeneratedColumn<String>(
    'contact_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactPhoneMeta = const VerificationMeta(
    'contactPhone',
  );
  @override
  late final GeneratedColumn<String> contactPhone = GeneratedColumn<String>(
    'contact_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kitLocationMeta = const VerificationMeta(
    'kitLocation',
  );
  @override
  late final GeneratedColumn<String> kitLocation = GeneratedColumn<String>(
    'kit_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shutoffLocationMeta = const VerificationMeta(
    'shutoffLocation',
  );
  @override
  late final GeneratedColumn<String> shutoffLocation = GeneratedColumn<String>(
    'shutoff_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    householdId,
    meetingPointNear,
    meetingPointFar,
    contactName,
    contactPhone,
    kitLocation,
    shutoffLocation,
    notes,
    updatedAt,
    deletedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<HouseholdPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('meeting_point_near')) {
      context.handle(
        _meetingPointNearMeta,
        meetingPointNear.isAcceptableOrUnknown(
          data['meeting_point_near']!,
          _meetingPointNearMeta,
        ),
      );
    }
    if (data.containsKey('meeting_point_far')) {
      context.handle(
        _meetingPointFarMeta,
        meetingPointFar.isAcceptableOrUnknown(
          data['meeting_point_far']!,
          _meetingPointFarMeta,
        ),
      );
    }
    if (data.containsKey('contact_name')) {
      context.handle(
        _contactNameMeta,
        contactName.isAcceptableOrUnknown(
          data['contact_name']!,
          _contactNameMeta,
        ),
      );
    }
    if (data.containsKey('contact_phone')) {
      context.handle(
        _contactPhoneMeta,
        contactPhone.isAcceptableOrUnknown(
          data['contact_phone']!,
          _contactPhoneMeta,
        ),
      );
    }
    if (data.containsKey('kit_location')) {
      context.handle(
        _kitLocationMeta,
        kitLocation.isAcceptableOrUnknown(
          data['kit_location']!,
          _kitLocationMeta,
        ),
      );
    }
    if (data.containsKey('shutoff_location')) {
      context.handle(
        _shutoffLocationMeta,
        shutoffLocation.isAcceptableOrUnknown(
          data['shutoff_location']!,
          _shutoffLocationMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  HouseholdPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdPlan(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      meetingPointNear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meeting_point_near'],
      ),
      meetingPointFar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meeting_point_far'],
      ),
      contactName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_name'],
      ),
      contactPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_phone'],
      ),
      kitLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kit_location'],
      ),
      shutoffLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shutoff_location'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $HouseholdPlansTable createAlias(String alias) {
    return $HouseholdPlansTable(attachedDatabase, alias);
  }
}

class HouseholdPlan extends DataClass implements Insertable<HouseholdPlan> {
  /// The household id, not a generated id. See the class comment.
  final String clientId;
  final String householdId;

  /// Where to gather if the house has to be left in a hurry — the corner,
  /// the neighbour's drive. Somewhere reachable on foot without a plan.
  final String? meetingPointNear;

  /// Where to gather if the whole area is cleared and the near one cannot
  /// be reached.
  final String? meetingPointFar;

  /// Someone outside the region everyone can ring to say where they are.
  final String? contactName;
  final String? contactPhone;

  /// Where the emergency luggage is kept, so nobody searches for it in
  /// the dark.
  final String? kitLocation;

  /// Where the water, gas and power can be shut off.
  final String? shutoffLocation;
  final String? notes;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const HouseholdPlan({
    required this.clientId,
    required this.householdId,
    this.meetingPointNear,
    this.meetingPointFar,
    this.contactName,
    this.contactPhone,
    this.kitLocation,
    this.shutoffLocation,
    this.notes,
    required this.updatedAt,
    this.deletedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['household_id'] = Variable<String>(householdId);
    if (!nullToAbsent || meetingPointNear != null) {
      map['meeting_point_near'] = Variable<String>(meetingPointNear);
    }
    if (!nullToAbsent || meetingPointFar != null) {
      map['meeting_point_far'] = Variable<String>(meetingPointFar);
    }
    if (!nullToAbsent || contactName != null) {
      map['contact_name'] = Variable<String>(contactName);
    }
    if (!nullToAbsent || contactPhone != null) {
      map['contact_phone'] = Variable<String>(contactPhone);
    }
    if (!nullToAbsent || kitLocation != null) {
      map['kit_location'] = Variable<String>(kitLocation);
    }
    if (!nullToAbsent || shutoffLocation != null) {
      map['shutoff_location'] = Variable<String>(shutoffLocation);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  HouseholdPlansCompanion toCompanion(bool nullToAbsent) {
    return HouseholdPlansCompanion(
      clientId: Value(clientId),
      householdId: Value(householdId),
      meetingPointNear: meetingPointNear == null && nullToAbsent
          ? const Value.absent()
          : Value(meetingPointNear),
      meetingPointFar: meetingPointFar == null && nullToAbsent
          ? const Value.absent()
          : Value(meetingPointFar),
      contactName: contactName == null && nullToAbsent
          ? const Value.absent()
          : Value(contactName),
      contactPhone: contactPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(contactPhone),
      kitLocation: kitLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(kitLocation),
      shutoffLocation: shutoffLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(shutoffLocation),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory HouseholdPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdPlan(
      clientId: serializer.fromJson<String>(json['clientId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      meetingPointNear: serializer.fromJson<String?>(json['meetingPointNear']),
      meetingPointFar: serializer.fromJson<String?>(json['meetingPointFar']),
      contactName: serializer.fromJson<String?>(json['contactName']),
      contactPhone: serializer.fromJson<String?>(json['contactPhone']),
      kitLocation: serializer.fromJson<String?>(json['kitLocation']),
      shutoffLocation: serializer.fromJson<String?>(json['shutoffLocation']),
      notes: serializer.fromJson<String?>(json['notes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'householdId': serializer.toJson<String>(householdId),
      'meetingPointNear': serializer.toJson<String?>(meetingPointNear),
      'meetingPointFar': serializer.toJson<String?>(meetingPointFar),
      'contactName': serializer.toJson<String?>(contactName),
      'contactPhone': serializer.toJson<String?>(contactPhone),
      'kitLocation': serializer.toJson<String?>(kitLocation),
      'shutoffLocation': serializer.toJson<String?>(shutoffLocation),
      'notes': serializer.toJson<String?>(notes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  HouseholdPlan copyWith({
    String? clientId,
    String? householdId,
    Value<String?> meetingPointNear = const Value.absent(),
    Value<String?> meetingPointFar = const Value.absent(),
    Value<String?> contactName = const Value.absent(),
    Value<String?> contactPhone = const Value.absent(),
    Value<String?> kitLocation = const Value.absent(),
    Value<String?> shutoffLocation = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? dirty,
  }) => HouseholdPlan(
    clientId: clientId ?? this.clientId,
    householdId: householdId ?? this.householdId,
    meetingPointNear: meetingPointNear.present
        ? meetingPointNear.value
        : this.meetingPointNear,
    meetingPointFar: meetingPointFar.present
        ? meetingPointFar.value
        : this.meetingPointFar,
    contactName: contactName.present ? contactName.value : this.contactName,
    contactPhone: contactPhone.present ? contactPhone.value : this.contactPhone,
    kitLocation: kitLocation.present ? kitLocation.value : this.kitLocation,
    shutoffLocation: shutoffLocation.present
        ? shutoffLocation.value
        : this.shutoffLocation,
    notes: notes.present ? notes.value : this.notes,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    dirty: dirty ?? this.dirty,
  );
  HouseholdPlan copyWithCompanion(HouseholdPlansCompanion data) {
    return HouseholdPlan(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      meetingPointNear: data.meetingPointNear.present
          ? data.meetingPointNear.value
          : this.meetingPointNear,
      meetingPointFar: data.meetingPointFar.present
          ? data.meetingPointFar.value
          : this.meetingPointFar,
      contactName: data.contactName.present
          ? data.contactName.value
          : this.contactName,
      contactPhone: data.contactPhone.present
          ? data.contactPhone.value
          : this.contactPhone,
      kitLocation: data.kitLocation.present
          ? data.kitLocation.value
          : this.kitLocation,
      shutoffLocation: data.shutoffLocation.present
          ? data.shutoffLocation.value
          : this.shutoffLocation,
      notes: data.notes.present ? data.notes.value : this.notes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdPlan(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('meetingPointNear: $meetingPointNear, ')
          ..write('meetingPointFar: $meetingPointFar, ')
          ..write('contactName: $contactName, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('kitLocation: $kitLocation, ')
          ..write('shutoffLocation: $shutoffLocation, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    householdId,
    meetingPointNear,
    meetingPointFar,
    contactName,
    contactPhone,
    kitLocation,
    shutoffLocation,
    notes,
    updatedAt,
    deletedAt,
    dirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdPlan &&
          other.clientId == this.clientId &&
          other.householdId == this.householdId &&
          other.meetingPointNear == this.meetingPointNear &&
          other.meetingPointFar == this.meetingPointFar &&
          other.contactName == this.contactName &&
          other.contactPhone == this.contactPhone &&
          other.kitLocation == this.kitLocation &&
          other.shutoffLocation == this.shutoffLocation &&
          other.notes == this.notes &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class HouseholdPlansCompanion extends UpdateCompanion<HouseholdPlan> {
  final Value<String> clientId;
  final Value<String> householdId;
  final Value<String?> meetingPointNear;
  final Value<String?> meetingPointFar;
  final Value<String?> contactName;
  final Value<String?> contactPhone;
  final Value<String?> kitLocation;
  final Value<String?> shutoffLocation;
  final Value<String?> notes;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const HouseholdPlansCompanion({
    this.clientId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.meetingPointNear = const Value.absent(),
    this.meetingPointFar = const Value.absent(),
    this.contactName = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.kitLocation = const Value.absent(),
    this.shutoffLocation = const Value.absent(),
    this.notes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdPlansCompanion.insert({
    required String clientId,
    required String householdId,
    this.meetingPointNear = const Value.absent(),
    this.meetingPointFar = const Value.absent(),
    this.contactName = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.kitLocation = const Value.absent(),
    this.shutoffLocation = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       householdId = Value(householdId),
       updatedAt = Value(updatedAt);
  static Insertable<HouseholdPlan> custom({
    Expression<String>? clientId,
    Expression<String>? householdId,
    Expression<String>? meetingPointNear,
    Expression<String>? meetingPointFar,
    Expression<String>? contactName,
    Expression<String>? contactPhone,
    Expression<String>? kitLocation,
    Expression<String>? shutoffLocation,
    Expression<String>? notes,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (householdId != null) 'household_id': householdId,
      if (meetingPointNear != null) 'meeting_point_near': meetingPointNear,
      if (meetingPointFar != null) 'meeting_point_far': meetingPointFar,
      if (contactName != null) 'contact_name': contactName,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (kitLocation != null) 'kit_location': kitLocation,
      if (shutoffLocation != null) 'shutoff_location': shutoffLocation,
      if (notes != null) 'notes': notes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdPlansCompanion copyWith({
    Value<String>? clientId,
    Value<String>? householdId,
    Value<String?>? meetingPointNear,
    Value<String?>? meetingPointFar,
    Value<String?>? contactName,
    Value<String?>? contactPhone,
    Value<String?>? kitLocation,
    Value<String?>? shutoffLocation,
    Value<String?>? notes,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return HouseholdPlansCompanion(
      clientId: clientId ?? this.clientId,
      householdId: householdId ?? this.householdId,
      meetingPointNear: meetingPointNear ?? this.meetingPointNear,
      meetingPointFar: meetingPointFar ?? this.meetingPointFar,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      kitLocation: kitLocation ?? this.kitLocation,
      shutoffLocation: shutoffLocation ?? this.shutoffLocation,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (meetingPointNear.present) {
      map['meeting_point_near'] = Variable<String>(meetingPointNear.value);
    }
    if (meetingPointFar.present) {
      map['meeting_point_far'] = Variable<String>(meetingPointFar.value);
    }
    if (contactName.present) {
      map['contact_name'] = Variable<String>(contactName.value);
    }
    if (contactPhone.present) {
      map['contact_phone'] = Variable<String>(contactPhone.value);
    }
    if (kitLocation.present) {
      map['kit_location'] = Variable<String>(kitLocation.value);
    }
    if (shutoffLocation.present) {
      map['shutoff_location'] = Variable<String>(shutoffLocation.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdPlansCompanion(')
          ..write('clientId: $clientId, ')
          ..write('householdId: $householdId, ')
          ..write('meetingPointNear: $meetingPointNear, ')
          ..write('meetingPointFar: $meetingPointFar, ')
          ..write('contactName: $contactName, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('kitLocation: $kitLocation, ')
          ..write('shutoffLocation: $shutoffLocation, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WarningsTable extends Warnings with TableInfo<$WarningsTable, Warning> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WarningsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionKeyMeta = const VerificationMeta(
    'regionKey',
  );
  @override
  late final GeneratedColumn<String> regionKey = GeneratedColumn<String>(
    'region_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headlineMeta = const VerificationMeta(
    'headline',
  );
  @override
  late final GeneratedColumn<String> headline = GeneratedColumn<String>(
    'headline',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effectiveMeta = const VerificationMeta(
    'effective',
  );
  @override
  late final GeneratedColumn<DateTime> effective = GeneratedColumn<DateTime>(
    'effective',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresMeta = const VerificationMeta(
    'expires',
  );
  @override
  late final GeneratedColumn<DateTime> expires = GeneratedColumn<DateTime>(
    'expires',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentMeta = const VerificationMeta('sent');
  @override
  late final GeneratedColumn<DateTime> sent = GeneratedColumn<DateTime>(
    'sent',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notifiedMeta = const VerificationMeta(
    'notified',
  );
  @override
  late final GeneratedColumn<bool> notified = GeneratedColumn<bool>(
    'notified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    source,
    externalId,
    countryCode,
    regionKey,
    severity,
    eventType,
    headline,
    description,
    effective,
    expires,
    sent,
    updatedAt,
    notified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'warnings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Warning> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countryCodeMeta);
    }
    if (data.containsKey('region_key')) {
      context.handle(
        _regionKeyMeta,
        regionKey.isAcceptableOrUnknown(data['region_key']!, _regionKeyMeta),
      );
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('headline')) {
      context.handle(
        _headlineMeta,
        headline.isAcceptableOrUnknown(data['headline']!, _headlineMeta),
      );
    } else if (isInserting) {
      context.missing(_headlineMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('effective')) {
      context.handle(
        _effectiveMeta,
        effective.isAcceptableOrUnknown(data['effective']!, _effectiveMeta),
      );
    } else if (isInserting) {
      context.missing(_effectiveMeta);
    }
    if (data.containsKey('expires')) {
      context.handle(
        _expiresMeta,
        expires.isAcceptableOrUnknown(data['expires']!, _expiresMeta),
      );
    }
    if (data.containsKey('sent')) {
      context.handle(
        _sentMeta,
        sent.isAcceptableOrUnknown(data['sent']!, _sentMeta),
      );
    } else if (isInserting) {
      context.missing(_sentMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('notified')) {
      context.handle(
        _notifiedMeta,
        notified.isAcceptableOrUnknown(data['notified']!, _notifiedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, externalId};
  @override
  Warning map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Warning(
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      )!,
      regionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_key'],
      ),
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      headline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headline'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      effective: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective'],
      )!,
      expires: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires'],
      ),
      sent: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      notified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notified'],
      )!,
    );
  }

  @override
  $WarningsTable createAlias(String alias) {
    return $WarningsTable(attachedDatabase, alias);
  }
}

class Warning extends DataClass implements Insertable<Warning> {
  /// A `WarningSource` enum name as plain text.
  final String source;

  /// The feed's own id for this warning.
  final String externalId;
  final String countryCode;
  final String? regionKey;

  /// Stores a `WarningSeverity` enum name as plain text.
  final String severity;
  final String eventType;
  final String headline;
  final String? description;
  final DateTime effective;
  final DateTime? expires;
  final DateTime sent;

  /// When this row was last written locally. Drives "what is new since I
  /// last looked", which is what decides whether to notify.
  final DateTime updatedAt;

  /// True once a notification has gone out for this warning, so a repeated
  /// poll does not announce the same thing again. Separate from
  /// [updatedAt] because a warning can be rewritten by its source without
  /// becoming newsworthy again.
  final bool notified;
  const Warning({
    required this.source,
    required this.externalId,
    required this.countryCode,
    this.regionKey,
    required this.severity,
    required this.eventType,
    required this.headline,
    this.description,
    required this.effective,
    this.expires,
    required this.sent,
    required this.updatedAt,
    required this.notified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['external_id'] = Variable<String>(externalId);
    map['country_code'] = Variable<String>(countryCode);
    if (!nullToAbsent || regionKey != null) {
      map['region_key'] = Variable<String>(regionKey);
    }
    map['severity'] = Variable<String>(severity);
    map['event_type'] = Variable<String>(eventType);
    map['headline'] = Variable<String>(headline);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['effective'] = Variable<DateTime>(effective);
    if (!nullToAbsent || expires != null) {
      map['expires'] = Variable<DateTime>(expires);
    }
    map['sent'] = Variable<DateTime>(sent);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['notified'] = Variable<bool>(notified);
    return map;
  }

  WarningsCompanion toCompanion(bool nullToAbsent) {
    return WarningsCompanion(
      source: Value(source),
      externalId: Value(externalId),
      countryCode: Value(countryCode),
      regionKey: regionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(regionKey),
      severity: Value(severity),
      eventType: Value(eventType),
      headline: Value(headline),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      effective: Value(effective),
      expires: expires == null && nullToAbsent
          ? const Value.absent()
          : Value(expires),
      sent: Value(sent),
      updatedAt: Value(updatedAt),
      notified: Value(notified),
    );
  }

  factory Warning.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Warning(
      source: serializer.fromJson<String>(json['source']),
      externalId: serializer.fromJson<String>(json['externalId']),
      countryCode: serializer.fromJson<String>(json['countryCode']),
      regionKey: serializer.fromJson<String?>(json['regionKey']),
      severity: serializer.fromJson<String>(json['severity']),
      eventType: serializer.fromJson<String>(json['eventType']),
      headline: serializer.fromJson<String>(json['headline']),
      description: serializer.fromJson<String?>(json['description']),
      effective: serializer.fromJson<DateTime>(json['effective']),
      expires: serializer.fromJson<DateTime?>(json['expires']),
      sent: serializer.fromJson<DateTime>(json['sent']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      notified: serializer.fromJson<bool>(json['notified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'externalId': serializer.toJson<String>(externalId),
      'countryCode': serializer.toJson<String>(countryCode),
      'regionKey': serializer.toJson<String?>(regionKey),
      'severity': serializer.toJson<String>(severity),
      'eventType': serializer.toJson<String>(eventType),
      'headline': serializer.toJson<String>(headline),
      'description': serializer.toJson<String?>(description),
      'effective': serializer.toJson<DateTime>(effective),
      'expires': serializer.toJson<DateTime?>(expires),
      'sent': serializer.toJson<DateTime>(sent),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'notified': serializer.toJson<bool>(notified),
    };
  }

  Warning copyWith({
    String? source,
    String? externalId,
    String? countryCode,
    Value<String?> regionKey = const Value.absent(),
    String? severity,
    String? eventType,
    String? headline,
    Value<String?> description = const Value.absent(),
    DateTime? effective,
    Value<DateTime?> expires = const Value.absent(),
    DateTime? sent,
    DateTime? updatedAt,
    bool? notified,
  }) => Warning(
    source: source ?? this.source,
    externalId: externalId ?? this.externalId,
    countryCode: countryCode ?? this.countryCode,
    regionKey: regionKey.present ? regionKey.value : this.regionKey,
    severity: severity ?? this.severity,
    eventType: eventType ?? this.eventType,
    headline: headline ?? this.headline,
    description: description.present ? description.value : this.description,
    effective: effective ?? this.effective,
    expires: expires.present ? expires.value : this.expires,
    sent: sent ?? this.sent,
    updatedAt: updatedAt ?? this.updatedAt,
    notified: notified ?? this.notified,
  );
  Warning copyWithCompanion(WarningsCompanion data) {
    return Warning(
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      regionKey: data.regionKey.present ? data.regionKey.value : this.regionKey,
      severity: data.severity.present ? data.severity.value : this.severity,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      headline: data.headline.present ? data.headline.value : this.headline,
      description: data.description.present
          ? data.description.value
          : this.description,
      effective: data.effective.present ? data.effective.value : this.effective,
      expires: data.expires.present ? data.expires.value : this.expires,
      sent: data.sent.present ? data.sent.value : this.sent,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      notified: data.notified.present ? data.notified.value : this.notified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Warning(')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('countryCode: $countryCode, ')
          ..write('regionKey: $regionKey, ')
          ..write('severity: $severity, ')
          ..write('eventType: $eventType, ')
          ..write('headline: $headline, ')
          ..write('description: $description, ')
          ..write('effective: $effective, ')
          ..write('expires: $expires, ')
          ..write('sent: $sent, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notified: $notified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    source,
    externalId,
    countryCode,
    regionKey,
    severity,
    eventType,
    headline,
    description,
    effective,
    expires,
    sent,
    updatedAt,
    notified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Warning &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.countryCode == this.countryCode &&
          other.regionKey == this.regionKey &&
          other.severity == this.severity &&
          other.eventType == this.eventType &&
          other.headline == this.headline &&
          other.description == this.description &&
          other.effective == this.effective &&
          other.expires == this.expires &&
          other.sent == this.sent &&
          other.updatedAt == this.updatedAt &&
          other.notified == this.notified);
}

class WarningsCompanion extends UpdateCompanion<Warning> {
  final Value<String> source;
  final Value<String> externalId;
  final Value<String> countryCode;
  final Value<String?> regionKey;
  final Value<String> severity;
  final Value<String> eventType;
  final Value<String> headline;
  final Value<String?> description;
  final Value<DateTime> effective;
  final Value<DateTime?> expires;
  final Value<DateTime> sent;
  final Value<DateTime> updatedAt;
  final Value<bool> notified;
  final Value<int> rowid;
  const WarningsCompanion({
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.regionKey = const Value.absent(),
    this.severity = const Value.absent(),
    this.eventType = const Value.absent(),
    this.headline = const Value.absent(),
    this.description = const Value.absent(),
    this.effective = const Value.absent(),
    this.expires = const Value.absent(),
    this.sent = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.notified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WarningsCompanion.insert({
    required String source,
    required String externalId,
    required String countryCode,
    this.regionKey = const Value.absent(),
    required String severity,
    required String eventType,
    required String headline,
    this.description = const Value.absent(),
    required DateTime effective,
    this.expires = const Value.absent(),
    required DateTime sent,
    required DateTime updatedAt,
    this.notified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : source = Value(source),
       externalId = Value(externalId),
       countryCode = Value(countryCode),
       severity = Value(severity),
       eventType = Value(eventType),
       headline = Value(headline),
       effective = Value(effective),
       sent = Value(sent),
       updatedAt = Value(updatedAt);
  static Insertable<Warning> custom({
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<String>? countryCode,
    Expression<String>? regionKey,
    Expression<String>? severity,
    Expression<String>? eventType,
    Expression<String>? headline,
    Expression<String>? description,
    Expression<DateTime>? effective,
    Expression<DateTime>? expires,
    Expression<DateTime>? sent,
    Expression<DateTime>? updatedAt,
    Expression<bool>? notified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (countryCode != null) 'country_code': countryCode,
      if (regionKey != null) 'region_key': regionKey,
      if (severity != null) 'severity': severity,
      if (eventType != null) 'event_type': eventType,
      if (headline != null) 'headline': headline,
      if (description != null) 'description': description,
      if (effective != null) 'effective': effective,
      if (expires != null) 'expires': expires,
      if (sent != null) 'sent': sent,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (notified != null) 'notified': notified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WarningsCompanion copyWith({
    Value<String>? source,
    Value<String>? externalId,
    Value<String>? countryCode,
    Value<String?>? regionKey,
    Value<String>? severity,
    Value<String>? eventType,
    Value<String>? headline,
    Value<String?>? description,
    Value<DateTime>? effective,
    Value<DateTime?>? expires,
    Value<DateTime>? sent,
    Value<DateTime>? updatedAt,
    Value<bool>? notified,
    Value<int>? rowid,
  }) {
    return WarningsCompanion(
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      countryCode: countryCode ?? this.countryCode,
      regionKey: regionKey ?? this.regionKey,
      severity: severity ?? this.severity,
      eventType: eventType ?? this.eventType,
      headline: headline ?? this.headline,
      description: description ?? this.description,
      effective: effective ?? this.effective,
      expires: expires ?? this.expires,
      sent: sent ?? this.sent,
      updatedAt: updatedAt ?? this.updatedAt,
      notified: notified ?? this.notified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (regionKey.present) {
      map['region_key'] = Variable<String>(regionKey.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (headline.present) {
      map['headline'] = Variable<String>(headline.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (effective.present) {
      map['effective'] = Variable<DateTime>(effective.value);
    }
    if (expires.present) {
      map['expires'] = Variable<DateTime>(expires.value);
    }
    if (sent.present) {
      map['sent'] = Variable<DateTime>(sent.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (notified.present) {
      map['notified'] = Variable<bool>(notified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WarningsCompanion(')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('countryCode: $countryCode, ')
          ..write('regionKey: $regionKey, ')
          ..write('severity: $severity, ')
          ..write('eventType: $eventType, ')
          ..write('headline: $headline, ')
          ..write('description: $description, ')
          ..write('effective: $effective, ')
          ..write('expires: $expires, ')
          ..write('sent: $sent, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notified: $notified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPulledAtMeta = const VerificationMeta(
    'lastPulledAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPulledAt = GeneratedColumn<DateTime>(
    'last_pulled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entity, lastPulledAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('last_pulled_at')) {
      context.handle(
        _lastPulledAtMeta,
        lastPulledAt.isAcceptableOrUnknown(
          data['last_pulled_at']!,
          _lastPulledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastPulledAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      lastPulledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pulled_at'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String entity;
  final DateTime lastPulledAt;
  const SyncStateData({required this.entity, required this.lastPulledAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['last_pulled_at'] = Variable<DateTime>(lastPulledAt);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      entity: Value(entity),
      lastPulledAt: Value(lastPulledAt),
    );
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      entity: serializer.fromJson<String>(json['entity']),
      lastPulledAt: serializer.fromJson<DateTime>(json['lastPulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'lastPulledAt': serializer.toJson<DateTime>(lastPulledAt),
    };
  }

  SyncStateData copyWith({String? entity, DateTime? lastPulledAt}) =>
      SyncStateData(
        entity: entity ?? this.entity,
        lastPulledAt: lastPulledAt ?? this.lastPulledAt,
      );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      entity: data.entity.present ? data.entity.value : this.entity,
      lastPulledAt: data.lastPulledAt.present
          ? data.lastPulledAt.value
          : this.lastPulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('entity: $entity, ')
          ..write('lastPulledAt: $lastPulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, lastPulledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.entity == this.entity &&
          other.lastPulledAt == this.lastPulledAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> entity;
  final Value<DateTime> lastPulledAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.entity = const Value.absent(),
    this.lastPulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String entity,
    required DateTime lastPulledAt,
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       lastPulledAt = Value(lastPulledAt);
  static Insertable<SyncStateData> custom({
    Expression<String>? entity,
    Expression<DateTime>? lastPulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (lastPulledAt != null) 'last_pulled_at': lastPulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? entity,
    Value<DateTime>? lastPulledAt,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      entity: entity ?? this.entity,
      lastPulledAt: lastPulledAt ?? this.lastPulledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (lastPulledAt.present) {
      map['last_pulled_at'] = Variable<DateTime>(lastPulledAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('entity: $entity, ')
          ..write('lastPulledAt: $lastPulledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $ChecklistTemplatesTable checklistTemplates =
      $ChecklistTemplatesTable(this);
  late final $ChecklistItemsTable checklistItems = $ChecklistItemsTable(this);
  late final $BudgetEntriesTable budgetEntries = $BudgetEntriesTable(this);
  late final $HouseholdMembersTable householdMembers = $HouseholdMembersTable(
    this,
  );
  late final $HouseholdPlansTable householdPlans = $HouseholdPlansTable(this);
  late final $WarningsTable warnings = $WarningsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    inventoryItems,
    checklistTemplates,
    checklistItems,
    budgetEntries,
    householdMembers,
    householdPlans,
    warnings,
    syncState,
  ];
}
