import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'push_sender.dart';

/// Sends notifications through Firebase Cloud Messaging's HTTP v1 API.
///
/// iOS goes through here too. Firebase forwards to APNs using the APNs
/// key uploaded to the Firebase project, which keeps the server to a
/// single credential and a single code path; the price is that the shape
/// of the message still has to be spelled out per platform, because APNs
/// will not display anything it does not find under `aps`.
class FcmSender implements PushSender {
  FcmSender({
    required String projectId,
    required Future<http.Client> Function() authClientFactory,
  }) : _projectId = projectId,
       _authClientFactory = authClientFactory;

  /// Builds a sender from a Google service-account key.
  ///
  /// Returns null when [serviceAccountJson] is absent or unusable, so a
  /// server without credentials starts normally with push switched off
  /// rather than refusing to boot. The project id is read out of the key
  /// itself — there is no second thing to configure and no way for the two
  /// to disagree.
  static FcmSender? fromServiceAccountJson(String? serviceAccountJson) {
    if (serviceAccountJson == null || serviceAccountJson.trim().isEmpty) {
      return null;
    }

    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(serviceAccountJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final projectId = parsed['project_id'];
    if (projectId is! String || projectId.isEmpty) return null;

    final credentials = auth.ServiceAccountCredentials.fromJson(parsed);

    // The auth client refreshes its own access token, so it is built once
    // and kept; building it per send would mean a token exchange for every
    // notification.
    http.Client? cached;
    return FcmSender(
      projectId: projectId,
      authClientFactory: () async =>
          cached ??= await auth.clientViaServiceAccount(credentials, _scopes),
    );
  }

  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  final String _projectId;
  final Future<http.Client> Function() _authClientFactory;

  @override
  bool get isConfigured => true;

  @override
  Future<PushDeliveryStatus> send(
    Session session, {
    required PushDevice device,
    required PushMessage message,
  }) async {
    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
    );

    try {
      final client = await _authClientFactory();
      final response = await client.post(
        url,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'message': buildFcmMessage(device: device, message: message),
        }),
      );

      if (response.statusCode == 200) return PushDeliveryStatus.delivered;

      if (isDeadTokenResponse(response.statusCode, response.body)) {
        session.log(
          'FCM rejected token for device ${device.id}, removing it',
          level: LogLevel.info,
        );
        return PushDeliveryStatus.tokenDead;
      }

      session.log(
        'FCM send failed (${response.statusCode}): ${response.body}',
        level: LogLevel.warning,
      );
      return PushDeliveryStatus.failed;
    } catch (e, stackTrace) {
      session.log(
        'FCM send threw: $e',
        level: LogLevel.warning,
        exception: e,
        stackTrace: stackTrace,
      );
      return PushDeliveryStatus.failed;
    }
  }
}

/// The `message` object of an FCM HTTP v1 request.
///
/// Split out as a pure function so the payload can be asserted in a test
/// without a network or a credential — the parts that are easy to get
/// subtly wrong (the APNs block, the Android channel id) are exactly the
/// parts whose absence shows up only on a real device.
Map<String, dynamic> buildFcmMessage({
  required PushDevice device,
  required PushMessage message,
}) {
  return {
    'token': device.token,
    'notification': {'title': message.title, 'body': message.body},
    if (message.data.isNotEmpty) 'data': message.data,
    switch (device.platform) {
      // `channel_id` must name a channel the app created, or Android 8+
      // drops the notification silently — this one is created by
      // `NotificationService.showWarningNotification`.
      PushPlatform.android => 'android',
      PushPlatform.ios => 'apns',
    }: switch (device.platform) {
      PushPlatform.android => {
        'priority': 'HIGH',
        'notification': {
          'channel_id': 'warnings',
          'default_sound': true,
        },
      },
      // Priority 10 is "deliver now"; without it APNs is free to hold the
      // message back to save battery, which is not what a civil-protection
      // warning is for.
      PushPlatform.ios => {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {
            'alert': {'title': message.title, 'body': message.body},
            'sound': 'default',
          },
        },
      },
    },
  };
}

/// Whether a non-200 FCM response means the token is permanently gone.
///
/// FCM signals this two ways and both have to be caught: `UNREGISTERED`
/// (404) for a token that was valid and no longer is, and
/// `INVALID_ARGUMENT` (400) for one that never was. Everything else —
/// quota, 5xx, an expired credential — is transient and must not delete
/// the device.
bool isDeadTokenResponse(int statusCode, String body) {
  if (statusCode != 404 && statusCode != 400) return false;

  try {
    final error = (jsonDecode(body) as Map<String, dynamic>)['error'];
    if (error is! Map<String, dynamic>) return false;
    final status = error['status'];
    return status == 'UNREGISTERED' || status == 'INVALID_ARGUMENT';
  } catch (_) {
    return false;
  }
}
