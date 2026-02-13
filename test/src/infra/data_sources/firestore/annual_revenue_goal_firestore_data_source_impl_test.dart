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

// Mocks
class MockMonthlyRevenueGoalRemoteModel extends Mock
    implements MonthlyRevenueGoalRemoteModel {}

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
  late List<MockMonthlyRevenueGoalRemoteModel> validGoalsList;

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
    when(() => mockLog.uuidV7).thenReturn(FakeIdUuidV7('log-id'));
    when(() => mockLog.toMap()).thenReturn({'action': 'create'});

    // Create a list of 12 goals
    validGoalsList = List.generate(12, (index) {
      final goal = MockMonthlyRevenueGoalRemoteModel();
      when(() => goal.uuidV7).thenReturn(FakeIdUuidV7('goal-$index'));
      when(() => goal.toMap()).thenReturn({'month': index + 1});
      return goal;
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
            .doc('log-id')
            .get();
        expect(logSnap.exists, isTrue);
        expect(logSnap.data()!['action'], 'create');
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
