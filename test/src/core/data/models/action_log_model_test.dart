import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_type.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/email.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/policies/goals_module_permission.dart';

// ===========================
// Mock Definitions
// ===========================

class MockActionLog extends Mock implements ActionLog {}

class MockLoggedInUser extends Mock implements LoggedInUser {}

// ===========================
// Fake Implementations
// ===========================

class FakeActionLog extends Fake implements ActionLog {
  @override
  IdUuidV7 get uuidV7 => IdUuidV7.generate();

  @override
  DateTime? get occurredAt => null;

  @override
  LoggedInUser get user => FakeLoggedInUser();

  @override
  IpAddress get userIpAddress => FakeIpAddress();

  @override
  DeviceInfo get userDeviceInfo => FakeDeviceInfo();

  @override
  AppVersion get appVersion => FakeAppVersion();

  @override
  GoalsModulePermission get requiredPermission =>
      GoalsModulePermission.values.first;

  @override
  ActionType get actionType => ActionType.values.first;

  @override
  String get useCaseId => 'test-use-case-id';

  @override
  Map<String, dynamic>? get oldDataMapped => null;

  @override
  Map<String, dynamic> get newDataMapped => {'result': 'success'};
}

class FakeLoggedInUser extends Fake implements LoggedInUser {
  @override
  String get uid => 'test-user-123';

  @override
  String get displayName => 'Test User';

  @override
  String get roleName => 'admin';

  @override
  Email get email => Email('test@example.com');
}

class FakeIpAddress extends Fake implements IpAddress {
  @override
  String get value => '192.168.1.1';
}

class FakeDeviceInfo extends Fake implements DeviceInfo {
  @override
  String get value => 'iPhone 13, iOS 15.4';
}

class FakeAppVersion extends Fake implements AppVersion {
  @override
  String get value => '1.0.0';
}

// ===========================
// Helper Functions
// ===========================

ActionLogModel createTestModel({
  String id = '550e8400-e29b-41d4-a716-446655440000',
  int? occurredAt,
  String userId = 'user-123',
  String userEmail = 'test@example.com',
  String userDisplayName = 'Test User',
  String userRoleName = 'admin',
  String userIpAddress = '192.168.1.1',
  String userDeviceInfo = 'iPhone 13',
  String appVersion = '1.0.0',
  String requiredPermission = 'create',
  String actionType = 'create',
  String useCaseId = 'use-case-123',
  Map<String, dynamic>? oldDataMapped,
  Map<String, dynamic>? newDataMapped,
  int schemaVersion = 1,
}) {
  final map = <String, dynamic>{
    'id': id,
    'user_id': userId,
    'user_email': userEmail,
    'user_display_name': userDisplayName,
    'user_role_name': userRoleName,
    'user_ip_address': userIpAddress,
    'user_device_info': userDeviceInfo,
    'app_version': appVersion,
    'required_permission': requiredPermission,
    'action_type': actionType,
    'use_case_id': useCaseId,
    'schema_version': schemaVersion,
  };

  if (occurredAt != null) {
    map['occurred_at'] = occurredAt;
  }
  if (oldDataMapped != null) {
    map['old_data_mapped'] = oldDataMapped;
  }
  if (newDataMapped != null) {
    map['new_data_mapped'] = newDataMapped;
  }

  return ActionLogModel.fromMap(map);
}

// ===========================
// Test Suite
// ===========================

