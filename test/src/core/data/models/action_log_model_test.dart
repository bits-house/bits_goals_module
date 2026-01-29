import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_type.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';

class MockActionLog extends Mock implements ActionLog {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockActionLog());
  });

  group('ActionLogModel', () {
    group('ActionLogModel.fromEntity', () {
      test('should convert ActionLog entity to ActionLogModel with all fields',
          () {
        final mockActionLog = MockActionLog();
        final testId = IdUuidV7.generate();
        final testTimestamp = DateTime(2024, 1, 15, 10, 30, 45);
        final testUser = LoggedInUser.create(
          uid: 'user-123',
          roleName: 'admin',
          email: 'admin@example.com',
          displayName: 'Admin User',
        );
        final testIpAddress = IpAddress('192.168.1.100');
        final testDeviceInfo = DeviceInfo('iPhone 14 Pro, iOS 17.2');
        final testAppVersion = AppVersion('1.5.3');

        when(() => mockActionLog.id).thenReturn(testId);
        when(() => mockActionLog.occurredAt).thenReturn(testTimestamp);
        when(() => mockActionLog.user).thenReturn(testUser);
        when(() => mockActionLog.userIpAddress).thenReturn(testIpAddress);
        when(() => mockActionLog.userDeviceInfo).thenReturn(testDeviceInfo);
        when(() => mockActionLog.appVersion).thenReturn(testAppVersion);
        when(() => mockActionLog.requiredPermission)
            .thenReturn(GoalsModulePermission.manageGlobalGoals);
        when(() => mockActionLog.actionType).thenReturn(ActionType.create);
        when(() => mockActionLog.useCaseId).thenReturn('use-case-001');
        when(() => mockActionLog.oldDataMapped).thenReturn(null);
        when(() => mockActionLog.newDataMapped)
            .thenReturn({'goalId': 'goal-123', 'targetAmount': 100000});

        final model = ActionLogModel.fromEntity(mockActionLog);

        expect(model.id.value, equals(testId.value));
        expect(model.occurredAtMillis,
            equals(testTimestamp.millisecondsSinceEpoch));
        expect(model.userId, equals('user-123'));
        expect(model.userEmail, equals('admin@example.com'));
        expect(model.userDisplayName, equals('Admin User'));
        expect(model.userRoleName, equals('admin'));
        expect(model.userIpAddress, equals('192.168.1.100'));
        expect(model.userDeviceInfo, equals('iPhone 14 Pro, iOS 17.2'));
        expect(model.appVersion, equals('1.5.3'));
        expect(model.requiredPermission, equals('manageGlobalGoals'));
        expect(model.actionType, equals('create'));
        expect(model.useCaseId, equals('use-case-001'));
        expect(model.oldDataMapped, isNull);
        expect(model.newDataMapped,
            equals({'goalId': 'goal-123', 'targetAmount': 100000}));
        expect(model.schemaVersion, equals(1));
      });

      test('should handle null occurredAt timestamp', () {
        final mockActionLog = MockActionLog();
        final testId = IdUuidV7.generate();
        final testUser = LoggedInUser.create(
          uid: 'user-456',
          roleName: 'user',
          email: 'user@example.com',
          displayName: 'Regular User',
        );

        when(() => mockActionLog.id).thenReturn(testId);
        when(() => mockActionLog.occurredAt).thenReturn(null);
        when(() => mockActionLog.user).thenReturn(testUser);
        when(() => mockActionLog.userIpAddress)
            .thenReturn(IpAddress('10.0.0.1'));
        when(() => mockActionLog.userDeviceInfo)
            .thenReturn(DeviceInfo('Android Device'));
        when(() => mockActionLog.appVersion).thenReturn(AppVersion('2.0.0'));
        when(() => mockActionLog.requiredPermission)
            .thenReturn(GoalsModulePermission.none);
        when(() => mockActionLog.actionType).thenReturn(ActionType.update);
        when(() => mockActionLog.useCaseId).thenReturn('use-case-002');
        when(() => mockActionLog.oldDataMapped)
            .thenReturn({'status': 'inactive'});
        when(() => mockActionLog.newDataMapped)
            .thenReturn({'status': 'active'});

        final model = ActionLogModel.fromEntity(mockActionLog);

        expect(model.occurredAtMillis, isNull);
      });

      test('should preserve oldDataMapped when present', () {
        final mockActionLog = MockActionLog();
        final testId = IdUuidV7.generate();
        final testUser = LoggedInUser.create(
          uid: 'user-789',
          roleName: 'editor',
          email: 'editor@example.com',
          displayName: 'Editor User',
        );
        final oldData = {'amount': 50000, 'currency': 'USD'};

        when(() => mockActionLog.id).thenReturn(testId);
        when(() => mockActionLog.occurredAt).thenReturn(DateTime.now());
        when(() => mockActionLog.user).thenReturn(testUser);
        when(() => mockActionLog.userIpAddress)
            .thenReturn(IpAddress('172.16.0.1'));
        when(() => mockActionLog.userDeviceInfo)
            .thenReturn(DeviceInfo('Windows PC'));
        when(() => mockActionLog.appVersion).thenReturn(AppVersion('1.0.0'));
        when(() => mockActionLog.requiredPermission)
            .thenReturn(GoalsModulePermission.none);
        when(() => mockActionLog.actionType).thenReturn(ActionType.delete);
        when(() => mockActionLog.useCaseId).thenReturn('use-case-003');
        when(() => mockActionLog.oldDataMapped).thenReturn(oldData);
        when(() => mockActionLog.newDataMapped).thenReturn({});

        final model = ActionLogModel.fromEntity(mockActionLog);

        expect(model.oldDataMapped, equals(oldData));
      });
    });

    group('ActionLogModel.fromMap', () {
      test('should parse valid map with all required fields', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13 Pro',
          'app_version': '1.2.3',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'old_data_mapped': null,
          'new_data_mapped': {'key': 'value'},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.id.value, equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(model.occurredAtMillis, equals(1705315845000));
        expect(model.userId, equals('user-123'));
        expect(model.userEmail, equals('test@example.com'));
        expect(model.userDisplayName, equals('Test User'));
        expect(model.userRoleName, equals('admin'));
        expect(model.userIpAddress, equals('192.168.1.1'));
        expect(model.userDeviceInfo, equals('iPhone 13 Pro'));
        expect(model.appVersion, equals('1.2.3'));
        expect(model.requiredPermission, equals('manageGlobalGoals'));
        expect(model.actionType, equals('create'));
        expect(model.useCaseId, equals('use-case-001'));
        expect(model.oldDataMapped, isNull);
        expect(model.newDataMapped, equals({'key': 'value'}));
        expect(model.schemaVersion, equals(1));
      });

      test('should handle Firestore timestamp with seconds and nanoseconds',
          () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440001',
          'occurred_at': {'_seconds': 1705315845, '_nanoseconds': 123456789},
          'user_id': 'user-456',
          'user_email': 'user@example.com',
          'user_display_name': 'User Name',
          'user_role_name': 'viewer',
          'user_ip_address': '10.0.0.1',
          'user_device_info': 'Android Phone',
          'app_version': '2.0.0',
          'required_permission': 'none',
          'action_type': 'update',
          'use_case_id': 'use-case-002',
          'old_data_mapped': null,
          'new_data_mapped': {},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.occurredAtMillis, equals(1705315845000));
      });

      test('should handle missing optional timestamp field', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440002',
          'user_id': 'user-789',
          'user_email': 'another@example.com',
          'user_display_name': 'Another User',
          'user_role_name': 'editor',
          'user_ip_address': '172.16.0.1',
          'user_device_info': 'Windows Device',
          'app_version': '1.5.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'delete',
          'use_case_id': 'use-case-003',
          'new_data_mapped': {'deleted': true},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.occurredAtMillis, isNull);
      });

      test('should default newDataMapped to empty map when missing', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440003',
          'occurred_at': 1705315845000,
          'user_id': 'user-111',
          'user_email': 'minimal@example.com',
          'user_display_name': 'Minimal User',
          'user_role_name': 'guest',
          'user_ip_address': '192.168.0.100',
          'user_device_info': 'Web Browser',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'create',
          'use_case_id': 'use-case-004',
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.newDataMapped, equals({}));
      });

      test('should handle oldDataMapped with nested structure', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440004',
          'occurred_at': 1705315845000,
          'user_id': 'user-222',
          'user_email': 'nested@example.com',
          'user_display_name': 'Nested User',
          'user_role_name': 'admin',
          'user_ip_address': '10.20.30.40',
          'user_device_info': 'Tablet Device',
          'app_version': '1.1.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'update',
          'use_case_id': 'use-case-005',
          'old_data_mapped': {
            'nested': {
              'deep': {'value': 123}
            },
            'list': [1, 2, 3],
          },
          'new_data_mapped': {'updated': true},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.oldDataMapped, isNotNull);
        expect(model.oldDataMapped!['nested']['deep']['value'], equals(123));
        expect(model.oldDataMapped!['list'], equals([1, 2, 3]));
      });

      test('should throw FormatException when id is missing', () {
        final map = <String, dynamic>{
          'occurred_at': 1705315845000,
          'user_id': 'user-333',
          'user_email': 'error@example.com',
          'user_display_name': 'Error User',
          'user_role_name': 'viewer',
          'user_ip_address': '127.0.0.1',
          'user_device_info': 'Localhost',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'create',
          'use_case_id': 'use-case-006',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        expect(
          () => ActionLogModel.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException when userId is missing', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440005',
          'occurred_at': 1705315845000,
          'user_email': 'error@example.com',
          'user_display_name': 'Error User',
          'user_role_name': 'viewer',
          'user_ip_address': '127.0.0.1',
          'user_device_info': 'Localhost',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'create',
          'use_case_id': 'use-case-007',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        expect(
          () => ActionLogModel.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException when actionType is missing', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440006',
          'occurred_at': 1705315845000,
          'user_id': 'user-444',
          'user_email': 'error@example.com',
          'user_display_name': 'Error User',
          'user_role_name': 'viewer',
          'user_ip_address': '127.0.0.1',
          'user_device_info': 'Localhost',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'use_case_id': 'use-case-008',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        expect(
          () => ActionLogModel.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException with invalid UUID format', () {
        final map = <String, dynamic>{
          'id': 'not-a-valid-uuid',
          'occurred_at': 1705315845000,
          'user_id': 'user-555',
          'user_email': 'error@example.com',
          'user_display_name': 'Error User',
          'user_role_name': 'viewer',
          'user_ip_address': '127.0.0.1',
          'user_device_info': 'Localhost',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'create',
          'use_case_id': 'use-case-009',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        expect(
          () => ActionLogModel.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle double timestamp conversion', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440007',
          'occurred_at': 1705315845000.5,
          'user_id': 'user-666',
          'user_email': 'double@example.com',
          'user_display_name': 'Double User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.50',
          'user_device_info': 'Mac Device',
          'app_version': '1.2.0',
          'required_permission': 'none',
          'action_type': 'update',
          'use_case_id': 'use-case-010',
          'new_data_mapped': {'timestamp': 'double'},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.occurredAtMillis, equals(1705315845000));
      });

      test('should handle string timestamp conversion', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440008',
          'occurred_at': '1705315845000',
          'user_id': 'user-777',
          'user_email': 'string@example.com',
          'user_display_name': 'String User',
          'user_role_name': 'editor',
          'user_ip_address': '10.10.10.10',
          'user_device_info': 'Linux Device',
          'app_version': '2.1.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'delete',
          'use_case_id': 'use-case-011',
          'new_data_mapped': {'timestamp': 'string'},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.occurredAtMillis, equals(1705315845000));
      });
    });

    group('ActionLogModel.toMap', () {
      test('should serialize model to map with all fields', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'old_data_mapped': null,
          'new_data_mapped': {'key': 'value'},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);
        final serializedMap = model.toMap();

        expect(serializedMap['id'],
            equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(serializedMap['occurred_at'], equals(1705315845000));
        expect(serializedMap['user_id'], equals('user-123'));
        expect(serializedMap['user_email'], equals('test@example.com'));
        expect(serializedMap['user_display_name'], equals('Test User'));
        expect(serializedMap['user_role_name'], equals('admin'));
        expect(serializedMap['user_ip_address'], equals('192.168.1.1'));
        expect(serializedMap['user_device_info'], equals('iPhone 13'));
        expect(serializedMap['app_version'], equals('1.0.0'));
        expect(
            serializedMap['required_permission'], equals('manageGlobalGoals'));
        expect(serializedMap['action_type'], equals('create'));
        expect(serializedMap['use_case_id'], equals('use-case-001'));
        expect(serializedMap['old_data_mapped'], isNull);
        expect(serializedMap['new_data_mapped'], equals({'key': 'value'}));
        expect(serializedMap['schema_version'], equals(1));
      });

      test('should serialize null occurredAtMillis', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440016',
          'user_id': 'user-456',
          'user_email': 'user@example.com',
          'user_display_name': 'User Name',
          'user_role_name': 'viewer',
          'user_ip_address': '10.0.0.1',
          'user_device_info': 'Android',
          'app_version': '2.0.0',
          'required_permission': 'none',
          'action_type': 'update',
          'use_case_id': 'use-case-002',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);
        final serializedMap = model.toMap();

        expect(serializedMap['occurred_at'], isNull);
      });

      test('should serialize complex oldDataMapped', () {
        final oldData = {
          'nested': {
            'deep': {'value': 123}
          },
          'list': [1, 2, 3],
        };
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440017',
          'occurred_at': 1705315845000,
          'user_id': 'user-789',
          'user_email': 'complex@example.com',
          'user_display_name': 'Complex User',
          'user_role_name': 'admin',
          'user_ip_address': '172.16.0.1',
          'user_device_info': 'iPad',
          'app_version': '1.5.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'delete',
          'use_case_id': 'use-case-003',
          'old_data_mapped': oldData,
          'new_data_mapped': {'deleted': true},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);
        final serializedMap = model.toMap();

        expect(serializedMap['old_data_mapped'], equals(oldData));
      });
    });

    group('ActionLogModel round-trip serialization', () {
      test('should serialize and deserialize without data loss', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440018',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'roundtrip@example.com',
          'user_display_name': 'Round Trip User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 14',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'old_data_mapped': {'old': 'state'},
          'new_data_mapped': {'new': 'state'},
          'schema_version': 1,
        };

        final originalModel = ActionLogModel.fromMap(map);
        final serializedMap = originalModel.toMap();
        final deserializedModel = ActionLogModel.fromMap(serializedMap);

        expect(deserializedModel.id.value, equals(originalModel.id.value));
        expect(deserializedModel.occurredAtMillis,
            equals(originalModel.occurredAtMillis));
        expect(deserializedModel.userId, equals(originalModel.userId));
        expect(deserializedModel.userEmail, equals(originalModel.userEmail));
        expect(deserializedModel.userDisplayName,
            equals(originalModel.userDisplayName));
        expect(
            deserializedModel.userRoleName, equals(originalModel.userRoleName));
        expect(deserializedModel.userIpAddress,
            equals(originalModel.userIpAddress));
        expect(deserializedModel.userDeviceInfo,
            equals(originalModel.userDeviceInfo));
        expect(deserializedModel.appVersion, equals(originalModel.appVersion));
        expect(deserializedModel.requiredPermission,
            equals(originalModel.requiredPermission));
        expect(deserializedModel.actionType, equals(originalModel.actionType));
        expect(deserializedModel.useCaseId, equals(originalModel.useCaseId));
        expect(deserializedModel.oldDataMapped,
            equals(originalModel.oldDataMapped));
        expect(deserializedModel.newDataMapped,
            equals(originalModel.newDataMapped));
        expect(deserializedModel.schemaVersion,
            equals(originalModel.schemaVersion));
      });

      test('should preserve equality after round-trip serialization', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440019',
          'occurred_at': 1705315845000,
          'user_id': 'user-456',
          'user_email': 'equality@example.com',
          'user_display_name': 'Equality User',
          'user_role_name': 'viewer',
          'user_ip_address': '10.0.0.1',
          'user_device_info': 'Android',
          'app_version': '2.0.0',
          'required_permission': 'none',
          'action_type': 'update',
          'use_case_id': 'use-case-002',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        final originalModel = ActionLogModel.fromMap(map);
        final serializedMap = originalModel.toMap();
        final deserializedModel = ActionLogModel.fromMap(serializedMap);

        expect(deserializedModel, equals(originalModel));
      });
    });

    group('ActionLogModel Equatable implementation', () {
      test('should be equal when all props are the same', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440020',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'old_data_mapped': {'old': 'data'},
          'new_data_mapped': {'new': 'data'},
          'schema_version': 1,
        };
        final model1 = ActionLogModel.fromMap(map);
        final model2 = ActionLogModel.fromMap(map);

        expect(model1, equals(model2));
      });

      test('should not be equal when ids are different', () {
        final map1 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440021',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {},
          'schema_version': 1,
        };
        final map2 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440022',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {},
          'schema_version': 1,
        };
        final model1 = ActionLogModel.fromMap(map1);
        final model2 = ActionLogModel.fromMap(map2);

        expect(model1, isNot(equals(model2)));
      });

      test('should not be equal when timestamps are different', () {
        final map1 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440023',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {},
          'schema_version': 1,
        };
        final map2 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440023',
          'occurred_at': 1705315846000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {},
          'schema_version': 1,
        };
        final model1 = ActionLogModel.fromMap(map1);
        final model2 = ActionLogModel.fromMap(map2);

        expect(model1, isNot(equals(model2)));
      });

      test('should not be equal when actionType is different', () {
        final map1 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440024',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {},
          'schema_version': 1,
        };
        final map2 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440024',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'update',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {},
          'schema_version': 1,
        };
        final model1 = ActionLogModel.fromMap(map1);
        final model2 = ActionLogModel.fromMap(map2);

        expect(model1, isNot(equals(model2)));
      });

      test('should not be equal when newDataMapped is different', () {
        final map1 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440025',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {'key1': 'value1'},
          'schema_version': 1,
        };
        final map2 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440025',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {'key2': 'value2'},
          'schema_version': 1,
        };
        final model1 = ActionLogModel.fromMap(map1);
        final model2 = ActionLogModel.fromMap(map2);

        expect(model1, isNot(equals(model2)));
      });
    });

    group('ActionLogModel.props and stringify', () {
      test('should have all props in the correct order', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440026',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'old_data_mapped': {'old': 'data'},
          'new_data_mapped': {'new': 'data'},
          'schema_version': 1,
        };
        final model = ActionLogModel.fromMap(map);
        final props = model.props;

        expect(props.length, equals(15));
        expect(props[1], equals(1705315845000));
        expect(props[2], equals('user-123'));
        expect(props[3], equals('test@example.com'));
        expect(props[4], equals('Test User'));
        expect(props[5], equals('admin'));
        expect(props[6], equals('192.168.1.1'));
        expect(props[7], equals('iPhone 13'));
        expect(props[8], equals('1.0.0'));
        expect(props[9], equals('manageGlobalGoals'));
        expect(props[10], equals('create'));
        expect(props[11], equals('use-case-001'));
        expect(props[12], equals({'old': 'data'}));
        expect(props[13], equals({'new': 'data'}));
        expect(props[14], equals(1));
      });

      test('should have stringify enabled', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440027',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {},
          'schema_version': 1,
        };
        final model = ActionLogModel.fromMap(map);

        expect(model.stringify, isTrue);
        expect(
          model.toString(),
          contains('ActionLogModel'),
        );
      });
    });

    group('ActionLogModel edge cases', () {
      test('should handle empty string fields', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440009',
          'occurred_at': 1705315845000,
          'user_id': '',
          'user_email': '',
          'user_display_name': '',
          'user_role_name': '',
          'user_ip_address': '',
          'user_device_info': '',
          'app_version': '',
          'required_permission': '',
          'action_type': '',
          'use_case_id': '',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.userId, equals(''));
        expect(model.userEmail, equals(''));
        expect(model.userDisplayName, equals(''));
        expect(model.userRoleName, equals(''));
      });

      test('should handle very large timestamps', () {
        const largeTimestamp = 9223372036854775807;
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440010',
          'occurred_at': largeTimestamp,
          'user_id': 'user-time',
          'user_email': 'maxtime@example.com',
          'user_display_name': 'Max Time User',
          'user_role_name': 'admin',
          'user_ip_address': '255.255.255.255',
          'user_device_info': 'Max Device',
          'app_version': '9.9.9',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-max',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.occurredAtMillis, equals(largeTimestamp));
      });

      test('should handle newDataMapped with null values', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440011',
          'occurred_at': 1705315845000,
          'user_id': 'user-null-values',
          'user_email': 'nullvalues@example.com',
          'user_display_name': 'Null Values User',
          'user_role_name': 'viewer',
          'user_ip_address': '127.0.0.1',
          'user_device_info': 'Null Device',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'update',
          'use_case_id': 'use-case-null',
          'new_data_mapped': {'key1': null, 'key2': 'value'},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.newDataMapped['key1'], isNull);
        expect(model.newDataMapped['key2'], equals('value'));
      });

      test('should handle newDataMapped with mixed types', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440012',
          'occurred_at': 1705315845000,
          'user_id': 'user-mixed',
          'user_email': 'mixed@example.com',
          'user_display_name': 'Mixed User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'Mixed Device',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'create',
          'use_case_id': 'use-case-mixed',
          'new_data_mapped': {
            'string': 'value',
            'number': 42,
            'double': 3.14,
            'bool': true,
            'list': [1, 2, 3],
            'map': {'nested': 'value'},
          },
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.newDataMapped['string'], equals('value'));
        expect(model.newDataMapped['number'], equals(42));
        expect(model.newDataMapped['double'], equals(3.14));
        expect(model.newDataMapped['bool'], isTrue);
        expect(model.newDataMapped['list'], equals([1, 2, 3]));
        expect(model.newDataMapped['map']['nested'], equals('value'));
      });

      test('should handle fromMap with null oldDataMapped explicitly', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440013',
          'occurred_at': 1705315845000,
          'user_id': 'user-null-old',
          'user_email': 'nullold@example.com',
          'user_display_name': 'Null Old User',
          'user_role_name': 'viewer',
          'user_ip_address': '10.0.0.1',
          'user_device_info': 'Null Old Device',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'create',
          'use_case_id': 'use-case-null-old',
          'old_data_mapped': null,
          'new_data_mapped': {},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.oldDataMapped, isNull);
      });

      test('should handle Firestore timestamp with missing nanoseconds', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440014',
          'occurred_at': {'_seconds': 1705315845},
          'user_id': 'user-incomplete-ts',
          'user_email': 'incompletets@example.com',
          'user_display_name': 'Incomplete TS User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'Incomplete TS Device',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'update',
          'use_case_id': 'use-case-incomplete-ts',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.occurredAtMillis, isNull);
      });

      test('should handle schema version as different int values', () {
        final map1 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440015',
          'occurred_at': 1705315845000,
          'user_id': 'user-schema1',
          'user_email': 'schema1@example.com',
          'user_display_name': 'Schema1 User',
          'user_role_name': 'viewer',
          'user_ip_address': '127.0.0.1',
          'user_device_info': 'Schema1 Device',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'create',
          'use_case_id': 'use-case-schema1',
          'new_data_mapped': {},
          'schema_version': 1,
        };

        final map2 = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440016',
          'occurred_at': 1705315845000,
          'user_id': 'user-schema2',
          'user_email': 'schema2@example.com',
          'user_display_name': 'Schema2 User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'Schema2 Device',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'update',
          'use_case_id': 'use-case-schema2',
          'new_data_mapped': {},
          'schema_version': 2,
        };

        final model1 = ActionLogModel.fromMap(map1);
        final model2 = ActionLogModel.fromMap(map2);

        expect(model1.schemaVersion, equals(1));
        expect(model2.schemaVersion, equals(2));
      });

      test(
          'should handle newDataMapped null coalescing when newDataMappedRaw is null',
          () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440030',
          'occurred_at': 1705315845000,
          'user_id': 'user-null-coalesce',
          'user_email': 'nullcoalesce@example.com',
          'user_display_name': 'Null Coalesce User',
          'user_role_name': 'viewer',
          'user_ip_address': '10.0.0.1',
          'user_device_info': 'Null Coalesce Device',
          'app_version': '1.0.0',
          'required_permission': 'none',
          'action_type': 'create',
          'use_case_id': 'use-case-null-coalesce',
          'new_data_mapped': null,
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.newDataMapped, isA<Map<String, dynamic>>());
        expect(model.newDataMapped, isEmpty);
      });

      test(
          'should default to empty map when newDataMapped key is present but null',
          () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440031',
          'occurred_at': 1705315845000,
          'user_id': 'user-explicit-null',
          'user_email': 'explicitnull@example.com',
          'user_display_name': 'Explicit Null User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'Explicit Null Device',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'update',
          'use_case_id': 'use-case-explicit-null',
          'old_data_mapped': null,
          'new_data_mapped': null,
          'schema_version': 1,
        };

        final model = ActionLogModel.fromMap(map);

        expect(model.newDataMapped, equals(<String, dynamic>{}));
        expect(model.newDataMapped.isEmpty, isTrue);
      });
    });

    group('ActionLogModel constructor validation', () {
      test('should create model from fromMap factory', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440028',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {},
          'schema_version': 1,
        };
        final model = ActionLogModel.fromMap(map);

        expect(model, isNotNull);
        expect(model.id.value, equals('550e8400-e29b-41d4-a716-446655440028'));
      });

      test('should preserve field immutability after fromMap', () {
        final map = <String, dynamic>{
          'id': '550e8400-e29b-41d4-a716-446655440029',
          'occurred_at': 1705315845000,
          'user_id': 'user-123',
          'user_email': 'test@example.com',
          'user_display_name': 'Test User',
          'user_role_name': 'admin',
          'user_ip_address': '192.168.1.1',
          'user_device_info': 'iPhone 13',
          'app_version': '1.0.0',
          'required_permission': 'manageGlobalGoals',
          'action_type': 'create',
          'use_case_id': 'use-case-001',
          'new_data_mapped': {},
          'schema_version': 1,
        };
        final model = ActionLogModel.fromMap(map);

        expect(model.id, isNotNull);
        expect(model.userId, isNotNull);
        expect(model.newDataMapped, isNotNull);
      });
    });
  });
}
