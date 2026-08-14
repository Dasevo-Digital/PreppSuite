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
import '../../warnings/models/warning_source.dart' as _i2;
import '../../warnings/models/warning_severity.dart' as _i3;

/// A normalized civil-protection/weather warning, upserted by the
/// self-rescheduling poll in `warning_poll_future_call.dart`. Read-only
/// from the client's perspective — delivered via a plain pull, never
/// through the generic push/pull sync used by household-editable entities,
/// since warnings are entirely server-generated.
abstract class Warning implements _i1.SerializableModel {
  Warning._({
    this.id,
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
    required this.rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Warning({
    _i1.UuidValue? id,
    required _i2.WarningSource source,
    required String externalId,
    required String countryCode,
    String? regionKey,
    required _i3.WarningSeverity severity,
    required String eventType,
    required String headline,
    String? description,
    required DateTime effective,
    DateTime? expires,
    required DateTime sent,
    required String rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _WarningImpl;

  factory Warning.fromJson(Map<String, dynamic> jsonSerialization) {
    return Warning(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      source: _i2.WarningSource.fromJson(
        (jsonSerialization['source'] as String),
      ),
      externalId: jsonSerialization['externalId'] as String,
      countryCode: jsonSerialization['countryCode'] as String,
      regionKey: jsonSerialization['regionKey'] as String?,
      severity: _i3.WarningSeverity.fromJson(
        (jsonSerialization['severity'] as String),
      ),
      eventType: jsonSerialization['eventType'] as String,
      headline: jsonSerialization['headline'] as String,
      description: jsonSerialization['description'] as String?,
      effective: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['effective'],
      ),
      expires: jsonSerialization['expires'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expires']),
      sent: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['sent']),
      rawPayload: jsonSerialization['rawPayload'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i2.WarningSource source;

  /// The source's own id for this warning; used with [source] to
  /// deduplicate on upsert.
  String externalId;

  /// ISO 3166-1 alpha-2. Scopes which households see this warning.
  String countryCode;

  /// Free-text area description/code from the source feed (BBK state
  /// code, MeteoAlarm EMMA_ID/areaDesc) — informational, not matched
  /// precisely against a household's `regionKey` in v1.
  String? regionKey;

  _i3.WarningSeverity severity;

  /// Free-text event type/category from the source (not a closed
  /// vocabulary — BBK and MeteoAlarm each use their own).
  String eventType;

  String headline;

  String? description;

  /// When the warning takes/took effect.
  DateTime effective;

  /// Null when the source doesn't report an expiry (e.g. BBK's mapData
  /// feed).
  DateTime? expires;

  /// When the source issued/last updated this warning.
  DateTime sent;

  /// The unprocessed source payload as a JSON string, kept for
  /// debugging/future re-parsing.
  String rawPayload;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Warning]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Warning copyWith({
    _i1.UuidValue? id,
    _i2.WarningSource? source,
    String? externalId,
    String? countryCode,
    String? regionKey,
    _i3.WarningSeverity? severity,
    String? eventType,
    String? headline,
    String? description,
    DateTime? effective,
    DateTime? expires,
    DateTime? sent,
    String? rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Warning',
      if (id != null) 'id': id?.toJson(),
      'source': source.toJson(),
      'externalId': externalId,
      'countryCode': countryCode,
      if (regionKey != null) 'regionKey': regionKey,
      'severity': severity.toJson(),
      'eventType': eventType,
      'headline': headline,
      if (description != null) 'description': description,
      'effective': effective.toJson(),
      if (expires != null) 'expires': expires?.toJson(),
      'sent': sent.toJson(),
      'rawPayload': rawPayload,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WarningImpl extends Warning {
  _WarningImpl({
    _i1.UuidValue? id,
    required _i2.WarningSource source,
    required String externalId,
    required String countryCode,
    String? regionKey,
    required _i3.WarningSeverity severity,
    required String eventType,
    required String headline,
    String? description,
    required DateTime effective,
    DateTime? expires,
    required DateTime sent,
    required String rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         source: source,
         externalId: externalId,
         countryCode: countryCode,
         regionKey: regionKey,
         severity: severity,
         eventType: eventType,
         headline: headline,
         description: description,
         effective: effective,
         expires: expires,
         sent: sent,
         rawPayload: rawPayload,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Warning]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Warning copyWith({
    Object? id = _Undefined,
    _i2.WarningSource? source,
    String? externalId,
    String? countryCode,
    Object? regionKey = _Undefined,
    _i3.WarningSeverity? severity,
    String? eventType,
    String? headline,
    Object? description = _Undefined,
    DateTime? effective,
    Object? expires = _Undefined,
    DateTime? sent,
    String? rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Warning(
      id: id is _i1.UuidValue? ? id : this.id,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      countryCode: countryCode ?? this.countryCode,
      regionKey: regionKey is String? ? regionKey : this.regionKey,
      severity: severity ?? this.severity,
      eventType: eventType ?? this.eventType,
      headline: headline ?? this.headline,
      description: description is String? ? description : this.description,
      effective: effective ?? this.effective,
      expires: expires is DateTime? ? expires : this.expires,
      sent: sent ?? this.sent,
      rawPayload: rawPayload ?? this.rawPayload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
