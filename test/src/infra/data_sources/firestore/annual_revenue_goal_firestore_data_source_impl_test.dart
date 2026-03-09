import 'package:bits_goals_module/src/core/data/exceptions/rate_limit_exceeded_exception.dart';
import 'package:bits_goals_module/src/core/application/ports/rate_limiter_service.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/infra/config/data_sources/firestore_config.dart';
import 'package:bits_goals_module/src/infra/data_sources/firestore/annual_revenue_goal_remote_data_source_firestore_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Manual Mock for RateLimiterService
class ManualMockRateLimiterService implements RateLimiterService {
  Exception? exceptionToThrow;
  String? lastFunctionId;
  Duration? lastWindowDuration;
  int? lastMaxAttempts;

  @override
  Future<T> run<T>({
    required String functionId,
    required Future<T> Function() function,
    Duration windowDuration = const Duration(seconds: 2),
    int maxAttempts = 1,
  }) async {
    lastFunctionId = functionId;
    lastWindowDuration = windowDuration;
    lastMaxAttempts = maxAttempts;

    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return await function();
  }
}

class MockActionLogModel extends Mock implements ActionLogModel {}

// Fakes
class FakeFirestoreConfig extends Fake implements FirestoreConfig {
  late FakeFirebaseFirestore _client;
  final String _monthlyRevenueGoalsCollection = 'monthly_goals';
  final String _annualRevenueGoalsMetaCollection = 'annual_meta';
  final String _goalsActionLogsCollection = 'action_logs';

  @override
  FakeFirebaseFirestore get client => _client;
  set client(FakeFirebaseFirestore value) => _client = value;

  @override
  String get monthlyRevenueGoalsCollection => _monthlyRevenueGoalsCollection;

  @override
  String get annualRevenueGoalsMetaCollection =>
      _annualRevenueGoalsMetaCollection;

  @override
  String get goalsActionLogsCollection => _goalsActionLogsCollection;
}

class FakeIdUuidV7 extends Fake implements IdUuidV7 {
  final String _value;
  FakeIdUuidV7([this._value = 'fake-uuid-v7-test']);

  @override
  String get value => _value;

  @override
  List<Object?> get props => [_value];

  @override
  bool? get stringify => true;
}

