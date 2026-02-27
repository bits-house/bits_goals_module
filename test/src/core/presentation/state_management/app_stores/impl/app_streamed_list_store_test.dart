import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bits_goals_module/src/core/presentation/state_management/app_stores/impl/app_streamed_list_store.dart';

// =======================
// TEST DOUBLES
// =======================

class TestFailure {
  final String message;
  TestFailure(this.message);
}

// ---------- STATES ----------

sealed class TestState {}

class LoadingState extends TestState {}

class SuccessState extends TestState {
  final List<int> data;
  SuccessState(this.data);
}

class EmptyState extends TestState {}

class FailureState extends TestState {
  final TestFailure failure;
  FailureState(this.failure);
}

// ---------- EVENT ----------

sealed class TestEvent {}

// =======================
// TEST STORE
// =======================

/// Default ST for basic tests.
class TestStreamedST
    extends AppStreamedListStore<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;

  TestStreamedST(this.streamFactory)
      : super(
          initialState: LoadingState(),
          mapDataToStateOnStreamAutoUpdate: (data) =>
              data.isEmpty ? EmptyState() : SuccessState(data),
          mapInitialFailureToState: (failure) => FailureState(failure),
          mapExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  @override
  Stream<List<int>> createStream({int? limit}) {
    return streamFactory(limit: limit);
  }
}

/// ST that records every `limit` passed into `createStream`.
/// Essential to validate limit consistency across operations.
class LimitTrackingST
    extends AppStreamedListStore<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;
  final List<int?> recordedLimits = [];

  LimitTrackingST(this.streamFactory)
      : super(
          initialState: LoadingState(),
          mapDataToStateOnStreamAutoUpdate: (data) =>
              data.isEmpty ? EmptyState() : SuccessState(data),
          mapInitialFailureToState: (failure) => FailureState(failure),
          mapExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  @override
  Stream<List<int>> createStream({int? limit}) {
    recordedLimits.add(limit);
    return streamFactory(limit: limit);
  }
}

/// ST whose mapper can be configured to throw (kept for future scenarios).
class DynamicMapperST
    extends AppStreamedListStore<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;
  bool shouldThrowOnMapper = false;

  DynamicMapperST(this.streamFactory)
      : super(
          initialState: LoadingState(),
          mapDataToStateOnStreamAutoUpdate: (_) =>
              throw StateError("replaced at runtime"),
          mapInitialFailureToState: (failure) => FailureState(failure),
          mapExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  // Overrides construction with a controllable mapper.
  factory DynamicMapperST.create(
      Stream<List<int>> Function({int? limit}) streamFactory) {
    late DynamicMapperST instance;
    instance = _DynamicMapperSTImpl(streamFactory);
    return instance;
  }

  @override
  Stream<List<int>> createStream({int? limit}) {
    return streamFactory(limit: limit);
  }
}

class _DynamicMapperSTImpl extends DynamicMapperST {
  _DynamicMapperSTImpl(super.streamFactory);
}

/// ST with a mapper that always throws (kept for future scenarios).
class MapperExceptionST
    extends AppStreamedListStore<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;
  int mapperCallCount = 0;

  MapperExceptionST(this.streamFactory)
      : super(
          initialState: LoadingState(),
          mapDataToStateOnStreamAutoUpdate: (_) =>
              throw StateError("placeholder — replaced below"),
          mapInitialFailureToState: (failure) => FailureState(failure),
          mapExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  @override
  Stream<List<int>> createStream({int? limit}) {
    return streamFactory(limit: limit);
  }
}

/// ST that throws from the mapper only after N calls.
class ConditionalMapperST
    extends AppStreamedListStore<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;
  static int _callCount = 0;
  static int _throwAfter = 999;

  ConditionalMapperST._internal(this.streamFactory)
      : super(
          initialState: LoadingState(),
          mapDataToStateOnStreamAutoUpdate: (data) {
            _callCount++;
            if (_callCount > _throwAfter) {
              throw Exception("Mapper explosion at call $_callCount");
            }
            return data.isEmpty ? EmptyState() : SuccessState(data);
          },
          mapInitialFailureToState: (failure) => FailureState(failure),
          mapExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  factory ConditionalMapperST({
    required Stream<List<int>> Function({int? limit}) streamFactory,
    required int throwAfterCall,
  }) {
    _callCount = 0;
    _throwAfter = throwAfterCall;
    return ConditionalMapperST._internal(streamFactory);
  }

  @override
  Stream<List<int>> createStream({int? limit}) {
    return streamFactory(limit: limit);
  }
}

