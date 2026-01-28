import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_type.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/email.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ============================================================
// MARKER FOR OPTIONAL PARAMETERS
// ============================================================
const _defaultOldDataMarker = '_DEFAULT_OLD_DATA_';

// ============================================================
// MOCK CLASSES
// ============================================================

class MockEmail extends Mock implements Email {}

class MockLoggedInUser extends Mock implements LoggedInUser {}

class MockIpAddress extends Mock implements IpAddress {}

class MockDeviceInfo extends Mock implements DeviceInfo {}

class MockAppVersion extends Mock implements AppVersion {}

// ============================================================
// TEST SUITE
// ============================================================

void main() {
  group('ActionLog Entity', () {
    // ============================================================
    /// FIXTURES
    // ============================================================

    late LoggedInUser mockUser;
    late IpAddress mockIpAddress;
    late DeviceInfo mockDeviceInfo;
    late AppVersion mockAppVersion;
    late GoalsModulePermission mockPermission;
    late ActionType mockActionType;
    late IdUuidV7 testUuid;
    late DateTime testDateTime;
    late Map<String, dynamic> testNewData;
    late Map<String, dynamic> testOldData;

    setUp(() {
      mockUser = MockLoggedInUser();
      mockIpAddress = MockIpAddress();
      mockDeviceInfo = MockDeviceInfo();
      mockAppVersion = MockAppVersion();

      // Create Email mock properly
      final mockEmail = MockEmail();
      when(() => mockEmail.value).thenReturn('test@example.com');

      // Setup mock return values using when/thenReturn
      when(() => mockUser.uid).thenReturn('test-uid-123');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUser.roleName).thenReturn('admin');
      when(() => mockUser.email).thenReturn(mockEmail);

      when(() => mockIpAddress.value).thenReturn('192.168.1.1');
      when(() => mockDeviceInfo.value).thenReturn('iPhone 15 Pro iOS 17.0');
      when(() => mockAppVersion.value).thenReturn('1.0.0');

      // Use real enum instances instead of mocking (enums cannot be mocked)
      mockPermission = GoalsModulePermission.none;
      mockActionType = ActionType.create;
      testUuid = IdUuidV7.fromString('123e4567-e89b-12d3-a456-426614174000');
      testDateTime = DateTime(2026, 1, 28, 12, 0, 0);
      testNewData = {'key': 'new_value', 'count': 42};
      testOldData = {'key': 'old_value', 'count': 40};
    });

    /// Helper to create an ActionLog with custom parameters
    ActionLog createTestLog({
      IdUuidV7? id,
      DateTime? occurredAt,
      LoggedInUser? user,
      IpAddress? userIpAddress,
      DeviceInfo? userDeviceInfo,
      AppVersion? appVersion,
      GoalsModulePermission? requiredPermission,
      ActionType? actionType,
      String? useCaseId,
      Map<String, dynamic>? newDataMapped,
      Map<String, dynamic>? oldDataMapped,
    }) {
      return ActionLog.reconstruct(
        id: id ?? testUuid,
        occurredAt: occurredAt ?? testDateTime,
        user: user ?? mockUser,
        userIpAddress: userIpAddress ?? mockIpAddress,
        userDeviceInfo: userDeviceInfo ?? mockDeviceInfo,
        appVersion: appVersion ?? mockAppVersion,
        requiredPermission: requiredPermission ?? mockPermission,
        actionType: actionType ?? mockActionType,
        useCaseId: useCaseId ?? 'use-case-1',
        newDataMapped: newDataMapped ?? testNewData,
        oldDataMapped: oldDataMapped ?? testOldData,
      );
    }

    /// Helper to create via factory
    ActionLog createViaFactory({
      LoggedInUser? user,
      IpAddress? userIpAddress,
      DeviceInfo? userDeviceInfo,
      AppVersion? appVersion,
      GoalsModulePermission? requiredPermission,
      ActionType? actionType,
      String? useCaseId,
      Map<String, dynamic>? newDataMapped,
      Object? oldDataMapped = _defaultOldDataMarker,
    }) {
      // Use testOldData if oldDataMapped wasn't provided, else use provided value (including null)
      final actualOldData = identical(oldDataMapped, _defaultOldDataMarker)
          ? testOldData
          : oldDataMapped as Map<String, dynamic>?;

      return ActionLog.create(
        user: user ?? mockUser,
        userIpAddress: userIpAddress ?? mockIpAddress,
        userDeviceInfo: userDeviceInfo ?? mockDeviceInfo,
        appVersion: appVersion ?? mockAppVersion,
        requiredPermission: requiredPermission ?? mockPermission,
        actionType: actionType ?? mockActionType,
        useCaseId: useCaseId ?? 'use-case-1',
        newDataMapped: newDataMapped ?? testNewData,
        oldDataMapped: actualOldData,
      );
    }

    // ============================================================
    /// CONSTRUCTION & EQUALITY
    // ============================================================

    group('Construction & Equality |', () {
      test('should be created via reconstruct with all properties', () {
        // Act
        final log = createTestLog();

        // Assert
        expect(log, isNotNull);
        expect(log.id, equals(testUuid));
        expect(log.occurredAt, equals(testDateTime));
      });

      test('should be created via factory without occurredAt', () {
        // Act
        final log = createViaFactory();

        // Assert
        expect(log, isNotNull);
        expect(log.occurredAt, isNull);
        expect(log.id, isNotNull);
      });

      test('should generate unique IDs via create factory', () {
        // Act
        final log1 = createViaFactory();
        final log2 = createViaFactory();

        // Assert
        expect(log1.id, isNot(equals(log2.id)));
      });

      test('should support value equality with same properties', () {
        // Act
        final log1 = createTestLog();
        final log2 = createTestLog();

        // Assert
        expect(log1, equals(log2));
      });

      test('should not be equal if ID differs', () {
        // Arrange
        final differentId =
            IdUuidV7.fromString('223e4567-e89b-12d3-a456-426614174000');

        // Act
        final log1 = createTestLog();
        final log2 = createTestLog(id: differentId);

        // Assert
        expect(log1, isNot(equals(log2)));
      });

      test('should not be equal if occurredAt differs', () {
        // Arrange
        final differentDateTime = DateTime(2026, 1, 29, 12, 0, 0);

        // Act
        final log1 = createTestLog();
        final log2 = createTestLog(occurredAt: differentDateTime);

        // Assert
        expect(log1, isNot(equals(log2)));
      });

      test('should not be equal if newDataMapped differs', () {
        // Arrange
        final differentData = {'key': 'different_value', 'count': 99};

        // Act
        final log1 = createTestLog();
        final log2 = createTestLog(newDataMapped: differentData);

        // Assert
        expect(log1, isNot(equals(log2)));
      });

      test('should not be equal if oldDataMapped differs', () {
        // Arrange
        final differentOldData = {'key': 'very_old', 'count': 30};

        // Act
        final log1 = createTestLog();
        final log2 = createTestLog(oldDataMapped: differentOldData);

        // Assert
        expect(log1, isNot(equals(log2)));
      });

      test('should not be equal if useCaseId differs', () {
        // Act
        final log1 = createTestLog();
        final log2 = createTestLog(useCaseId: 'use-case-2');

        // Assert
        expect(log1, isNot(equals(log2)));
      });

      test('should have same hash for equal objects', () {
        // Act
        final log1 = createTestLog();
        final log2 = createTestLog();

        // Assert
        expect(log1.hashCode, equals(log2.hashCode));
      });

      test('should handle null oldDataMapped in equality', () {
        // Act
        final log1 = createTestLog(oldDataMapped: null);
        final log2 = createTestLog(oldDataMapped: null);

        // Assert
        expect(log1, equals(log2));
      });

      test('should not be equal if one has oldDataMapped and other null', () {
        // Act - Using factory which supports optional oldDataMapped
        final log1 = ActionLog.create(
          user: mockUser,
          userIpAddress: mockIpAddress,
          userDeviceInfo: mockDeviceInfo,
          appVersion: mockAppVersion,
          requiredPermission: mockPermission,
          actionType: mockActionType,
          useCaseId: 'use-case-1',
          newDataMapped: testNewData,
          oldDataMapped: testOldData, // Has oldDataMapped
        );
        final log2 = ActionLog.create(
          user: mockUser,
          userIpAddress: mockIpAddress,
          userDeviceInfo: mockDeviceInfo,
          appVersion: mockAppVersion,
          requiredPermission: mockPermission,
          actionType: mockActionType,
          useCaseId: 'use-case-1',
          newDataMapped: testNewData,
          oldDataMapped: null, // No oldDataMapped
        );

        // Assert
        expect(log1, isNot(equals(log2)));
      });
    });

    // ============================================================
    /// GETTERS - BASIC FUNCTIONALITY
    // ============================================================

    group('Getters - Basic Functionality |', () {
      test('id getter returns IdUuidV7 with correct value', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.id;

        // Assert
        expect(result, equals(testUuid));
        expect(result.value, equals(testUuid.value));
      });

      test('occurredAt getter returns correct DateTime', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.occurredAt;

        // Assert
        expect(result, equals(testDateTime));
        expect(result?.year, equals(2026));
        expect(result?.month, equals(1));
        expect(result?.day, equals(28));
      });

      test('occurredAt getter returns null when not provided', () {
        // Arrange
        final log = createViaFactory();

        // Act
        final result = log.occurredAt;

        // Assert
        expect(result, isNull);
      });

      test('user getter returns LoggedInUser with correct properties', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.user;

        // Assert
        expect(result, isNotNull);
        expect(result.uid, equals('test-uid-123'));
        expect(result.displayName, equals('Test User'));
        expect(result.roleName, equals('admin'));
      });

      test('userIpAddress getter returns IpAddress with correct value', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.userIpAddress;

        // Assert
        expect(result, isNotNull);
        expect(result.value, equals('192.168.1.1'));
      });

      test('userDeviceInfo getter returns DeviceInfo with correct value', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.userDeviceInfo;

        // Assert
        expect(result, isNotNull);
        expect(result.value, equals('iPhone 15 Pro iOS 17.0'));
      });

      test('appVersion getter returns AppVersion with correct value', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.appVersion;

        // Assert
        expect(result, isNotNull);
        expect(result.value, equals('1.0.0'));
      });

      test('requiredPermission getter returns GoalsModulePermission', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.requiredPermission;

        // Assert
        expect(result, equals(mockPermission));
        expect(result.name, equals('none'));
      });

      test('actionType getter returns ActionType', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.actionType;

        // Assert
        expect(result, equals(mockActionType));
        expect(result.name, equals('create'));
      });

      test('useCaseId getter returns String representation', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.useCaseId;

        // Assert
        expect(result, equals('use-case-1'));
        expect(result, isA<String>());
      });

      test('newDataMapped getter returns unmodifiable map', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.newDataMapped;

        // Assert
        expect(result, isNotNull);
        expect(result['key'], equals('new_value'));
        expect(result['count'], equals(42));
      });

      test('oldDataMapped getter returns unmodifiable map', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.oldDataMapped;

        // Assert
        expect(result, isNotNull);
        expect(result?['key'], equals('old_value'));
        expect(result?['count'], equals(40));
      });

      test('oldDataMapped getter returns null when not provided', () {
        // Arrange
        final log = createViaFactory(oldDataMapped: null);

        // Act
        final result = log.oldDataMapped;

        // Assert
        expect(result, isNull);
      });
    });

    // ============================================================
    /// GETTERS - DEFENSIVE COPYING
    // ============================================================

    group('Getters - Defensive Copying |', () {
      test('id getter returns new instance each call', () {
        // Arrange
        final log = createTestLog();

        // Act
        final first = log.id;
        final second = log.id;

        // Assert
        expect(first, equals(second));
        expect(first.value, equals(second.value));
      });

      test('occurredAt getter returns new DateTime instance', () {
        // Arrange
        final log = createTestLog();

        // Act
        final first = log.occurredAt;
        final second = log.occurredAt;

        // Assert
        expect(first, equals(second));
        expect(first?.millisecondsSinceEpoch,
            equals(second?.millisecondsSinceEpoch));
      });

      test('user getter returns reconstructed user', () {
        // Arrange
        final log = createTestLog();

        // Act
        final first = log.user;
        final second = log.user;

        // Assert
        expect(first.uid, equals(second.uid));
        expect(first.displayName, equals(second.displayName));
      });

      test('userIpAddress getter returns new instance', () {
        // Arrange
        final log = createTestLog();

        // Act
        final first = log.userIpAddress;
        final second = log.userIpAddress;

        // Assert
        expect(first.value, equals(second.value));
      });

      test('userDeviceInfo getter returns new instance', () {
        // Arrange
        final log = createTestLog();

        // Act
        final first = log.userDeviceInfo;
        final second = log.userDeviceInfo;

        // Assert
        expect(first.value, equals(second.value));
      });

      test('appVersion getter returns new instance', () {
        // Arrange
        final log = createTestLog();

        // Act
        final first = log.appVersion;
        final second = log.appVersion;

        // Assert
        expect(first.value, equals(second.value));
      });

      test('newDataMapped returns unmodifiable map each time', () {
        // Arrange
        final log = createTestLog();

        // Act
        final first = log.newDataMapped;
        final second = log.newDataMapped;

        // Assert
        expect(first, equals(second));
        expect(
          () => first['new_key'] = 'value',
          throwsUnsupportedError,
        );
      });

      test('oldDataMapped returns unmodifiable map each time', () {
        // Arrange
        final log = createTestLog();

        // Act
        final first = log.oldDataMapped;
        final second = log.oldDataMapped;

        // Assert
        expect(first, equals(second));
        expect(
          () => first?['new_key'] = 'value',
          throwsUnsupportedError,
        );
      });
    });

    // ============================================================
    /// IMMUTABILITY & SECURITY
    // ============================================================

    group('Immutability & Security |', () {
      test(
          'modifying newDataMapped from getter should not affect internal state',
          () {
        // Arrange
        final log = createTestLog();
        final originalValue = log.newDataMapped['count'];

        // Act
        final map = log.newDataMapped;
        expect(
          () => map['count'] = 999,
          throwsUnsupportedError,
        );

        // Assert - internal state unchanged
        expect(log.newDataMapped['count'], equals(originalValue));
      });

      test(
          'modifying oldDataMapped from getter should not affect internal state',
          () {
        // Arrange
        final log = createTestLog();
        final originalValue = log.oldDataMapped?['count'];

        // Act
        final map = log.oldDataMapped;
        expect(
          () => map?['count'] = 999,
          throwsUnsupportedError,
        );

        // Assert
        expect(log.oldDataMapped?['count'], equals(originalValue));
      });

      test('factory create should make maps unmodifiable before storing', () {
        // Arrange
        final originalNewData = {'key': 'value', 'count': 10};
        final originalOldData = {'key': 'old', 'count': 5};

        // Act
        final log = ActionLog.create(
          user: mockUser,
          userIpAddress: mockIpAddress,
          userDeviceInfo: mockDeviceInfo,
          appVersion: mockAppVersion,
          requiredPermission: mockPermission,
          actionType: mockActionType,
          useCaseId: 'test-use-case',
          newDataMapped: originalNewData,
          oldDataMapped: originalOldData,
        );

        // Modify original maps
        originalNewData['key'] = 'modified';
        originalOldData['key'] = 'modified';

        // Assert - log should have original values
        expect(log.newDataMapped['key'], equals('value'));
        expect(log.oldDataMapped?['key'], equals('old'));
      });

      test('factory reconstruct should make maps unmodifiable before storing',
          () {
        // Arrange
        final originalNewData = {'key': 'value', 'count': 10};
        final originalOldData = {'key': 'old', 'count': 5};

        // Act
        final log = ActionLog.reconstruct(
          id: testUuid,
          occurredAt: testDateTime,
          user: mockUser,
          userIpAddress: mockIpAddress,
          userDeviceInfo: mockDeviceInfo,
          appVersion: mockAppVersion,
          requiredPermission: mockPermission,
          actionType: mockActionType,
          useCaseId: 'test-use-case',
          newDataMapped: originalNewData,
          oldDataMapped: originalOldData,
        );

        // Modify original maps
        originalNewData['key'] = 'modified';
        originalOldData['key'] = 'modified';

        // Assert
        expect(log.newDataMapped['key'], equals('value'));
        expect(log.oldDataMapped?['key'], equals('old'));
      });

      test('internal state should remain consistent after getter calls', () {
        // Arrange
        final log = createTestLog();

        // Act - Call multiple getters
        log.id;
        log.occurredAt;
        log.user;
        log.userIpAddress;
        log.userDeviceInfo;
        log.appVersion;
        log.newDataMapped;
        log.oldDataMapped;

        // Assert - State unchanged
        expect(log.id, equals(testUuid));
        expect(log.newDataMapped['count'], equals(42));
        expect(log.oldDataMapped?['count'], equals(40));
      });
    });

    // ============================================================
    /// EQUATABLE IMPLEMENTATION
    // ============================================================

    group('Equatable Implementation |', () {
      test('props contains all 11 properties in correct order', () {
        // Arrange
        final log = createTestLog();

        // Act
        final props = log.props;

        // Assert
        expect(props.length, equals(11));
        expect(props[0], equals(testUuid));
        expect(props[1], equals(testDateTime));
        expect(props[2], equals(mockUser));
        expect(props[3], equals(mockIpAddress));
        expect(props[4], equals(mockDeviceInfo));
        expect(props[5], equals(mockAppVersion));
        expect(props[6], equals(mockPermission));
        expect(props[7], equals(mockActionType));
        expect(props[8], equals('use-case-1'));
        expect(props[9], equals(testOldData));
        expect(props[10], equals(testNewData));
      });

      test('stringify should return true', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.stringify;

        // Assert
        expect(result, isTrue);
      });

      test('toString should return readable representation', () {
        // Arrange
        final log = createTestLog();

        // Act
        final result = log.toString();

        // Assert
        expect(result, startsWith('ActionLog'));
        expect(result, contains('IdUuidV7')); // Contains the id value object
        expect(result,
            contains('2026-01-28')); // Contains the date from occurredAt
      });

      test('two equal objects should have same toString', () {
        // Arrange
        final log1 = createTestLog();
        final log2 = createTestLog();

        // Act
        final str1 = log1.toString();
        final str2 = log2.toString();

        // Assert
        expect(str1, equals(str2));
      });

      test('two different objects should have different toString', () {
        // Arrange
        final log1 = createTestLog();
        final log2 = createTestLog(useCaseId: 'different');

        // Act
        final str1 = log1.toString();
        final str2 = log2.toString();

        // Assert
        expect(str1, isNot(equals(str2)));
      });
    });

    // ============================================================
    /// MAP HANDLING & SERIALIZATION
    // ============================================================

    group('Map Handling & Serialization |', () {
      test('newDataMapped with empty map should work', () {
        // Act
        final log = createTestLog(newDataMapped: {});

        // Assert
        expect(log.newDataMapped, isEmpty);
        expect(log.newDataMapped, isA<Map<String, dynamic>>());
      });

      test('newDataMapped with nested objects should be preserved', () {
        // Arrange
        final nestedData = {
          'user': {'name': 'John', 'age': 30},
          'settings': {'theme': 'dark'}
        };

        // Act
        final log = createTestLog(newDataMapped: nestedData);

        // Assert
        expect(log.newDataMapped['user'], isA<Map>());
        expect(log.newDataMapped['user']['name'], equals('John'));
        expect(log.newDataMapped['settings']['theme'], equals('dark'));
      });

      test('oldDataMapped with null should be handled correctly', () {
        // Act
        final log = createViaFactory(oldDataMapped: null);

        // Assert
        expect(log.oldDataMapped, isNull);
      });

      test('oldDataMapped with empty map should work', () {
        // Act
        final log = createTestLog(oldDataMapped: {});

        // Assert
        expect(log.oldDataMapped, isEmpty);
      });

      test('maps should preserve numeric types', () {
        // Arrange
        final dataWithNumbers = {
          'int_value': 42,
          'double_value': 3.14,
          'zero': 0,
          'negative': -10,
        };

        // Act
        final log = createTestLog(newDataMapped: dataWithNumbers);

        // Assert
        expect(log.newDataMapped['int_value'], isA<int>());
        expect(log.newDataMapped['double_value'], isA<double>());
        expect(log.newDataMapped['zero'], equals(0));
        expect(log.newDataMapped['negative'], equals(-10));
      });

      test('maps should preserve boolean types', () {
        // Arrange
        final dataWithBools = {
          'is_active': true,
          'is_deleted': false,
        };

        // Act
        final log = createTestLog(newDataMapped: dataWithBools);

        // Assert
        expect(log.newDataMapped['is_active'], isA<bool>());
        expect(log.newDataMapped['is_deleted'], isA<bool>());
        expect(log.newDataMapped['is_active'], isTrue);
        expect(log.newDataMapped['is_deleted'], isFalse);
      });

      test('maps should preserve null values', () {
        // Arrange
        final dataWithNulls = {
          'existing_field': 'value',
          'null_field': null,
        };

        // Act
        final log = createTestLog(newDataMapped: dataWithNulls);

        // Assert
        expect(log.newDataMapped.containsKey('null_field'), isTrue);
        expect(log.newDataMapped['null_field'], isNull);
      });

      test('maps should preserve list values', () {
        // Arrange
        final dataWithLists = {
          'items': [1, 2, 3],
          'names': ['Alice', 'Bob'],
        };

        // Act
        final log = createTestLog(newDataMapped: dataWithLists);

        // Assert
        expect(log.newDataMapped['items'], isA<List>());
        expect(log.newDataMapped['items'].length, equals(3));
        expect(log.newDataMapped['names'][0], equals('Alice'));
      });

      test('maps should preserve string values with special characters', () {
        // Arrange
        final dataWithSpecialStrings = {
          'json_string': '{"key": "value"}',
          'unicode': '你好世界🌍',
          'empty_string': '',
          'whitespace': '   ',
        };

        // Act
        final log = createTestLog(newDataMapped: dataWithSpecialStrings);

        // Assert
        expect(log.newDataMapped['json_string'], contains('{'));
        expect(log.newDataMapped['unicode'], contains('世'));
        expect(log.newDataMapped['empty_string'], isEmpty);
        expect(log.newDataMapped['whitespace'], equals('   '));
      });
    });

    // ============================================================
    /// EDGE CASES & BOUNDARIES
    // ============================================================

    group('Edge Cases & Boundaries |', () {
      test('should handle useCaseId with empty string', () {
        // Act
        final log = createTestLog(useCaseId: '');

        // Assert
        expect(log.useCaseId, isEmpty);
      });

      test('should handle useCaseId with whitespace only', () {
        // Act
        final log = createTestLog(useCaseId: '   ');

        // Assert
        expect(log.useCaseId, equals('   '));
      });

      test('should handle useCaseId with special characters', () {
        // Arrange
        const specialId = 'use-case_v1.0!@#';

        // Act
        final log = createTestLog(useCaseId: specialId);

        // Assert
        expect(log.useCaseId, equals(specialId));
      });

      test('should handle useCaseId with very long string', () {
        // Arrange
        final longId = 'a' * 1000;

        // Act
        final log = createTestLog(useCaseId: longId);

        // Assert
        expect(log.useCaseId, equals(longId));
        expect(log.useCaseId.length, equals(1000));
      });

      test('should handle DateTime at epoch', () {
        // Arrange
        final epochDateTime = DateTime.fromMillisecondsSinceEpoch(0);

        // Act
        final log = createTestLog(occurredAt: epochDateTime);

        // Assert
        expect(log.occurredAt, equals(epochDateTime));
      });

      test('should handle DateTime in far future', () {
        // Arrange
        final futureDateTime = DateTime(9999, 12, 31, 23, 59, 59);

        // Act
        final log = createTestLog(occurredAt: futureDateTime);

        // Assert
        expect(log.occurredAt, equals(futureDateTime));
      });

      test('should handle very large map', () {
        // Arrange
        final largeMap = <String, dynamic>{};
        for (int i = 0; i < 1000; i++) {
          largeMap['key_$i'] = 'value_$i';
        }

        // Act
        final log = createTestLog(newDataMapped: largeMap);

        // Assert
        expect(log.newDataMapped.length, equals(1000));
        expect(log.newDataMapped['key_0'], equals('value_0'));
        expect(log.newDataMapped['key_999'], equals('value_999'));
      });

      test('should handle deeply nested maps', () {
        // Arrange
        final deeplyNested = {
          'level1': {
            'level2': {
              'level3': {
                'level4': {'level5': 'deep_value'}
              }
            }
          }
        };

        // Act
        final log = createTestLog(newDataMapped: deeplyNested);

        // Assert
        expect(
            log.newDataMapped['level1']['level2']['level3']['level4']['level5'],
            equals('deep_value'));
      });

      test('should preserve map structure through multiple accesses', () {
        // Arrange
        final data = {
          'created_at': '2026-01-28',
          'modified_at': '2026-01-28',
          'user_count': 42,
        };

        final log = createTestLog(newDataMapped: data);

        // Act
        for (int i = 0; i < 5; i++) {
          expect(log.newDataMapped['user_count'], equals(42));
        }

        // Assert - all accesses return same values
        expect(log.newDataMapped.length, equals(3));
      });
    });

    // ============================================================
    /// TYPE SAFETY & VALIDATION
    // ============================================================

    group('Type Safety & Validation |', () {
      test('getters should return correct types', () {
        // Arrange
        final log = createTestLog();

        // Assert
        expect(log.id, isA<IdUuidV7>());
        expect(log.occurredAt, isA<DateTime?>());
        expect(log.user, isA<LoggedInUser>());
        expect(log.userIpAddress, isA<IpAddress>());
        expect(log.userDeviceInfo, isA<DeviceInfo>());
        expect(log.appVersion, isA<AppVersion>());
        expect(log.requiredPermission, isA<GoalsModulePermission>());
        expect(log.actionType, isA<ActionType>());
        expect(log.useCaseId, isA<String>());
        expect(log.newDataMapped, isA<Map<String, dynamic>>());
        expect(log.oldDataMapped, isA<Map<String, dynamic>?>());
      });

      test('props should contain correct types', () {
        // Arrange
        final log = createTestLog();

        // Act
        final props = log.props;

        // Assert
        expect(props[0], isA<IdUuidV7>());
        expect(props[1], isA<DateTime>());
        expect(props[2], isA<LoggedInUser>());
        expect(props[3], isA<IpAddress>());
        expect(props[4], isA<DeviceInfo>());
        expect(props[5], isA<AppVersion>());
        expect(props[6], isA<GoalsModulePermission>());
        expect(props[7], isA<ActionType>());
        expect(props[8], isA<String>());
        expect(props[9], isA<Map<String, dynamic>?>());
        expect(props[10], isA<Map<String, dynamic>>());
      });

      test('map values should maintain their types', () {
        // Arrange
        final data = {
          'string': 'value',
          'int': 123,
          'double': 45.67,
          'bool': true,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
          'null': null,
        };

        // Act
        final log = createTestLog(newDataMapped: data);
        final result = log.newDataMapped;

        // Assert
        expect(result['string'], isA<String>());
        expect(result['int'], isA<int>());
        expect(result['double'], isA<double>());
        expect(result['bool'], isA<bool>());
        expect(result['list'], isA<List>());
        expect(result['map'], isA<Map>());
        expect(result['null'], isNull);
      });
    });

    // ============================================================
    /// NULL HANDLING
    // ============================================================

    group('Null Handling |', () {
      test('occurredAt can be null from create factory', () {
        // Act
        final log = createViaFactory();

        // Assert
        expect(log.occurredAt, isNull);
      });

      test('occurredAt must not be null from reconstruct', () {
        // Act
        final log = createTestLog(occurredAt: testDateTime);

        // Assert
        expect(log.occurredAt, isNotNull);
      });

      test('oldDataMapped can be null from create factory', () {
        // Act
        final log = createViaFactory(oldDataMapped: null);

        // Assert
        expect(log.oldDataMapped, isNull);
      });

      test('oldDataMapped can be null from reconstruct', () {
        // Act & Assert
        expect(
          () => ActionLog.reconstruct(
            id: testUuid,
            occurredAt: testDateTime,
            user: mockUser,
            userIpAddress: mockIpAddress,
            userDeviceInfo: mockDeviceInfo,
            appVersion: mockAppVersion,
            requiredPermission: mockPermission,
            actionType: mockActionType,
            useCaseId: 'test',
            newDataMapped: testNewData,
            oldDataMapped: {}, // Cannot be null in reconstruct
          ),
          isNotNull,
        );
      });

      test('newDataMapped must not be null', () {
        // Arrange
        final log = createTestLog();

        // Assert
        expect(log.newDataMapped, isNotNull);
      });

      test('oldDataMapped being null should not affect equality', () {
        // Arrange - Use reconstruct to control IDs
        final id = IdUuidV7.fromString('123e4567-e89b-12d3-a456-426614174000');
        final dateTime = DateTime(2026, 1, 28, 12, 0, 0);

        final log1 = ActionLog.reconstruct(
          id: id,
          occurredAt: dateTime,
          user: mockUser,
          userIpAddress: mockIpAddress,
          userDeviceInfo: mockDeviceInfo,
          appVersion: mockAppVersion,
          requiredPermission: mockPermission,
          actionType: mockActionType,
          useCaseId: 'use-case-1',
          newDataMapped: testNewData,
          oldDataMapped: {}, // Empty oldDataMapped
        );

        final log2 = ActionLog.reconstruct(
          id: id,
          occurredAt: dateTime,
          user: mockUser,
          userIpAddress: mockIpAddress,
          userDeviceInfo: mockDeviceInfo,
          appVersion: mockAppVersion,
          requiredPermission: mockPermission,
          actionType: mockActionType,
          useCaseId: 'use-case-1',
          newDataMapped: testNewData,
          oldDataMapped: {}, // Same empty oldDataMapped
        );

        // Assert - These should be equal
        expect(log1, equals(log2));
      });

      test('one log with null oldDataMapped not equal to one with map', () {
        // Arrange
        final log1 = createViaFactory(oldDataMapped: null);
        final log2 = createViaFactory(oldDataMapped: {'key': 'value'});

        // Assert
        expect(log1, isNot(equals(log2)));
      });
    });

    // ============================================================
    /// FACTORY CONSTRUCTORS COMPARISON
    // ============================================================

    group('Factory Constructors Comparison |', () {
      test('create generates unique ID each time', () {
        // Act
        final log1 = createViaFactory();
        final log2 = createViaFactory();
        final log3 = createViaFactory();

        // Assert
        expect(log1.id, isNot(equals(log2.id)));
        expect(log2.id, isNot(equals(log3.id)));
        expect(log1.id, isNot(equals(log3.id)));
      });

      test('create leaves occurredAt as null', () {
        // Act
        final log = createViaFactory();

        // Assert
        expect(log.occurredAt, isNull);
      });

      test('reconstruct preserves exact ID', () {
        // Act
        final log = createTestLog(id: testUuid);

        // Assert
        expect(log.id, equals(testUuid));
      });

      test('reconstruct requires occurredAt', () {
        // Assert - reconstruct requires occurredAt param
        expect(
          () => ActionLog.reconstruct(
            id: testUuid,
            occurredAt: testDateTime,
            user: mockUser,
            userIpAddress: mockIpAddress,
            userDeviceInfo: mockDeviceInfo,
            appVersion: mockAppVersion,
            requiredPermission: mockPermission,
            actionType: mockActionType,
            useCaseId: 'test',
            newDataMapped: testNewData,
            oldDataMapped: {},
          ),
          isNotNull,
        );
      });

      test('both factories handle maps immutability', () {
        // Arrange
        final mutableData = {'key': 'value'};

        // Act - via create
        final log1 = createViaFactory(newDataMapped: mutableData);
        mutableData['key'] = 'modified';

        // Assert
        expect(log1.newDataMapped['key'], equals('value'));

        // Act - via reconstruct
        final mutableData2 = {'key': 'value'};
        final log2 = createTestLog(newDataMapped: mutableData2);
        mutableData2['key'] = 'modified';

        // Assert
        expect(log2.newDataMapped['key'], equals('value'));
      });
    });

    // ============================================================
    /// COMPLEX SCENARIOS
    // ============================================================

    group('Complex Scenarios |', () {
      test('should handle realistic audit log for goal creation', () {
        // Arrange
        final createdGoalData = {
          'goal_id': 'goal-123',
          'target_amount': 5000.0,
          'month': 2,
          'year': 2026,
          'created_by': 'user-456',
        };

        // Act
        final log = createViaFactory(
          actionType: mockActionType,
          useCaseId: 'create-revenue-goal',
          newDataMapped: createdGoalData,
          oldDataMapped: null,
        );

        // Assert
        expect(log.actionType, equals(mockActionType));
        expect(log.useCaseId, equals('create-revenue-goal'));
        expect(log.newDataMapped['goal_id'], equals('goal-123'));
        expect(log.oldDataMapped, isNull);
      });

      test('should handle realistic audit log for goal update', () {
        // Arrange
        final oldGoalData = {'target_amount': 5000.0, 'status': 'active'};
        final newGoalData = {'target_amount': 7500.0, 'status': 'active'};

        // Act
        final log = createViaFactory(
          actionType: mockActionType,
          useCaseId: 'update-revenue-goal',
          newDataMapped: newGoalData,
          oldDataMapped: oldGoalData,
        );

        // Assert
        expect(log.oldDataMapped?['target_amount'], equals(5000.0));
        expect(log.newDataMapped['target_amount'], equals(7500.0));
      });

      test('should track user permissions in logs', () {
        // Arrange
        const adminPermission = 'ADMIN_WRITE_GOAL';
        const userPermission = 'USER_WRITE_OWN_GOAL';

        // Act
        final adminLog = createTestLog(
          useCaseId: adminPermission,
        );

        final userLog = createTestLog(
          useCaseId: userPermission,
        );

        // Assert
        expect(adminLog.useCaseId, equals(adminPermission));
        expect(userLog.useCaseId, equals(userPermission));
        expect(adminLog.useCaseId, isNot(equals(userLog.useCaseId)));
      });

      test('should maintain log order via timestamps', () {
        // Arrange
        final now = DateTime.now();
        final later = now.add(const Duration(minutes: 5));

        // Act
        final log1 = createTestLog(occurredAt: now);
        final log2 = createTestLog(occurredAt: later);

        // Assert
        expect(log1.occurredAt!.isBefore(log2.occurredAt!), isTrue);
      });

      test('should support bulk log creation', () {
        // Arrange & Act
        final logs = [
          createViaFactory(),
          createViaFactory(),
          createViaFactory(),
          createViaFactory(),
          createViaFactory(),
        ];

        // Assert
        expect(logs.length, equals(5));
        expect(logs[0].id, isNot(equals(logs[1].id)));
        expect(logs.every((log) => log.id.value.isNotEmpty), isTrue);
      });

      test('should handle logs in collections', () {
        // Arrange
        final log1 = createTestLog();
        final log2 = createTestLog(useCaseId: 'different-use-case');
        final log3 = createTestLog(
            id: IdUuidV7.fromString('223e4567-e89b-12d3-a456-426614174000'));

        // Act
        final logSet = {log1, log2, log3};
        final logList = [log1, log2, log3];
        final logMap = {
          'log1': log1,
          'log2': log2,
          'log3': log3,
        };

        // Assert
        expect(logSet.length, equals(3));
        expect(logList.length, equals(3));
        expect(logMap.length, equals(3));
        expect(logList[0], equals(log1));
      });
    });

    // ============================================================
    /// SECURITY EDGE CASES
    // ============================================================

    group('Security Edge Cases |', () {
      test('should prevent modification of newDataMapped via returned map', () {
        // Arrange
        final log = createTestLog();

        // Act & Assert
        expect(
          () => log.newDataMapped['secret_key'] = 'secret_value',
          throwsUnsupportedError,
        );
      });

      test('should prevent modification of oldDataMapped via returned map', () {
        // Arrange
        final log = createTestLog();

        // Act & Assert
        expect(
          () => log.oldDataMapped?['secret_key'] = 'secret_value',
          throwsUnsupportedError,
        );
      });

      test('maps created with sensitive data should not leak via copies', () {
        // Arrange
        final sensitiveData = {
          'password': 'secret123',
          'api_key': 'xyz789',
          'ssn': '123-45-6789',
        };

        // Act
        final log = createTestLog(newDataMapped: sensitiveData);
        final copiedMap = log.newDataMapped;

        // Assert
        expect(copiedMap.containsKey('password'), isTrue);
        expect(
          () => copiedMap.remove('password'),
          throwsUnsupportedError,
        );
      });

      test('modifying original data before passing should not affect log', () {
        // Arrange
        final mutableData = {'amount': 1000, 'status': 'pending'};

        // Act
        final log = createViaFactory(newDataMapped: mutableData);
        mutableData['amount'] = 0;
        mutableData['status'] = 'cancelled';
        mutableData['malicious'] = 'injection';

        // Assert
        expect(log.newDataMapped['amount'], equals(1000));
        expect(log.newDataMapped['status'], equals('pending'));
        expect(log.newDataMapped.containsKey('malicious'), isFalse);
      });

      test('all getter instances should be independent', () {
        // Arrange
        final log = createTestLog();

        // Act
        final id1 = log.id;
        final id2 = log.id;

        // Assert - different objects but equal values
        expect(id1, equals(id2));
        expect(identical(id1, id2), isFalse);
      });
    });

    // ============================================================
    /// STRING REPRESENTATION EDGE CASES
    // ============================================================

    group('String Representation Edge Cases |', () {
      test('toString with null occurredAt should work', () {
        // Arrange
        final log = createViaFactory();

        // Act
        final result = log.toString();

        // Assert
        expect(result, isNotNull);
        expect(result, isA<String>());
        expect(result.length, greaterThan(0));
      });

      test('toString with large data maps should work', () {
        // Arrange
        final largeData = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          largeData['key_$i'] = 'value_$i';
        }

        // Act
        final log = createTestLog(newDataMapped: largeData);
        final result = log.toString();

        // Assert
        expect(result, isNotNull);
        expect(result.length, greaterThan(100));
      });

      test('toString with special characters in strings should work', () {
        // Arrange
        final specialData = {
          'unicode': '你好 مرحبا שלום',
          'emoji': '🚀 🎯 ✅',
          'special': '!@#^&*()',
        };

        // Act
        final log = createTestLog(newDataMapped: specialData);
        final result = log.toString();

        // Assert
        expect(result, isNotNull);
        expect(result, isA<String>());
      });
    });

    // ============================================================
    /// EQUALITY EDGE CASES
    // ============================================================

    group('Equality Edge Cases |', () {
      test('logs with same ID but different data are not equal', () {
        // Arrange
        final log1 = createTestLog();
        final log2 = createTestLog(newDataMapped: {'different': 'data'});

        // Assert
        expect(log1, isNot(equals(log2)));
      });

      test('logs with different useCaseId are not equal', () {
        // Act
        final log1 = createTestLog(useCaseId: 'use-case-a');
        final log2 = createTestLog(useCaseId: 'use-case-b');

        // Assert
        expect(log1, isNot(equals(log2)));
      });

      test('equality is symmetric', () {
        // Arrange
        final log1 = createTestLog();
        final log2 = createTestLog();

        // Assert
        expect(log1, equals(log2));
        expect(log2, equals(log1));
      });

      test('equality is transitive', () {
        // Arrange
        final log1 = createTestLog();
        final log2 = createTestLog();
        final log3 = createTestLog();

        // Assert
        expect(log1, equals(log2));
        expect(log2, equals(log3));
        expect(log1, equals(log3));
      });

      test('reflexivity: log should equal itself', () {
        // Arrange
        final log = createTestLog();

        // Assert
        expect(log, equals(log));
      });
    });
  });
}
