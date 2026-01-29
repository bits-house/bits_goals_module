import 'package:bits_goals_module/src/core/data/extensions/map_parsing_extension.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:equatable/equatable.dart';

// DO NOT DELETE OR EDIT LEGACY/OLD SCHEMAS AND NAMES.
// create a new version instead
// and ADD LEGACY KEYS IN PARSING EXTENSION.
class ActionLogRemoteSchemaV1 {
  static const int version = 1;

  static const String id = 'id';
  static const String occurredAt = 'occurred_at';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userDisplayName = 'user_display_name';
  static const String userRoleName = 'user_role_name';
  static const String userIpAddress = 'user_ip_address';
  static const String userDeviceInfo = 'user_device_info';
  static const String appVersion = 'app_version';
  static const String requiredPermission = 'required_permission';
  static const String actionType = 'action_type';
  static const String useCaseId = 'use_case_id';
  static const String oldDataMapped = 'old_data_mapped';
  static const String newDataMapped = 'new_data_mapped';
  static const String schemaVersion = 'schema_version';
}

/// Data Transfer Object (DTO) for ActionLog serialization/deserialization.
///
/// Converts between domain entities and remote API representations.
/// Flattens nested value objects for JSON serialization.
class ActionLogModel extends Equatable {
  // ===========================
  // Identifier & Timestamp
  // ===========================

  /// Unique identifier for this audit log entry (UUID v7).
  final IdUuidV7 id;

  /// Timestamp when the action occurred (milliseconds since epoch).
  /// Nullable because backend generates this value server-side.
  final int? occurredAtMillis;

  // ===========================
  // User Context (Who & Where)
  // ===========================

  /// The user who performed the action (UID extracted from LoggedInUser).
  final String userId;

  /// Email address of the user who performed the action.
  final String userEmail;

  /// Display name of the user who performed the action.
  final String userDisplayName;

  /// Role name of the user who performed the action.
  final String userRoleName;

  /// IP address from which the action was initiated.
  final String userIpAddress;

  /// Device information (platform, OS version, etc) where action originated.
  final String userDeviceInfo;

  /// Application version when the action was performed.
  final String appVersion;

  // ===========================
  // Action Context (What & How)
  // ===========================

  /// Permission required to perform this action.
  final String requiredPermission;

  /// Type of action performed (create, update, delete, etc).
  final String actionType;

  /// Use case identifier that triggered this action.
  final String useCaseId;

  // ===========================
  // Data Snapshots
  // ===========================

  /// Previous state of the modified entity (before the action).
  /// Nullable for create operations where no previous state exists.
  final Map<String, dynamic>? oldDataMapped;

  /// Current state of the modified entity (after the action).
  /// Always present, never empty (represents the action result).
  final Map<String, dynamic> newDataMapped;

  // ===========================
  // Schema Management
  // ===========================

  /// Schema version for backward compatibility in deserialization.
  final int schemaVersion;

  // ===========================
  // Constructor
  // ===========================

  const ActionLogModel._({
    required this.id,
    required this.occurredAtMillis,
    required this.userId,
    required this.userEmail,
    required this.userDisplayName,
    required this.userRoleName,
    required this.userIpAddress,
    required this.userDeviceInfo,
    required this.appVersion,
    required this.requiredPermission,
    required this.actionType,
    required this.useCaseId,
    required this.oldDataMapped,
    required this.newDataMapped,
    required this.schemaVersion,
  });

  // ===========================
  // Factories - Conversion
  // ===========================

  /// Creates a model from domain entity.
  ///
  /// Extracts primitives from nested value objects for serialization.
  /// - LoggedInUser → uid, email.value, displayName, roleName
  /// - IpAddress, DeviceInfo, AppVersion → .value properties
  /// - GoalsModulePermission, ActionType → .name (enum name)
  /// - DateTime → millisecondsSinceEpoch (nullable)
  factory ActionLogModel.fromEntity(ActionLog entity) {
    return ActionLogModel._(
      id: entity.id,
      occurredAtMillis: entity.occurredAt?.millisecondsSinceEpoch,
      userId: entity.user.uid,
      userEmail: entity.user.email.value,
      userDisplayName: entity.user.displayName,
      userRoleName: entity.user.roleName,
      userIpAddress: entity.userIpAddress.value,
      userDeviceInfo: entity.userDeviceInfo.value,
      appVersion: entity.appVersion.value,
      requiredPermission: entity.requiredPermission.name,
      actionType: entity.actionType.name,
      useCaseId: entity.useCaseId,
      oldDataMapped: entity.oldDataMapped,
      newDataMapped: entity.newDataMapped,
      schemaVersion: 1,
    );
  }

