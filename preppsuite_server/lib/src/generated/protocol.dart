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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i3;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i4;
import 'budget/models/budget_entry.dart' as _i5;
import 'checklists/models/checklist_category.dart' as _i6;
import 'checklists/models/checklist_item.dart' as _i7;
import 'checklists/models/checklist_template.dart' as _i8;
import 'households/models/household.dart' as _i9;
import 'households/models/household_exception.dart' as _i10;
import 'households/models/household_exception_reason.dart' as _i11;
import 'households/models/household_member.dart' as _i12;
import 'households/models/household_membership_info.dart' as _i13;
import 'households/models/household_role.dart' as _i14;
import 'inventory/models/inventory_item.dart' as _i15;
import 'inventory/models/inventory_item_category.dart' as _i16;
import 'warnings/models/warning.dart' as _i17;
import 'warnings/models/warning_region_kind.dart' as _i18;
import 'warnings/models/warning_region_subscription.dart' as _i19;
import 'warnings/models/warning_severity.dart' as _i20;
import 'warnings/models/warning_source.dart' as _i21;
import 'package:preppsuite_server/src/generated/budget/models/budget_entry.dart'
    as _i22;
import 'package:preppsuite_server/src/generated/checklists/models/checklist_template.dart'
    as _i23;
import 'package:preppsuite_server/src/generated/checklists/models/checklist_item.dart'
    as _i24;
import 'package:preppsuite_server/src/generated/households/models/household_member.dart'
    as _i25;
import 'package:preppsuite_server/src/generated/warnings/models/warning_region_subscription.dart'
    as _i26;
import 'package:preppsuite_server/src/generated/inventory/models/inventory_item.dart'
    as _i27;
