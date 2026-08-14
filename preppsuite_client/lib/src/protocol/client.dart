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
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:preppsuite_client/src/protocol/budget/models/budget_entry.dart'
    as _i5;
import 'package:preppsuite_client/src/protocol/checklists/models/checklist_template.dart'
    as _i6;
import 'package:preppsuite_client/src/protocol/checklists/models/checklist_item.dart'
    as _i7;
import 'package:preppsuite_client/src/protocol/households/models/household.dart'
    as _i8;
import 'package:preppsuite_client/src/protocol/households/models/household_membership_info.dart'
    as _i9;
import 'package:preppsuite_client/src/protocol/households/models/household_member.dart'
    as _i10;
import 'package:preppsuite_client/src/protocol/inventory/models/inventory_item.dart'
    as _i11;
import 'package:preppsuite_client/src/protocol/warnings/models/warning.dart'
    as _i12;
import 'protocol.dart' as _i13;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _i3.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// Delta sync for household budget entries. Accessed through
/// `client.budget`.
/// {@category Endpoint}
class EndpointBudget extends _i2.EndpointRef {
  EndpointBudget(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'budget';

  _i3.Future<List<_i5.BudgetEntry>> pullBudgetChanges(
    _i2.UuidValue householdId,
    DateTime since,
  ) => caller.callServerEndpoint<List<_i5.BudgetEntry>>(
    'budget',
    'pullBudgetChanges',
    {
      'householdId': householdId,
      'since': since,
    },
  );

  _i3.Future<List<_i5.BudgetEntry>> pushBudgetChanges(
    _i2.UuidValue householdId,
    List<_i5.BudgetEntry> changes,
  ) => caller.callServerEndpoint<List<_i5.BudgetEntry>>(
    'budget',
    'pushBudgetChanges',
    {
      'householdId': householdId,
      'changes': changes,
    },
  );
}

/// Delta sync for household checklists. Templates and items are synced as
/// two independent entities (same shape as `InventoryEndpoint`) rather than
/// nested, so each can be delta-pulled on its own regardless of whether its
/// counterpart also changed. Accessed through `client.checklist`.
/// {@category Endpoint}
class EndpointChecklist extends _i2.EndpointRef {
  EndpointChecklist(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'checklist';

  _i3.Future<List<_i6.ChecklistTemplate>> pullChecklistTemplateChanges(
    _i2.UuidValue householdId,
    DateTime since,
  ) => caller.callServerEndpoint<List<_i6.ChecklistTemplate>>(
    'checklist',
    'pullChecklistTemplateChanges',
    {
      'householdId': householdId,
      'since': since,
    },
  );

  _i3.Future<List<_i6.ChecklistTemplate>> pushChecklistTemplateChanges(
    _i2.UuidValue householdId,
    List<_i6.ChecklistTemplate> changes,
  ) => caller.callServerEndpoint<List<_i6.ChecklistTemplate>>(
    'checklist',
    'pushChecklistTemplateChanges',
    {
      'householdId': householdId,
      'changes': changes,
    },
  );

  _i3.Future<List<_i7.ChecklistItem>> pullChecklistItemChanges(
    _i2.UuidValue householdId,
    DateTime since,
  ) => caller.callServerEndpoint<List<_i7.ChecklistItem>>(
    'checklist',
    'pullChecklistItemChanges',
    {
      'householdId': householdId,
      'since': since,
    },
  );

  _i3.Future<List<_i7.ChecklistItem>> pushChecklistItemChanges(
    _i2.UuidValue householdId,
    List<_i7.ChecklistItem> changes,
  ) => caller.callServerEndpoint<List<_i7.ChecklistItem>>(
    'checklist',
    'pushChecklistItemChanges',
    {
      'householdId': householdId,
      'changes': changes,
    },
  );
}

/// Household creation/joining and membership management. Accessed through
/// `client.household` on the client side.
/// {@category Endpoint}
class EndpointHousehold extends _i2.EndpointRef {
  EndpointHousehold(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'household';

  /// Creates a new household with the caller as its owner. Fails with
  /// [HouseholdException] ([HouseholdExceptionReason.alreadyInHousehold]) if
  /// the caller already belongs to a household.
  _i3.Future<_i8.Household> createHousehold({
    required String name,
    required String countryCode,
    String? regionKey,
    required String displayName,
  }) => caller.callServerEndpoint<_i8.Household>(
    'household',
    'createHousehold',
    {
      'name': name,
      'countryCode': countryCode,
      'regionKey': regionKey,
      'displayName': displayName,
    },
  );

  /// Joins an existing household using its invite code. Fails with
  /// [HouseholdException] if the code is invalid or the caller already
  /// belongs to a household.
  _i3.Future<_i8.Household> joinHousehold({
    required String inviteCode,
    required String displayName,
  }) => caller.callServerEndpoint<_i8.Household>(
    'household',
    'joinHousehold',
    {
      'inviteCode': inviteCode,
      'displayName': displayName,
    },
  );

  /// Returns the caller's current household and membership, or `null` if
  /// they have not joined or created one yet. Called on app start to decide
  /// whether to show onboarding.
  _i3.Future<_i9.HouseholdMembershipInfo?> getMyHousehold() =>
      caller.callServerEndpoint<_i9.HouseholdMembershipInfo?>(
        'household',
        'getMyHousehold',
        {},
      );

  /// Lists all members of a household the caller belongs to.
  _i3.Future<List<_i10.HouseholdMember>> listMembers(
    _i2.UuidValue householdId,
  ) => caller.callServerEndpoint<List<_i10.HouseholdMember>>(
    'household',
    'listMembers',
    {'householdId': householdId},
  );

  /// Rotates the invite code. Only the household's owner may do this.
  _i3.Future<_i8.Household> rotateInviteCode(_i2.UuidValue householdId) =>
      caller.callServerEndpoint<_i8.Household>(
        'household',
        'rotateInviteCode',
        {'householdId': householdId},
      );
}

/// Delta sync for household inventory items. Accessed through
/// `client.inventory` on the client side.
/// {@category Endpoint}
class EndpointInventory extends _i2.EndpointRef {
  EndpointInventory(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'inventory';

  /// Returns all inventory items (including tombstoned ones) for
  /// [householdId] changed after [since].
  _i3.Future<List<_i11.InventoryItem>> pullInventoryChanges(
    _i2.UuidValue householdId,
    DateTime since,
  ) => caller.callServerEndpoint<List<_i11.InventoryItem>>(
    'inventory',
    'pullInventoryChanges',
    {
      'householdId': householdId,
      'since': since,
    },
  );

  /// Upserts [changes] for [householdId] and returns the canonical
  /// server-side rows (with server-assigned ids and re-stamped
  /// `updatedAt`) so the client can reconcile its local copies.
  _i3.Future<List<_i11.InventoryItem>> pushInventoryChanges(
    _i2.UuidValue householdId,
    List<_i11.InventoryItem> changes,
  ) => caller.callServerEndpoint<List<_i11.InventoryItem>>(
    'inventory',
    'pushInventoryChanges',
    {
      'householdId': householdId,
      'changes': changes,
    },
  );
}

/// Read-only warning pull, scoped to the household's country. Accessed
/// through `client.warning`.
/// {@category Endpoint}
class EndpointWarning extends _i2.EndpointRef {
  EndpointWarning(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'warning';

  _i3.Future<List<_i12.Warning>> pullWarnings(
    _i2.UuidValue householdId,
    DateTime since,
  ) => caller.callServerEndpoint<List<_i12.Warning>>(
    'warning',
    'pullWarnings',
    {
      'householdId': householdId,
      'since': since,
    },
  );
}

class Modules {
  Modules(Client client) {
    auth = _i4.Caller(client);
    serverpod_auth_idp = _i1.Caller(client);
  }

  late final _i4.Caller auth;

  late final _i1.Caller serverpod_auth_idp;
}

class Client extends _i2.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i13.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    budget = EndpointBudget(this);
    checklist = EndpointChecklist(this);
    household = EndpointHousehold(this);
    inventory = EndpointInventory(this);
    warning = EndpointWarning(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointBudget budget;

  late final EndpointChecklist checklist;

  late final EndpointHousehold household;

  late final EndpointInventory inventory;

  late final EndpointWarning warning;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'budget': budget,
    'checklist': checklist,
    'household': household,
    'inventory': inventory,
    'warning': warning,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'auth': modules.auth,
    'serverpod_auth_idp': modules.serverpod_auth_idp,
  };
}