void main() {
  setUpAll(() {
    registerFallbackValue(FakeActionLog());
  });

  group('ActionLogModel.create', () {
    late MockActionLog mockActionLog;

    setUp(() {
      mockActionLog = MockActionLog();

      when(() => mockActionLog.uuidV7).thenReturn(IdUuidV7.generate());
      when(() => mockActionLog.user).thenReturn(FakeLoggedInUser());
      when(() => mockActionLog.userIpAddress).thenReturn(FakeIpAddress());
      when(() => mockActionLog.userDeviceInfo).thenReturn(FakeDeviceInfo());
      when(() => mockActionLog.appVersion).thenReturn(FakeAppVersion());
      when(() => mockActionLog.requiredPermission)
          .thenReturn(GoalsModulePermission.values.first);
      when(() => mockActionLog.actionType).thenReturn(ActionType.values.first);
      when(() => mockActionLog.useCaseId).thenReturn('test-use-case');
      when(() => mockActionLog.oldDataMapped).thenReturn(null);
      when(() => mockActionLog.newDataMapped).thenReturn({'key': 'value'});
    });

    test('should create model from valid ActionLog entity', () {
      final entity = FakeActionLog();

      final model = ActionLogModel.create(entity);

      expect(model, isNotNull);
      expect(model.userId, equals(entity.user.uid));
      expect(model.userEmail, equals(entity.user.email.value));
      expect(model.userDisplayName, equals(entity.user.displayName));
    });

    test('should extract value object properties correctly', () {
      final entity = FakeActionLog();

      final model = ActionLogModel.create(entity);

      expect(model.userIpAddress, equals(entity.userIpAddress.value));
      expect(model.userDeviceInfo, equals(entity.userDeviceInfo.value));
      expect(model.appVersion, equals(entity.appVersion.value));
    });

    test('should convert enum names to string', () {
      final entity = FakeActionLog();

      final model = ActionLogModel.create(entity);

      expect(model.requiredPermission, isA<String>());
      expect(model.actionType, isA<String>());
    });

    test('should set occurredAtMillis to null on creation', () {
      final entity = FakeActionLog();

      final model = ActionLogModel.create(entity);

      expect(model.occurredAtMillis, isNull);
    });

    test('should set schemaVersion to 1', () {
      final entity = FakeActionLog();

      final model = ActionLogModel.create(entity);

      expect(model.schemaVersion, equals(1));
    });

    test('should preserve newDataMapped from entity', () {
      final testData = {'action': 'create', 'status': 'success'};
      when(() => mockActionLog.newDataMapped).thenReturn(testData);

      final model = ActionLogModel.create(mockActionLog);

      expect(model.newDataMapped, equals(testData));
    });

    test('should set oldDataMapped to null when not provided', () {
      when(() => mockActionLog.oldDataMapped).thenReturn(null);

      final model = ActionLogModel.create(mockActionLog);

      expect(model.oldDataMapped, isNull);
    });
  });

  group('ActionLogModel.fromMap', () {
    test('should parse valid Firestore map successfully', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test User',
        'user_role_name': 'admin',
        'user_ip_address': '192.168.1.1',
        'user_device_info': 'iPhone 13',
        'app_version': '1.0.0',
        'required_permission': 'create_goal',
        'action_type': 'create',
        'use_case_id': 'use-case-123',
        'new_data_mapped': {'result': 'success'},
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model, isNotNull);
      expect(model.userId, equals('user-123'));
      expect(model.userEmail, equals('test@example.com'));
    });

    test('should parse all required string fields', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-456',
        'user_email': 'admin@example.com',
        'user_display_name': 'Admin User',
        'user_role_name': 'superAdmin',
        'user_ip_address': '10.0.0.1',
        'user_device_info': 'Android 12',
        'app_version': '2.1.0',
        'required_permission': 'delete_goal',
        'action_type': 'delete',
        'use_case_id': 'delete-case-789',
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.userId, equals('user-456'));
      expect(model.userRoleName, equals('superAdmin'));
      expect(model.userIpAddress, equals('10.0.0.1'));
      expect(model.appVersion, equals('2.1.0'));
    });

    test('should handle Firestore Timestamp with seconds and nanoseconds', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'occurred_at': {'_seconds': 1234567890, '_nanoseconds': 123456789},
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.occurredAtMillis, equals(1234567890000));
    });

    test('should handle direct milliseconds timestamp', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'occurred_at': 1609459200000,
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.occurredAtMillis, equals(1609459200000));
    });

    test('should handle null occurredAt field', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.occurredAtMillis, isNull);
    });

    test('should parse oldDataMapped when present', () {
      final oldData = {'previousKey': 'previousValue'};
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'old_data_mapped': oldData,
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.oldDataMapped, equals(oldData));
    });

    test('should parse newDataMapped when present', () {
      final newData = {'newKey': 'newValue'};
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'new_data_mapped': newData,
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.newDataMapped, equals(newData));
    });

    test('should handle null coalescing when newDataMapped is null', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'new_data_mapped': null,
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.newDataMapped, isEmpty);
    });

    test('should handle missing newDataMapped with empty map', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.newDataMapped, isEmpty);
    });

    test('should throw FormatException on missing required field', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        // Missing user_email
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'schema_version': 1,
      };

      expect(
        () => ActionLogModel.fromMap(map),
        throwsA(isA<FormatException>()),
      );
    });

    test('should throw FormatException on invalid UUID format', () {
      final map = <String, dynamic>{
        'id': 'invalid-uuid-format',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'schema_version': 1,
      };

      expect(
        () => ActionLogModel.fromMap(map),
        throwsA(isA<FormatException>()),
      );
    });

    test('should throw FormatException on missing schema_version', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        // Missing schema_version
      };

      expect(
        () => ActionLogModel.fromMap(map),
        throwsA(isA<FormatException>()),
      );
    });

    test('should parse different schema versions', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'schema_version': 2,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.schemaVersion, equals(2));
    });
  });

  group('ActionLogModel.toMap', () {
    test('should serialize all fields correctly', () {
      final model = createTestModel(
        occurredAt: 1609459200000,
        oldDataMapped: {'old': 'data'},
        newDataMapped: {'new': 'data'},
      );

      final map = model.toMap();

      expect(map['id'], isNotNull);
      expect(map['occurred_at'], equals(1609459200000));
      expect(map['user_id'], equals('user-123'));
      expect(map['user_email'], equals('test@example.com'));
      expect(map['schema_version'], equals(1));
    });

    test('should serialize null occurredAtMillis', () {
      final model = createTestModel(
        newDataMapped: {'result': 'ok'},
      );

      final map = model.toMap();

      expect(map['occurred_at'], isNull);
    });

    test('should serialize null oldDataMapped', () {
      final model = createTestModel(
        newDataMapped: {'result': 'ok'},
      );

      final map = model.toMap();

      expect(map['old_data_mapped'], isNull);
    });

    test('should contain all schema keys', () {
      final model = createTestModel();

      final map = model.toMap();

      expect(map.containsKey('id'), isTrue);
      expect(map.containsKey('user_id'), isTrue);
      expect(map.containsKey('user_email'), isTrue);
      expect(map.containsKey('user_display_name'), isTrue);
      expect(map.containsKey('user_role_name'), isTrue);
      expect(map.containsKey('user_ip_address'), isTrue);
      expect(map.containsKey('user_device_info'), isTrue);
      expect(map.containsKey('app_version'), isTrue);
      expect(map.containsKey('required_permission'), isTrue);
      expect(map.containsKey('action_type'), isTrue);
      expect(map.containsKey('use_case_id'), isTrue);
      expect(map.containsKey('old_data_mapped'), isTrue);
      expect(map.containsKey('new_data_mapped'), isTrue);
      expect(map.containsKey('schema_version'), isTrue);
    });
  });

  group('ActionLogModel equality', () {
    test('should be equal when all props match', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'occurred_at': 1609459200000,
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test User',
        'user_role_name': 'admin',
        'user_ip_address': '192.168.1.1',
        'user_device_info': 'iPhone 13',
        'app_version': '1.0.0',
        'required_permission': 'create',
        'action_type': 'create',
        'use_case_id': 'use-case-123',
        'old_data_mapped': {'old': 'data'},
        'new_data_mapped': {'new': 'data'},
        'schema_version': 1,
      };

      final model1 = ActionLogModel.fromMap(map);
      final model2 = ActionLogModel.fromMap(map);

      expect(model1, equals(model2));
    });

    test('should not be equal when userId differs', () {
      final map1 = createTestModel(userId: 'user-123').toMap();
      final map2 = createTestModel(userId: 'different-user').toMap();

      final model1 = ActionLogModel.fromMap(map1);
      final model2 = ActionLogModel.fromMap(map2);

      expect(model1, isNot(equals(model2)));
    });

    test('should have props list with 15 elements', () {
      final model = createTestModel();

      expect(model.props.length, equals(15));
    });

    test('should have stringify enabled', () {
      final model = createTestModel();

      expect(model.stringify, isTrue);
    });
  });

  group('ActionLogModel roundtrip', () {
    test('should preserve data through toMap and fromMap', () {
      final original = createTestModel(
        occurredAt: 1609459200000,
        oldDataMapped: {'old': 'value'},
        newDataMapped: {'new': 'value'},
      );

      final serialized = original.toMap();
      final restored = ActionLogModel.fromMap(serialized);

      expect(restored.userId, equals(original.userId));
      expect(restored.userEmail, equals(original.userEmail));
      expect(restored.userDisplayName, equals(original.userDisplayName));
      expect(restored.schemaVersion, equals(original.schemaVersion));
    });

    test('should handle roundtrip with null oldDataMapped', () {
      final original = createTestModel(
        newDataMapped: {'result': 'success'},
      );

      final serialized = original.toMap();
      final restored = ActionLogModel.fromMap(serialized);

      expect(restored.oldDataMapped, isNull);
      expect(restored.newDataMapped, equals(original.newDataMapped));
    });
  });

  group('ActionLogModel edge cases', () {
    test('should handle empty maps in newDataMapped', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'new_data_mapped': {},
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.newDataMapped, isEmpty);
    });

    test('should handle nested maps in oldDataMapped', () {
      final nestedData = {
        'user': {'id': '123', 'name': 'Test'},
        'metadata': {'timestamp': 1234567890},
      };
      final map = createTestModel(
        oldDataMapped: nestedData,
      ).toMap();

      final model = ActionLogModel.fromMap(map);

      expect(model.oldDataMapped, equals(nestedData));
    });

    test('should handle special characters in strings', () {
      final map = createTestModel(
        userId: 'user-@#\$%',
        userEmail: 'test+alias@example.com',
        userDisplayName: 'Test "User" & Friends',
      ).toMap();

      final model = ActionLogModel.fromMap(map);

      expect(model.userId, contains('@'));
      expect(model.userEmail, contains('+'));
      expect(model.userDisplayName, contains('"'));
    });

    test('should handle large timestamp values', () {
      const largeTimestamp = 9223372036854775807;
      final model = createTestModel(occurredAt: largeTimestamp);

      expect(model.occurredAtMillis, equals(largeTimestamp));
    });

    test('should handle missing oldDataMapped as null', () {
      final map = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'user_email': 'test@example.com',
        'user_display_name': 'Test',
        'user_role_name': 'user',
        'user_ip_address': '127.0.0.1',
        'user_device_info': 'Web',
        'app_version': '1.0.0',
        'required_permission': 'read',
        'action_type': 'read',
        'use_case_id': 'read-case',
        'schema_version': 1,
      };

      final model = ActionLogModel.fromMap(map);

      expect(model.oldDataMapped, isNull);
    });
  });
}