import 'package:preppsuite_server/src/generated/warnings/models/warning.dart'
    as _i28;
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
export 'warnings/models/warning_region_kind.dart';
export 'warnings/models/warning_region_subscription.dart';
export 'warnings/models/warning_severity.dart';
export 'warnings/models/warning_source.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'budget_entry',
      dartName: 'BudgetEntry',
      schema: 'public',
      module: 'preppsuite',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'clientId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'householdId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'label',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'amountCents',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'currency',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'category',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:InventoryItemCategory',
        ),
        _i2.ColumnDefinition(
          name: 'purchaseDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'linkedInventoryItemId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deletedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'budget_entry_fk_0',
          columns: ['householdId'],
          referenceTable: 'household',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'budget_entry_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'budget_entry_household_client_id',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'budget_entry_household_updated_at',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'checklist_item',
      dartName: 'ChecklistItem',
      schema: 'public',
      module: 'preppsuite',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'clientId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'householdId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'templateId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'targetQuantity',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'isChecked',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'linkedInventoryItemId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'sortOrder',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deletedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'checklist_item_fk_0',
          columns: ['householdId'],
          referenceTable: 'household',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'checklist_item_fk_1',
          columns: ['templateId'],
          referenceTable: 'checklist_template',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'checklist_item_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'checklist_item_household_client_id',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'checklist_item_household_updated_at',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'checklist_item_template',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'templateId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'checklist_template',
      dartName: 'ChecklistTemplate',
      schema: 'public',
      module: 'preppsuite',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'clientId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'householdId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'category',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ChecklistCategory',
        ),
        _i2.ColumnDefinition(
          name: 'isBuiltIn',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deletedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'checklist_template_fk_0',
          columns: ['householdId'],
          referenceTable: 'household',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'checklist_template_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'checklist_template_household_client_id',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'checklist_template_household_updated_at',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'household',
      dartName: 'Household',
      schema: 'public',
      module: 'preppsuite',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'countryCode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'regionKey',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'inviteCode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'household_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'household_invite_code',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'inviteCode',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'household_member',
      dartName: 'HouseholdMember',
      schema: 'public',
      module: 'preppsuite',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'householdId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:HouseholdRole',
        ),
        _i2.ColumnDefinition(
          name: 'joinedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'household_member_fk_0',
          columns: ['householdId'],
          referenceTable: 'household',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'household_member_fk_1',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'household_member_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'household_member_household_auth_user',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'inventory_item',
      dartName: 'InventoryItem',
      schema: 'public',
      module: 'preppsuite',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'householdId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'clientId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'category',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:InventoryItemCategory',
        ),
        _i2.ColumnDefinition(
          name: 'barcode',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'offProductId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'quantity',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'unit',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'storageLocation',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'expirationDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'minQuantity',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'calories',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'notes',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deletedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'inventory_item_fk_0',
          columns: ['householdId'],
          referenceTable: 'household',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'inventory_item_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'inventory_item_household_client_id',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'inventory_item_household_updated_at',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'warning',
      dartName: 'Warning',
      schema: 'public',
      module: 'preppsuite',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'source',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:WarningSource',
        ),
        _i2.ColumnDefinition(
          name: 'externalId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'countryCode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'regionKey',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'severity',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:WarningSeverity',
        ),
        _i2.ColumnDefinition(
          name: 'eventType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'headline',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'effective',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'expires',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'sent',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'rawPayload',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'warning_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'warning_source_external_id',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'source',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'externalId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'warning_country_updated_at',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'countryCode',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'warning_region_subscription',
      dartName: 'WarningRegionSubscription',
      schema: 'public',
      module: 'preppsuite',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'householdId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'kind',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:WarningRegionKind',
        ),
        _i2.ColumnDefinition(
          name: 'value',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'label',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'warning_region_subscription_fk_0',
          columns: ['householdId'],
          referenceTable: 'household',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'warning_region_subscription_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'warning_region_subscription_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'householdId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'kind',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'value',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

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

    if (t == _i5.BudgetEntry) {
      return _i5.BudgetEntry.fromJson(data) as T;
    }
    if (t == _i6.ChecklistCategory) {
      return _i6.ChecklistCategory.fromJson(data) as T;
    }
    if (t == _i7.ChecklistItem) {
      return _i7.ChecklistItem.fromJson(data) as T;
    }
    if (t == _i8.ChecklistTemplate) {
      return _i8.ChecklistTemplate.fromJson(data) as T;
    }
    if (t == _i9.Household) {
      return _i9.Household.fromJson(data) as T;
    }
    if (t == _i10.HouseholdException) {
      return _i10.HouseholdException.fromJson(data) as T;
    }
    if (t == _i11.HouseholdExceptionReason) {
      return _i11.HouseholdExceptionReason.fromJson(data) as T;
    }
    if (t == _i12.HouseholdMember) {
      return _i12.HouseholdMember.fromJson(data) as T;
    }
    if (t == _i13.HouseholdMembershipInfo) {
      return _i13.HouseholdMembershipInfo.fromJson(data) as T;
    }
    if (t == _i14.HouseholdRole) {
      return _i14.HouseholdRole.fromJson(data) as T;
    }
    if (t == _i15.InventoryItem) {
      return _i15.InventoryItem.fromJson(data) as T;
    }
    if (t == _i16.InventoryItemCategory) {
      return _i16.InventoryItemCategory.fromJson(data) as T;
    }
    if (t == _i17.Warning) {
      return _i17.Warning.fromJson(data) as T;
    }
    if (t == _i18.WarningRegionKind) {
      return _i18.WarningRegionKind.fromJson(data) as T;
    }
    if (t == _i19.WarningRegionSubscription) {
      return _i19.WarningRegionSubscription.fromJson(data) as T;
    }
    if (t == _i20.WarningSeverity) {
      return _i20.WarningSeverity.fromJson(data) as T;
    }
    if (t == _i21.WarningSource) {
      return _i21.WarningSource.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.BudgetEntry?>()) {
      return (data != null ? _i5.BudgetEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ChecklistCategory?>()) {
      return (data != null ? _i6.ChecklistCategory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.ChecklistItem?>()) {
      return (data != null ? _i7.ChecklistItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.ChecklistTemplate?>()) {
      return (data != null ? _i8.ChecklistTemplate.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Household?>()) {
      return (data != null ? _i9.Household.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.HouseholdException?>()) {
      return (data != null ? _i10.HouseholdException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.HouseholdExceptionReason?>()) {
      return (data != null
              ? _i11.HouseholdExceptionReason.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i12.HouseholdMember?>()) {
      return (data != null ? _i12.HouseholdMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.HouseholdMembershipInfo?>()) {
      return (data != null ? _i13.HouseholdMembershipInfo.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.HouseholdRole?>()) {
      return (data != null ? _i14.HouseholdRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.InventoryItem?>()) {
      return (data != null ? _i15.InventoryItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.InventoryItemCategory?>()) {
      return (data != null ? _i16.InventoryItemCategory.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.Warning?>()) {
      return (data != null ? _i17.Warning.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.WarningRegionKind?>()) {
      return (data != null ? _i18.WarningRegionKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.WarningRegionSubscription?>()) {
      return (data != null
              ? _i19.WarningRegionSubscription.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.WarningSeverity?>()) {
      return (data != null ? _i20.WarningSeverity.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.WarningSource?>()) {
      return (data != null ? _i21.WarningSource.fromJson(data) : null) as T;
    }
    if (t == List<_i22.BudgetEntry>) {
      return (data as List)
              .map((e) => deserialize<_i22.BudgetEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i23.ChecklistTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i23.ChecklistTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i24.ChecklistItem>) {
      return (data as List)
              .map((e) => deserialize<_i24.ChecklistItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i25.HouseholdMember>) {
      return (data as List)
              .map((e) => deserialize<_i25.HouseholdMember>(e))
              .toList()
          as T;
    }
    if (t == List<_i26.WarningRegionSubscription>) {
      return (data as List)
              .map((e) => deserialize<_i26.WarningRegionSubscription>(e))
              .toList()
          as T;
    }
    if (t == List<_i27.InventoryItem>) {
      return (data as List)
              .map((e) => deserialize<_i27.InventoryItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i28.Warning>) {
      return (data as List).map((e) => deserialize<_i28.Warning>(e)).toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.BudgetEntry => 'BudgetEntry',
      _i6.ChecklistCategory => 'ChecklistCategory',
      _i7.ChecklistItem => 'ChecklistItem',
      _i8.ChecklistTemplate => 'ChecklistTemplate',
      _i9.Household => 'Household',
      _i10.HouseholdException => 'HouseholdException',
      _i11.HouseholdExceptionReason => 'HouseholdExceptionReason',
      _i12.HouseholdMember => 'HouseholdMember',
      _i13.HouseholdMembershipInfo => 'HouseholdMembershipInfo',
      _i14.HouseholdRole => 'HouseholdRole',
      _i15.InventoryItem => 'InventoryItem',
      _i16.InventoryItemCategory => 'InventoryItemCategory',
      _i17.Warning => 'Warning',
      _i18.WarningRegionKind => 'WarningRegionKind',
      _i19.WarningRegionSubscription => 'WarningRegionSubscription',
      _i20.WarningSeverity => 'WarningSeverity',
      _i21.WarningSource => 'WarningSource',
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
      case _i5.BudgetEntry():
        return 'BudgetEntry';
      case _i6.ChecklistCategory():
        return 'ChecklistCategory';
      case _i7.ChecklistItem():
        return 'ChecklistItem';
      case _i8.ChecklistTemplate():
        return 'ChecklistTemplate';
      case _i9.Household():
        return 'Household';
      case _i10.HouseholdException():
        return 'HouseholdException';
      case _i11.HouseholdExceptionReason():
        return 'HouseholdExceptionReason';
      case _i12.HouseholdMember():
        return 'HouseholdMember';
      case _i13.HouseholdMembershipInfo():
        return 'HouseholdMembershipInfo';
      case _i14.HouseholdRole():
        return 'HouseholdRole';
      case _i15.InventoryItem():
        return 'InventoryItem';
      case _i16.InventoryItemCategory():
        return 'InventoryItemCategory';
      case _i17.Warning():
        return 'Warning';
      case _i18.WarningRegionKind():
        return 'WarningRegionKind';
      case _i19.WarningRegionSubscription():
        return 'WarningRegionSubscription';
      case _i20.WarningSeverity():
        return 'WarningSeverity';
      case _i21.WarningSource():
        return 'WarningSource';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
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
      return deserialize<_i5.BudgetEntry>(data['data']);
    }
    if (dataClassName == 'ChecklistCategory') {
      return deserialize<_i6.ChecklistCategory>(data['data']);
    }
    if (dataClassName == 'ChecklistItem') {
      return deserialize<_i7.ChecklistItem>(data['data']);
    }
    if (dataClassName == 'ChecklistTemplate') {
      return deserialize<_i8.ChecklistTemplate>(data['data']);
    }
    if (dataClassName == 'Household') {
      return deserialize<_i9.Household>(data['data']);
    }
    if (dataClassName == 'HouseholdException') {
      return deserialize<_i10.HouseholdException>(data['data']);
    }
    if (dataClassName == 'HouseholdExceptionReason') {
      return deserialize<_i11.HouseholdExceptionReason>(data['data']);
    }
    if (dataClassName == 'HouseholdMember') {
      return deserialize<_i12.HouseholdMember>(data['data']);
    }
    if (dataClassName == 'HouseholdMembershipInfo') {
      return deserialize<_i13.HouseholdMembershipInfo>(data['data']);
    }
    if (dataClassName == 'HouseholdRole') {
      return deserialize<_i14.HouseholdRole>(data['data']);
    }
    if (dataClassName == 'InventoryItem') {
      return deserialize<_i15.InventoryItem>(data['data']);
    }
    if (dataClassName == 'InventoryItemCategory') {
      return deserialize<_i16.InventoryItemCategory>(data['data']);
    }
    if (dataClassName == 'Warning') {
      return deserialize<_i17.Warning>(data['data']);
    }
    if (dataClassName == 'WarningRegionKind') {
      return deserialize<_i18.WarningRegionKind>(data['data']);
    }
    if (dataClassName == 'WarningRegionSubscription') {
      return deserialize<_i19.WarningRegionSubscription>(data['data']);
    }
    if (dataClassName == 'WarningSeverity') {
      return deserialize<_i20.WarningSeverity>(data['data']);
    }
    if (dataClassName == 'WarningSource') {
      return deserialize<_i21.WarningSource>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i5.BudgetEntry:
        return _i5.BudgetEntry.t;
      case _i7.ChecklistItem:
        return _i7.ChecklistItem.t;
      case _i8.ChecklistTemplate:
        return _i8.ChecklistTemplate.t;
      case _i9.Household:
        return _i9.Household.t;
      case _i12.HouseholdMember:
        return _i12.HouseholdMember.t;
      case _i15.InventoryItem:
        return _i15.InventoryItem.t;
      case _i17.Warning:
        return _i17.Warning.t;
      case _i19.WarningRegionSubscription:
        return _i19.WarningRegionSubscription.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'preppsuite';

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
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