  /// Parses a model from Firestore JSON map.
  ///
  /// Handles Firestore-specific data formats:
  /// - Timestamp: Extracts from Firestore Timestamp object
  ///   Format: {_seconds: 1234567890, _nanoseconds: 123456789}
  ///   Or direct milliseconds as int/double
  /// - Maps: Safe type casting for dynamic JSON with null-safety
  /// - Optional fields: occurredAt, oldDataMapped default to null/empty
  ///
  /// Throws FormatException on parsing errors with detailed context.
  factory ActionLogModel.fromMap(Map<String, dynamic> map) {
    try {
      final idString = map.getString(
        key: ActionLogRemoteSchemaV1.id,
      );

      final occurredAtMillis = map.getFirestoreTimestamp(
        key: ActionLogRemoteSchemaV1.occurredAt,
        defaultValue: null,
      );

      final userId = map.getString(
        key: ActionLogRemoteSchemaV1.userId,
      );

      final userEmail = map.getString(
        key: ActionLogRemoteSchemaV1.userEmail,
      );

      final userDisplayName = map.getString(
        key: ActionLogRemoteSchemaV1.userDisplayName,
      );

      final userRoleName = map.getString(
        key: ActionLogRemoteSchemaV1.userRoleName,
      );

      final userIpAddress = map.getString(
        key: ActionLogRemoteSchemaV1.userIpAddress,
      );

      final userDeviceInfo = map.getString(
        key: ActionLogRemoteSchemaV1.userDeviceInfo,
      );

      final appVersion = map.getString(
        key: ActionLogRemoteSchemaV1.appVersion,
      );

      final requiredPermission = map.getString(
        key: ActionLogRemoteSchemaV1.requiredPermission,
      );

      final actionType = map.getString(
        key: ActionLogRemoteSchemaV1.actionType,
      );

      final useCaseId = map.getString(
        key: ActionLogRemoteSchemaV1.useCaseId,
      );

      final oldDataMapped =
          map.containsKey(ActionLogRemoteSchemaV1.oldDataMapped)
              ? (map[ActionLogRemoteSchemaV1.oldDataMapped] as Map?)
                  ?.cast<String, dynamic>()
              : null;

      final newDataMappedRaw =
          map.containsKey(ActionLogRemoteSchemaV1.newDataMapped)
              ? (map[ActionLogRemoteSchemaV1.newDataMapped] as Map?)
                  ?.cast<String, dynamic>()
              : <String, dynamic>{};
      final newDataMapped = newDataMappedRaw ?? <String, dynamic>{};

      final schemaVer = map.getInt(
        key: ActionLogRemoteSchemaV1.schemaVersion,
      );

      return ActionLogModel._(
        id: IdUuidV7.fromString(idString),
        occurredAtMillis: occurredAtMillis,
        userId: userId,
        userEmail: userEmail,
        userDisplayName: userDisplayName,
        userRoleName: userRoleName,
        userIpAddress: userIpAddress,
        userDeviceInfo: userDeviceInfo,
        appVersion: appVersion,
        requiredPermission: requiredPermission,
        actionType: actionType,
        useCaseId: useCaseId,
        oldDataMapped: oldDataMapped,
        newDataMapped: newDataMapped,
        schemaVersion: schemaVer,
      );
    } catch (e) {
      throw FormatException(
        'Exception while parsing ActionLogModel fromMap: $e',
      );
    }
  }

  // ===========================
  // Serialization
  // ===========================

  Map<String, dynamic> toMap() {
    return {
      ActionLogRemoteSchemaV1.id: id.value,
      ActionLogRemoteSchemaV1.occurredAt: occurredAtMillis,
      ActionLogRemoteSchemaV1.userId: userId,
      ActionLogRemoteSchemaV1.userEmail: userEmail,
      ActionLogRemoteSchemaV1.userDisplayName: userDisplayName,
      ActionLogRemoteSchemaV1.userRoleName: userRoleName,
      ActionLogRemoteSchemaV1.userIpAddress: userIpAddress,
      ActionLogRemoteSchemaV1.userDeviceInfo: userDeviceInfo,
      ActionLogRemoteSchemaV1.appVersion: appVersion,
      ActionLogRemoteSchemaV1.requiredPermission: requiredPermission,
      ActionLogRemoteSchemaV1.actionType: actionType,
      ActionLogRemoteSchemaV1.useCaseId: useCaseId,
      ActionLogRemoteSchemaV1.oldDataMapped: oldDataMapped,
      ActionLogRemoteSchemaV1.newDataMapped: newDataMapped,
      ActionLogRemoteSchemaV1.schemaVersion: schemaVersion,
    };
  }

  // ===========================
  // Equatable Overrides
  // ===========================

  @override
  List<Object?> get props => [
        id,
        occurredAtMillis,
        userId,
        userEmail,
        userDisplayName,
        userRoleName,
        userIpAddress,
        userDeviceInfo,
        appVersion,
        requiredPermission,
        actionType,
        useCaseId,
        oldDataMapped,
        newDataMapped,
        schemaVersion,
      ];

  @override
  bool get stringify => true;
}