Future<void> dummyFunction() async {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirestoreConfig fakeConfig;
  late ManualMockRateLimiterService mockRateLimiter;
  late AnnualRevenueGoalRemoteDataSourceFirestoreImpl dataSource;

  // Test Data
  late MockActionLogModel mockLog;
  late List<MonthlyRevenueGoalRemoteModel> validGoalsList;

  setUpAll(() {
    registerFallbackValue(FakeIdUuidV7());
    registerFallbackValue(const Duration(seconds: 2));
    registerFallbackValue(dummyFunction);
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeConfig = FakeFirestoreConfig();
    fakeConfig.client = fakeFirestore;

    mockRateLimiter = ManualMockRateLimiterService();

    dataSource = AnnualRevenueGoalRemoteDataSourceFirestoreImpl(
      config: fakeConfig,
      rateLimiter: mockRateLimiter,
    );

    mockLog = MockActionLogModel();
    when(() => mockLog.uuidV7).thenReturn(
        IdUuidV7.fromString('00000000-0000-0000-0000-000000000001'));
    when(() => mockLog.toMap()).thenReturn({
      ActionLogModelCurrentSchema.id: '00000000-0000-0000-0000-000000000001',
      ActionLogModelCurrentSchema.occurredAt: null,
      ActionLogModelCurrentSchema.userId: 'user-id-1',
      ActionLogModelCurrentSchema.userEmail: 'user@email.com',
      ActionLogModelCurrentSchema.userDisplayName: 'User Display Name',
      ActionLogModelCurrentSchema.userRoleName: 'admin',
      ActionLogModelCurrentSchema.userIpAddress: '127.0.0.1',
      ActionLogModelCurrentSchema.userDeviceInfo: 'test-device',
      ActionLogModelCurrentSchema.appVersion: '1.0.0',
      ActionLogModelCurrentSchema.requiredPermission: 'goals.write',
      ActionLogModelCurrentSchema.actionType: 'create',
      ActionLogModelCurrentSchema.useCaseId: 'createMonthlyGoalsForYear',
      ActionLogModelCurrentSchema.oldDataMapped: null,
      ActionLogModelCurrentSchema.newDataMapped: {'action': 'create'},
      ActionLogModelCurrentSchema.schemaVersion:
          ActionLogModelCurrentSchema.version,
    });

    // Create a list of 12 goals with the full remote schema.
    validGoalsList = List.generate(12, (index) {
      final uuid =
          '00000000-0000-0000-0000-${(index + 2).toString().padLeft(12, '0')}';
      return MonthlyRevenueGoalRemoteModel.fromMap({
        MonthlyRevenueGoalRemoteSchemaV1.uuidV7: uuid,
        MonthlyRevenueGoalRemoteSchemaV1.month: index + 1,
        MonthlyRevenueGoalRemoteSchemaV1.year: 2025,
        MonthlyRevenueGoalRemoteSchemaV1.targetCents: 100000,
        MonthlyRevenueGoalRemoteSchemaV1.progressCents: 0,
        MonthlyRevenueGoalRemoteSchemaV1.currencyCode: 'USD',
        MonthlyRevenueGoalRemoteSchemaV1.schemaVersion:
            MonthlyRevenueGoalCurrentSchema.version,
      });
    });
  });

  group('AnnualRevenueGoalRemoteDataSourceFirestoreImpl', () {
    group('Rate Limiter', () {
      test('should rethrow RateLimitExceededException', () async {
        mockRateLimiter.exceptionToThrow = const RateLimitExceededException(
          remainingDuration: Duration(seconds: 2),
        );

        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: 2025,
            goals: validGoalsList,
            log: mockLog,
          ),
          throwsA(isA<RateLimitExceededException>()),
        );
      });

      test('should propagate ServerException thrown by rate limiter', () async {
        mockRateLimiter.exceptionToThrow =
            const ServerException(reason: ServerExceptionReason.unexpected);

        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: 2025,
            goals: validGoalsList,
            log: mockLog,
          ),
          throwsA(isA<ServerException>().having(
              (e) => e.reason, 'reason', ServerExceptionReason.unexpected)),
        );
      });

      test('should use correct functionId', () async {
        const year = 2088;
        await dataSource.createMonthlyGoalsForYear(
          year: year,
          goals: validGoalsList,
          log: mockLog,
        );
        expect(
            mockRateLimiter.lastFunctionId, 'createMonthlyGoalsForYear($year)');
      });
    });

    group('Firestore Exceptions', () {
      test('should map permission-denied to ServerException(permissionDenied)',
          () async {
        mockRateLimiter.exceptionToThrow = FirebaseException(
            plugin: 'cloud_firestore', code: 'permission-denied');

        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: 2026,
            goals: validGoalsList,
            log: mockLog,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.permissionDenied,
          )),
        );
      });

      test('should map unavailable to ServerException(connectionError)',
          () async {
        mockRateLimiter.exceptionToThrow =
            FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');

        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: 2026,
            goals: validGoalsList,
            log: mockLog,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.connectionError,
          )),
        );
      });

      test(
          'should catch generic errors and wrap in ServerException(unexpected)',
          () async {
        final genericException = Exception('Something bad happened');
        mockRateLimiter.exceptionToThrow = genericException;

        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: 2029,
            goals: validGoalsList,
            log: mockLog,
          ),
          throwsA(isA<ServerException>()
              .having(
                  (e) => e.reason, 'reason', ServerExceptionReason.unexpected)
              .having((e) => e.error, 'error', equals(genericException))),
        );
      });
    });

    group('Transaction & Atomicity', () {
      group('Created Document Fields', () {
        test('should write every field for meta, goals, and log', () async {
          const year = 2030;

          // Use a set of goals tied to this test's year.
          final goalsForThisYear = List.generate(12, (index) {
            final uuid =
                '10000000-0000-0000-0000-${(index + 1).toString().padLeft(12, '0')}';
            return MonthlyRevenueGoalRemoteModel.fromMap({
              MonthlyRevenueGoalRemoteSchemaV1.uuidV7: uuid,
              MonthlyRevenueGoalRemoteSchemaV1.month: index + 1,
              MonthlyRevenueGoalRemoteSchemaV1.year: year,
              MonthlyRevenueGoalRemoteSchemaV1.targetCents: 50000 + index,
              MonthlyRevenueGoalRemoteSchemaV1.progressCents: 100 + index,
              MonthlyRevenueGoalRemoteSchemaV1.currencyCode: 'USD',
              MonthlyRevenueGoalRemoteSchemaV1.schemaVersion:
                  MonthlyRevenueGoalCurrentSchema.version,
            });
          });

          await dataSource.createMonthlyGoalsForYear(
            year: year,
            goals: goalsForThisYear,
            log: mockLog,
          );

          // 1) Meta doc: assert the whole payload.
          final metaSnap = await fakeFirestore
              .collection(fakeConfig.annualRevenueGoalsMetaCollection)
              .doc('$year')
              .get();
          expect(metaSnap.exists, isTrue);
          expect(
            metaSnap.data(),
            equals({
              'year': year,
              'schema_version': 1,
            }),
          );

          // 2) Goals docs: assert ids and full map.
          for (final goal in goalsForThisYear) {
            final goalSnap = await fakeFirestore
                .collection(fakeConfig.monthlyRevenueGoalsCollection)
                .doc(goal.uuidV7.value)
                .get();
            expect(goalSnap.exists, isTrue);
            expect(goalSnap.data(), equals(goal.toMap()));
          }

          // 3) Log doc: assert all fields and that occurred_at is set.
          final logId = mockLog.uuidV7.value;
          final logSnap = await fakeFirestore
              .collection(fakeConfig.goalsActionLogsCollection)
              .doc(logId)
              .get();
          expect(logSnap.exists, isTrue);
          final logData = logSnap.data()!;

          expect(logData.keys.toSet(), equals(mockLog.toMap().keys.toSet()));

          // Everything except occurred_at should be exactly what the model sent.
          final expectedLogData = Map<String, dynamic>.from(mockLog.toMap())
            ..remove(ActionLogModelCurrentSchema.occurredAt);
          final actualLogData = Map<String, dynamic>.from(logData)
            ..remove(ActionLogModelCurrentSchema.occurredAt);
          expect(actualLogData, equals(expectedLogData));

          // The data source must set the server timestamp.
          expect(logData[ActionLogModelCurrentSchema.occurredAt], isNotNull);
          expect(logData[ActionLogModelCurrentSchema.occurredAt],
              isA<Timestamp>());
        });
      });

      test('should succeed writing meta, goals, and log', () async {
        const year = 2024;
        await dataSource.createMonthlyGoalsForYear(
          year: year,
          goals: validGoalsList,
          log: mockLog,
        );

        // Verify Meta
        final metaSnap = await fakeFirestore
            .collection(fakeConfig.annualRevenueGoalsMetaCollection)
            .doc('$year')
            .get();
        expect(metaSnap.exists, isTrue);
        expect(metaSnap.data()!['year'], year);

        // Verify Goals
        final goalsQuery = await fakeFirestore
            .collection(fakeConfig.monthlyRevenueGoalsCollection)
            .get();
        expect(goalsQuery.docs.length, 12);

        // Verify Log
        final logSnap = await fakeFirestore
            .collection(fakeConfig.goalsActionLogsCollection)
            .doc(mockLog.uuidV7.value)
            .get();
        expect(logSnap.exists, isTrue);
        expect(
            logSnap.data()![ActionLogModelCurrentSchema.actionType], 'create');
      });

      test('should throw ServerException(conflict) if meta already exists',
          () async {
        const year = 2025;
        // Pre-create meta
        await fakeFirestore
            .collection(fakeConfig.annualRevenueGoalsMetaCollection)
            .doc('$year')
            .set({'year': year});

        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: year,
            goals: validGoalsList,
            log: mockLog,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.conflict,
          )),
        );
      });

      test('should NOT write goals if conflict error occurs inside transaction',
          () async {
        const year = 2025;
        // Pre-create meta to cause conflict
        await fakeFirestore
            .collection(fakeConfig.annualRevenueGoalsMetaCollection)
            .doc('$year')
            .set({'year': year});

        try {
          await dataSource.createMonthlyGoalsForYear(
            year: year,
            goals: validGoalsList,
            log: mockLog,
          );
        } catch (_) {}

        // Assert no goals written (besides pre-existing if any, but we started clean except meta)
        final goalsQuery = await fakeFirestore
            .collection(fakeConfig.monthlyRevenueGoalsCollection)
            .get();
        expect(
            goalsQuery.docs.length, 0); // None of the new goals should be there
      });
    });
  });
}