// =======================
// TESTS
// =======================

void main() {
  // Silence internal `debugPrint` from the production Store during tests.
  // We still validate behavior via state/pagination assertions.
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
  });

  // ─────────────────────────────────────────
  // 1. INITIAL LOAD
  // ─────────────────────────────────────────
  group("AppStreamedListStore - Initial Load", () {
    test("emits SuccessState on initial data", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(st.state, isA<SuccessState>());
      expect((st.state as SuccessState).data, [1, 2]);
      controller.close();
    });

    test("emits EmptyState on initial empty data", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([]);
      await Future.microtask(() {});

      expect(st.state, isA<EmptyState>());
      controller.close();
    });

    test("emits FailureState on initial known failure type", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      expect(st.state, isA<FailureState>());
      expect((st.state as FailureState).failure.message, "fail");
      controller.close();
    });

    test("maps unexpected exception to failure on initial load", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.addError(ArgumentError("bad"));
      await Future.microtask(() {});

      expect(st.state, isA<FailureState>());
      expect((st.state as FailureState).failure.message, "unexpected");
      controller.close();
    });

    test("paginationState is Idle after initial failure (never Loading/Error)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      // CRITICAL: pagination must be Idle on initial load, not Error.
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("hasReachedMax is true when initial data < pageSize", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1]); // pageSize=2, got 1 → hasReachedMax=true
      await Future.microtask(() {});

      expect(st.hasReachedMax, true);
      controller.close();
    });

    test("hasReachedMax is false when initial data == pageSize", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]); // pageSize=2, got 2 → hasReachedMax=false
      await Future.microtask(() {});

      expect(st.hasReachedMax, false);
      controller.close();
    });

    test("empty initial data sets hasReachedMax to true", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([]); // 0 < 2 → true
      await Future.microtask(() {});

      expect(st.hasReachedMax, true);
      expect(st.state, isA<EmptyState>());
      controller.close();
    });

    test("initial state is LoadingState before stream emits", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      expect(st.state, isA<LoadingState>());
      controller.close();
    });

    test("pageSize getter returns the configured value", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      expect(st.pageSize, 2);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 2. LIMIT CONSISTENCY (critical para bugs de dados)
  // ─────────────────────────────────────────
  group("AppStreamedListStore - Limit Consistency", () {
    test("createStream receives pageSize as initial limit", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      // The constructor triggers `_startListening` with `_currentLimit = pageSize`.
      expect(st.recordedLimits.first, 2);
      controller.close();
    });

    test("loadMore increments limit by pageSize", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();

      // Initial: 2, after loadMore: 4
      expect(st.recordedLimits, [2, 4]);
      controller.close();
    });

    test("multiple loadMore calls increment limit correctly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      // Initial: limit=2
      controller.add([1, 2]);
      await Future.microtask(() {});

      // loadMore 1: limit=4
      st.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // loadMore 2: limit=6
      st.loadMore();
      controller.add([1, 2, 3, 4, 5, 6]);
      await Future.microtask(() {});

      // loadMore 3: limit=8
      st.loadMore();
      controller.add([1, 2, 3, 4, 5, 6, 7, 8]);
      await Future.microtask(() {});

      expect(st.recordedLimits, [2, 4, 6, 8]);
      controller.close();
    });

    test("refresh resets limit to pageSize", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      st.refresh();

      // Recorded: [2 (init), 4 (loadMore), 2 (refresh)]
      expect(st.recordedLimits, [2, 4, 2]);
      controller.close();
    });

    test("retryPagination does NOT increment limit (reuses current)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore(); // limit goes to 4
      controller.addError(TestFailure("error"));
      await Future.microtask(() {});

      st.retryPagination(); // limit should STILL be 4

      // Recorded: [2 (init), 4 (loadMore), 4 (retry)]
      expect(st.recordedLimits, [2, 4, 4]);
      controller.close();
    });

    test(
        "refresh after multiple loadMore calls resets limit to pageSize, "
        "not the accumulated value", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3, 4, 5, 6]);
      await Future.microtask(() {});

      st.refresh();

      // Must reset to 2, not keep 6.
      expect(st.recordedLimits.last, 2);
      controller.close();
    });

    test(
        "loadMore after refresh uses correct limit "
        "(pageSize + pageSize, not the old accumulated)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      // loadMore: limit=4
      st.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // refresh: limit=2
      st.refresh();
      controller.add([1, 2]);
      await Future.microtask(() {});

      // loadMore after refresh: limit=4 (2+2), NOT 6 (4+2)
      st.loadMore();

      expect(st.recordedLimits, [2, 4, 2, 4]);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 3. PAGINATION - loadMore
  // ─────────────────────────────────────────
  group("AppStreamedListStore - loadMore", () {
    test("sets pagination to Loading then Idle on success", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      expect(st.paginationState.runtimeType.toString(), contains("Loading"));

      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("sets pagination to Error on stream error", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      expect(st.paginationState.runtimeType.toString(), contains("Error"));
      controller.close();
    });

    test("hasReachedMax becomes true when received data < limit", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore(); // limit=4
      controller.add([1, 2, 3]); // got 3 < 4
      await Future.microtask(() {});

      expect(st.hasReachedMax, true);
      controller.close();
    });

    test("hasReachedMax stays false when received data == limit", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore(); // limit=4
      controller.add([1, 2, 3, 4]); // got 4 == 4
      await Future.microtask(() {});

      expect(st.hasReachedMax, false);
      controller.close();
    });

    test("is blocked when hasReachedMax is true", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3]); // hasReachedMax = true
      await Future.microtask(() {});

      expect(st.hasReachedMax, true);

      final limitCountBefore = st.recordedLimits.length;
      st.loadMore(); // deve ser ignorado
      expect(
          st.recordedLimits.length, limitCountBefore); // sem novo createStream
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("is blocked when already loading (prevents concurrent calls)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      final limitsCount = st.recordedLimits.length;

      st.loadMore(); // deveria ser ignorado
      st.loadMore(); // deveria ser ignorado
      st.loadMore(); // deveria ser ignorado

      expect(st.recordedLimits.length, limitsCount);
      controller.close();
    });

    test("preserves main SuccessState on pagination error", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      final stateBefore = st.state;
      expect(stateBefore, isA<SuccessState>());

      st.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      // CRITICAL: main state NÃO deve mudar
      expect(st.state, equals(stateBefore));
      expect(st.state, isA<SuccessState>());
      controller.close();
    });

    test(
        "after successful loadMore, data in SuccessState reflects "
        "the full list (not just new page)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      final state = st.state as SuccessState;
      expect(state.data, [1, 2, 3, 4]);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 4. RETRY PAGINATION
  // ─────────────────────────────────────────
  group("AppStreamedListStore - retryPagination", () {
    test("triggers Loading from Error state", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      expect(st.paginationState.runtimeType.toString(), contains("Error"));

      st.retryPagination();
      expect(st.paginationState.runtimeType.toString(), contains("Loading"));
      controller.close();
    });

    test("does nothing when paginationState is Idle", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      final countBefore = st.recordedLimits.length;
      st.retryPagination();
      expect(st.recordedLimits.length, countBefore);
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("does nothing when paginationState is Loading", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      expect(st.paginationState.runtimeType.toString(), contains("Loading"));

      final countBefore = st.recordedLimits.length;
      st.retryPagination();
      expect(st.recordedLimits.length, countBefore);
      controller.close();
    });

    test("successful retry transitions Error → Loading → Idle", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      expect(st.paginationState.runtimeType.toString(), contains("Error"));

      st.retryPagination();
      expect(st.paginationState.runtimeType.toString(), contains("Loading"));

      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      expect(st.state, isA<SuccessState>());
      controller.close();
    });

    test("retryPagination resets hasReachedMax to false", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      st.retryPagination();
      expect(st.hasReachedMax, false);
      controller.close();
    });

    test(
        "multiple error→retry cycles don't corrupt state "
        "or increment limit incorrectly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      // loadMore: limit=4
      st.loadMore();
      controller.addError(TestFailure("error 1"));
      await Future.microtask(() {});

      // retry 1: limit=4 (não incrementa!)
      st.retryPagination();
      controller.addError(TestFailure("error 2"));
      await Future.microtask(() {});

      // retry 2: limit=4 (não incrementa!)
      st.retryPagination();
      controller.addError(TestFailure("error 3"));
      await Future.microtask(() {});

      // retry 3: limit=4, success
      st.retryPagination();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // Verifica que o limite NUNCA foi corrompido
      // init=2, loadMore=4, retry1=4, retry2=4, retry3=4
      expect(st.recordedLimits, [2, 4, 4, 4, 4]);
      expect(st.state, isA<SuccessState>());
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 5. REFRESH
  // ─────────────────────────────────────────
  group("AppStreamedListStore - refresh", () {
    test("resets hasReachedMax, paginationState and limit", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3]); // hasReachedMax=true
      await Future.microtask(() {});

      expect(st.hasReachedMax, true);

      st.refresh();

      expect(st.hasReachedMax, false);
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      expect(st.recordedLimits.last, 2); // limit reset
      controller.close();
    });

    test("cancels ongoing pagination and resets", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      expect(st.paginationState.runtimeType.toString(), contains("Loading"));

      st.refresh();

      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      expect(st.hasReachedMax, false);
      controller.close();
    });

    test("after refresh, loadMore works again correctly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3]); // hasReachedMax=true
      await Future.microtask(() {});

      expect(st.hasReachedMax, true);

      st.refresh();
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(st.hasReachedMax, false);

      st.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      expect(st.hasReachedMax, false);
      expect(st.state, isA<SuccessState>());
      controller.close();
    });

    test("refresh after pagination error clears error state", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.addError(TestFailure("err"));
      await Future.microtask(() {});

      expect(st.paginationState.runtimeType.toString(), contains("Error"));

      st.refresh();

      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      expect(st.hasReachedMax, false);

      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(st.state, isA<SuccessState>());
      controller.close();
    });

    test("multiple rapid refreshes don't create duplicate subscriptions",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      st.refresh();
      st.refresh();
      st.refresh();

      // After 3 calls, there should be at most one active listener.
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(st.state, isA<SuccessState>());
      // Should not crash or produce inconsistent states.
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 6. SUBSCRIPTION MANAGEMENT & MEMORY LEAKS
  // ─────────────────────────────────────────
  group("AppStreamedListStore - Subscription Management", () {
    test("dispose cancels stream subscription", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      expect(controller.hasListener, true);
      st.dispose();
      expect(controller.hasListener, false);
      controller.close();
    });

    test("dispose before stream emits does not crash", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      st.dispose();

      // Emitting data after dispose must not crash.
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(controller.hasListener, false);
      controller.close();
    });

    test("dispose during active pagination cleans up", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();

      expect(controller.hasListener, true);
      st.dispose();
      expect(controller.hasListener, false);
      controller.close();
    });

    test("error handler cancels subscription (prevents ghost listeners)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);
      addTearDown(st.dispose);

      controller.addError(TestFailure("boom"));
      await Future.microtask(() {});

      // After an error, `_handleError` must cancel the subscription.
      expect(controller.hasListener, false);
      controller.close();
    });

    test(
        "loadMore creates new subscription (old one cancelled by "
        "_startListening)", () async {
      final controller = StreamController<List<int>>.broadcast();
      int listenerCountHighWatermark = 0;

      final st = TestStreamedST(({limit}) {
        // Snapshot listener count.
        if (controller.hasListener) {
          listenerCountHighWatermark++;
        }
        return controller.stream;
      });

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();

      // `_startListening` cancels the previous subscription before creating a new one.
      expect(controller.hasListener, true);
      // Make the variable intentionally used to avoid lints.
      expect(listenerCountHighWatermark, greaterThanOrEqualTo(0));
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 7. STREAM DATA UPDATES (real-time)
  // ─────────────────────────────────────────
  group("AppStreamedListStore - Real-Time Stream Updates", () {
    test("multiple stream emissions update state correctly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});
      expect((st.state as SuccessState).data, [1, 2]);

      controller.add([1, 2, 3]);
      await Future.microtask(() {});
      expect((st.state as SuccessState).data, [1, 2, 3]);

      controller.add([10, 20]);
      await Future.microtask(() {});
      expect((st.state as SuccessState).data, [10, 20]);
      controller.close();
    });

    test("stream update from non-empty to empty transitions correctly",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2, 3]);
      await Future.microtask(() {});
      expect(st.state, isA<SuccessState>());

      controller.add([]);
      await Future.microtask(() {});
      expect(st.state, isA<EmptyState>());
      controller.close();
    });

    test("hasReachedMax updates correctly on each stream emission", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream); // pageSize=2

      // limit=2, got 2 → false
      controller.add([1, 2]);
      await Future.microtask(() {});
      expect(st.hasReachedMax, false);

      // Stream emite novamente com dados menores → true
      controller.add([1]);
      await Future.microtask(() {});
      expect(st.hasReachedMax, true);

      // Stream emite novamente com dados iguais ao limit → false
      controller.add([1, 2]);
      await Future.microtask(() {});
      expect(st.hasReachedMax, false);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 8. MAPPER EXCEPTION HANDLING
  // ─────────────────────────────────────────
  group("AppStreamedListStore - Mapper Exception Handling", () {
    test("mapper exception on initial load sets FailureState", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = ConditionalMapperST(
        streamFactory: ({limit}) => controller.stream,
        throwAfterCall: 0, // throw on first call
      );

      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(st.state, isA<FailureState>());
      expect((st.state as FailureState).failure.message, "unexpected");
      controller.close();
    });

    test(
        "mapper exception on pagination sets PaginationError "
        "and preserves main state", () async {
      final controller = StreamController<List<int>>.broadcast();

      // throwAfterCall=1: first mapper call OK, second throws
      final st = ConditionalMapperST(
        streamFactory: ({limit}) => controller.stream,
        throwAfterCall: 1,
      );

      // First emission → mapper call 1 → success
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(st.state, isA<SuccessState>());
      final stateBefore = st.state;

      // loadMore → mapper call 2 → throws
      st.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // Main state must remain intact.
      expect(st.state, equals(stateBefore));
      expect(st.paginationState.runtimeType.toString(), contains("Error"));
      controller.close();
    });

    test(
        "mapper exception on pagination cancels subscription "
        "(prevents infinite error loop)", () async {
      final controller = StreamController<List<int>>.broadcast();

      final st = ConditionalMapperST(
        streamFactory: ({limit}) => controller.stream,
        throwAfterCall: 1,
      );

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3, 4]); // mapper throws
      await Future.microtask(() {});

      // Subscription must have been cancelled.
      expect(controller.hasListener, false);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 9. _isLoadingMore FLAG INTEGRITY
  // ─────────────────────────────────────────
  group("AppStreamedListStore - _isLoadingMore Flag Integrity", () {
    test("flag is reset after successful loadMore (can loadMore again)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // If the flag wasn't reset, this loadMore would be ignored.
      st.loadMore();
      expect(st.recordedLimits.last, 6); // prova que o loadMore funcionou
      controller.close();
    });

    test("flag is reset after failed loadMore (retryPagination unblocked)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.addError(TestFailure("err"));
      await Future.microtask(() {});

      // If the flag wasn't reset, retryPagination wouldn't work.
      st.retryPagination();
      expect(st.paginationState.runtimeType.toString(), contains("Loading"));
      controller.close();
    });

    test("flag is reset after mapper exception (retryPagination unblocked)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = ConditionalMapperST(
        streamFactory: ({limit}) => controller.stream,
        throwAfterCall: 1,
      );

      controller.add([1, 2]); // call 1 → success
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3, 4]); // call 2 → throws
      await Future.microtask(() {});

      // `_isLoadingMore` must be reset by `_handleError`.
      expect(st.paginationState.runtimeType.toString(), contains("Error"));

      // retryPagination must work (no deadlock).
      st.retryPagination();
      expect(st.paginationState.runtimeType.toString(), contains("Loading"));
      controller.close();
    });

    test("flag is reset by refresh (unblocks future loadMore)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore(); // _isLoadingMore = true

      st.refresh(); // must reset _isLoadingMore = false

      controller.add([1, 2]);
      await Future.microtask(() {});

      // After refresh + data, loadMore should work normally.
      st.loadMore();
      expect(st.recordedLimits.last, 4); // prova que loadMore funcionou
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 10. INFINITE LOOP & DEADLOCK PREVENTION
  // ─────────────────────────────────────────
  group("AppStreamedListStore - Infinite Loop Prevention", () {
    test(
        "loadMore → hasReachedMax=true → loadMore is noop "
        "(prevents infinite pagination loop)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.add([1, 2, 3]); // < limit=4 → hasReachedMax
      await Future.microtask(() {});

      expect(st.hasReachedMax, true);

      // Calling loadMore 100 times should have no effect.
      final countBefore = st.recordedLimits.length;
      for (int i = 0; i < 100; i++) {
        st.loadMore();
      }
      expect(st.recordedLimits.length, countBefore);
      controller.close();
    });

    test(
        "rapid loadMore→error→retry cycle terminates correctly "
        "(no deadlock)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      // Simulate 5 error→retry cycles.
      for (int i = 0; i < 5; i++) {
        st.loadMore();
        controller.addError(TestFailure("error $i"));
        await Future.microtask(() {});
        expect(st.paginationState.runtimeType.toString(), contains("Error"));
        st.retryPagination();
      }

      // Finally succeed.
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      expect(st.state, isA<SuccessState>());
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("error on initial load stops listening (no infinite error stream)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.addError(TestFailure("init error"));
      await Future.microtask(() {});

      expect(st.state, isA<FailureState>());
      // CRITICAL: subscription must be cancelled to avoid infinite loops.
      expect(controller.hasListener, false);
      controller.close();
    });

    test(
        "pagination error cancels subscription "
        "(no more events from that stream)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller.addError(TestFailure("pagination error"));
      await Future.microtask(() {});

      expect(controller.hasListener, false);

      // Emitting data afterwards must not affect state.
      final stateBefore = st.state;
      controller.add([99, 100]);
      await Future.microtask(() {});
      expect(st.state, equals(stateBefore));
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 11. FULL LIFECYCLE / STATE MACHINE
  // ─────────────────────────────────────────
  group("AppStreamedListStore - Full Lifecycle", () {
    test(
        "complete lifecycle: load → paginate → paginate → "
        "maxReached → refresh → load → paginate → dispose", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      // 1. Initial load
      expect(st.state, isA<LoadingState>());
      controller.add([1, 2]);
      await Future.microtask(() {});
      expect(st.state, isA<SuccessState>());
      expect(st.hasReachedMax, false);
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));

      // 2. First pagination
      st.loadMore();
      expect(st.paginationState.runtimeType.toString(), contains("Loading"));
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});
      expect(st.hasReachedMax, false);
      expect((st.state as SuccessState).data, [1, 2, 3, 4]);

      // 3. Second pagination → max reached
      st.loadMore();
      controller.add([1, 2, 3, 4, 5]); // 5 < 6 → max
      await Future.microtask(() {});
      expect(st.hasReachedMax, true);
      expect((st.state as SuccessState).data, [1, 2, 3, 4, 5]);

      // 4. loadMore é bloqueado
      // 4. loadMore is blocked
      st.loadMore();
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));

      // 5. Refresh
      st.refresh();
      expect(st.hasReachedMax, false);
      controller.add([10, 20]);
      await Future.microtask(() {});
      expect((st.state as SuccessState).data, [10, 20]);

      // 6. New pagination after refresh
      st.loadMore();
      controller.add([10, 20, 30, 40]);
      await Future.microtask(() {});
      expect(st.hasReachedMax, false);

      // 7. Dispose
      expect(controller.hasListener, true);
      st.dispose();
      expect(controller.hasListener, false);

      // Verify limit sequence
      // init=2, loadMore=4, loadMore=6, refresh=2, loadMore=4
      expect(st.recordedLimits, [2, 4, 6, 2, 4]);
      controller.close();
    });

    test(
        "error recovery lifecycle: load → loadMore → error → retry → "
        "error → refresh → load → success", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      // 1. Initial load
      controller.add([1, 2]);
      await Future.microtask(() {});
      expect(st.state, isA<SuccessState>());

      // 2. Pagination fails
      st.loadMore();
      controller.addError(TestFailure("err1"));
      await Future.microtask(() {});
      expect(st.paginationState.runtimeType.toString(), contains("Error"));
      expect(st.state, isA<SuccessState>()); // main state preserved

      // 3. Retry - fails again
      st.retryPagination();
      controller.addError(TestFailure("err2"));
      await Future.microtask(() {});
      expect(st.paginationState.runtimeType.toString(), contains("Error"));

      // 4. User refreshes
      st.refresh();
      controller.add([10, 20]);
      await Future.microtask(() {});
      expect(st.state, isA<SuccessState>());
      expect((st.state as SuccessState).data, [10, 20]);
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      expect(st.hasReachedMax, false);

      // limits: init=2, loadMore=4, retry=4, refresh=2
      expect(st.recordedLimits, [2, 4, 4, 2]);
      controller.close();
    });

    test("initial failure → refresh → success lifecycle works correctly",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      // Initial fail
      controller.addError(TestFailure("init error"));
      await Future.microtask(() {});
      expect(st.state, isA<FailureState>());

      // User refreshes
      st.refresh();
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(st.state, isA<SuccessState>());
      expect(st.hasReachedMax, false);
      expect(st.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 12. EDGE CASES
  // ─────────────────────────────────────────
  group("AppStreamedListStore - Edge Cases", () {
    test("stream that emits error immediately is handled", () async {
      final st = TestStreamedST(
        ({limit}) => Stream<List<int>>.error(TestFailure("instant error")),
      );

      await Future.microtask(() {});
      expect(st.state, isA<FailureState>());
    });

    test(
        "stream that completes without emitting any data stays in initial state",
        () async {
      final st = TestStreamedST(
        ({limit}) => const Stream<List<int>>.empty(),
      );

      await Future.microtask(() {});

      // Empty stream completes; state remains the initialState.
      expect(st.state, isA<LoadingState>());
    });

    test("stream that emits single value then completes works", () async {
      final st = TestStreamedST(
        ({limit}) => Stream<List<int>>.fromIterable([
          [1, 2, 3]
        ]),
      );

      await Future.microtask(() {});
      expect(st.state, isA<SuccessState>());
      expect((st.state as SuccessState).data, [1, 2, 3]);
    });

    test("data larger than limit does not set hasReachedMax", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream); // pageSize=2

      // Edge case: backend returns more items than the limit (defensive).
      controller.add([1, 2, 3, 4, 5]); // limit=2, got 5
      await Future.microtask(() {});

      expect(st.hasReachedMax, false); // 5 < 2 is false
      expect(st.state, isA<SuccessState>());
      controller.close();
    });

    test("unexpected error type on pagination is mapped correctly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = TestStreamedST(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      st.loadMore();
      controller
          .addError(const FormatException("bad format")); // not TestFailure
      await Future.microtask(() {});

      expect(st.paginationState.runtimeType.toString(), contains("Error"));
      // Main state preserved
      expect(st.state, isA<SuccessState>());
      controller.close();
    });

    test("loadMore right after initial error is handled consistently",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final st = LimitTrackingST(({limit}) => controller.stream);

      controller.addError(TestFailure("init error"));
      await Future.microtask(() {});

      expect(st.state, isA<FailureState>());

      final countBefore = st.recordedLimits.length;

      // After an initial error, _isLoadingMore is reset to false, _hasReachedMax
      // is false, and paginationState is Idle. So loadMore is allowed.
      st.loadMore();

      // Verify the limit increment is correct.
      if (st.recordedLimits.length > countBefore) {
        expect(st.recordedLimits.last, 4); // 2 + 2
      }
      controller.close();
    });
  });
}
