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
import '../auth/email_idp_endpoint.dart' as _i2;
import '../auth/jwt_refresh_endpoint.dart' as _i3;
import '../budget/budget_endpoint.dart' as _i4;
import '../checklists/checklist_endpoint.dart' as _i5;
import '../households/household_endpoint.dart' as _i6;
import '../inventory/inventory_endpoint.dart' as _i7;
import '../warnings/warning_endpoint.dart' as _i8;
import 'package:preppsuite_server/src/generated/budget/models/budget_entry.dart'
    as _i9;
import 'package:preppsuite_server/src/generated/checklists/models/checklist_template.dart'
    as _i10;
import 'package:preppsuite_server/src/generated/checklists/models/checklist_item.dart'
    as _i11;
import 'package:preppsuite_server/src/generated/inventory/models/inventory_item.dart'
    as _i12;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i13;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i14;
import 'package:preppsuite_server/src/generated/future_calls.dart' as _i15;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'emailIdp': _i2.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _i3.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'budget': _i4.BudgetEndpoint()
        ..initialize(
          server,
          'budget',
          null,
        ),
      'checklist': _i5.ChecklistEndpoint()
        ..initialize(
          server,
          'checklist',
          null,
        ),
      'household': _i6.HouseholdEndpoint()
        ..initialize(
          server,
          'household',
          null,
        ),
      'inventory': _i7.InventoryEndpoint()
        ..initialize(
          server,
          'inventory',
          null,
        ),
      'warning': _i8.WarningEndpoint()
        ..initialize(
          server,
          'warning',
          null,
        ),
    };
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'startRegistration': _i1.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _i1.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _i1.ParameterDescription(
              name: 'accountRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _i1.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _i1.ParameterDescription(
              name: 'registrationToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _i1.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _i1.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _i1.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _i1.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _i1.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i3.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['budget'] = _i1.EndpointConnector(
      name: 'budget',
      endpoint: endpoints['budget']!,
      methodConnectors: {
        'pullBudgetChanges': _i1.MethodConnector(
          name: 'pullBudgetChanges',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'since': _i1.ParameterDescription(
              name: 'since',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['budget'] as _i4.BudgetEndpoint).pullBudgetChanges(
                    session,
                    params['householdId'],
                    params['since'],
                  ),
        ),
        'pushBudgetChanges': _i1.MethodConnector(
          name: 'pushBudgetChanges',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'changes': _i1.ParameterDescription(
              name: 'changes',
              type: _i1.getType<List<_i9.BudgetEntry>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['budget'] as _i4.BudgetEndpoint).pushBudgetChanges(
                    session,
                    params['householdId'],
                    params['changes'],
                  ),
        ),
      },
    );
    connectors['checklist'] = _i1.EndpointConnector(
      name: 'checklist',
      endpoint: endpoints['checklist']!,
      methodConnectors: {
        'pullChecklistTemplateChanges': _i1.MethodConnector(
          name: 'pullChecklistTemplateChanges',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'since': _i1.ParameterDescription(
              name: 'since',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['checklist'] as _i5.ChecklistEndpoint)
                  .pullChecklistTemplateChanges(
                    session,
                    params['householdId'],
                    params['since'],
                  ),
        ),
        'pushChecklistTemplateChanges': _i1.MethodConnector(
          name: 'pushChecklistTemplateChanges',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'changes': _i1.ParameterDescription(
              name: 'changes',
              type: _i1.getType<List<_i10.ChecklistTemplate>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['checklist'] as _i5.ChecklistEndpoint)
                  .pushChecklistTemplateChanges(
                    session,
                    params['householdId'],
                    params['changes'],
                  ),
        ),
        'pullChecklistItemChanges': _i1.MethodConnector(
          name: 'pullChecklistItemChanges',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'since': _i1.ParameterDescription(
              name: 'since',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['checklist'] as _i5.ChecklistEndpoint)
                  .pullChecklistItemChanges(
                    session,
                    params['householdId'],
                    params['since'],
                  ),
        ),
        'pushChecklistItemChanges': _i1.MethodConnector(
          name: 'pushChecklistItemChanges',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'changes': _i1.ParameterDescription(
              name: 'changes',
              type: _i1.getType<List<_i11.ChecklistItem>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['checklist'] as _i5.ChecklistEndpoint)
                  .pushChecklistItemChanges(
                    session,
                    params['householdId'],
                    params['changes'],
                  ),
        ),
      },
    );
    connectors['household'] = _i1.EndpointConnector(
      name: 'household',
      endpoint: endpoints['household']!,
      methodConnectors: {
        'createHousehold': _i1.MethodConnector(
          name: 'createHousehold',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'countryCode': _i1.ParameterDescription(
              name: 'countryCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'regionKey': _i1.ParameterDescription(
              name: 'regionKey',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['household'] as _i6.HouseholdEndpoint)
                  .createHousehold(
                    session,
                    name: params['name'],
                    countryCode: params['countryCode'],
                    regionKey: params['regionKey'],
                    displayName: params['displayName'],
                  ),
        ),
        'joinHousehold': _i1.MethodConnector(
          name: 'joinHousehold',
          params: {
            'inviteCode': _i1.ParameterDescription(
              name: 'inviteCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['household'] as _i6.HouseholdEndpoint)
                  .joinHousehold(
                    session,
                    inviteCode: params['inviteCode'],
                    displayName: params['displayName'],
                  ),
        ),
        'getMyHousehold': _i1.MethodConnector(
          name: 'getMyHousehold',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['household'] as _i6.HouseholdEndpoint)
                  .getMyHousehold(session),
        ),
        'listMembers': _i1.MethodConnector(
          name: 'listMembers',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['household'] as _i6.HouseholdEndpoint).listMembers(
                    session,
                    params['householdId'],
                  ),
        ),
        'rotateInviteCode': _i1.MethodConnector(
          name: 'rotateInviteCode',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['household'] as _i6.HouseholdEndpoint)
                  .rotateInviteCode(
                    session,
                    params['householdId'],
                  ),
        ),
      },
    );
    connectors['inventory'] = _i1.EndpointConnector(
      name: 'inventory',
      endpoint: endpoints['inventory']!,
      methodConnectors: {
        'pullInventoryChanges': _i1.MethodConnector(
          name: 'pullInventoryChanges',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'since': _i1.ParameterDescription(
              name: 'since',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['inventory'] as _i7.InventoryEndpoint)
                  .pullInventoryChanges(
                    session,
                    params['householdId'],
                    params['since'],
                  ),
        ),
        'pushInventoryChanges': _i1.MethodConnector(
          name: 'pushInventoryChanges',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'changes': _i1.ParameterDescription(
              name: 'changes',
              type: _i1.getType<List<_i12.InventoryItem>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['inventory'] as _i7.InventoryEndpoint)
                  .pushInventoryChanges(
                    session,
                    params['householdId'],
                    params['changes'],
                  ),
        ),
      },
    );
    connectors['warning'] = _i1.EndpointConnector(
      name: 'warning',
      endpoint: endpoints['warning']!,
      methodConnectors: {
        'pullWarnings': _i1.MethodConnector(
          name: 'pullWarnings',
          params: {
            'householdId': _i1.ParameterDescription(
              name: 'householdId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'since': _i1.ParameterDescription(
              name: 'since',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['warning'] as _i8.WarningEndpoint).pullWarnings(
                    session,
                    params['householdId'],
                    params['since'],
                  ),
        ),
      },
    );
    modules['serverpod_auth_core'] = _i13.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_idp'] = _i14.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _i1.FutureCallDispatch? get futureCalls {
    return _i15.FutureCalls();
  }
}
