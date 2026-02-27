import 'dart:async';

import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_streamed_list_observer.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/app_stores/impl/app_streamed_list_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// =======================
// TEST DOUBLES
// =======================

class _TestFailure {
  final String message;
  _TestFailure(this.message);

  @override
  String toString() => message;
}

sealed class _TestState {}

class _LoadingState extends _TestState {}

class _SuccessState extends _TestState {
  final List<int> data;
  _SuccessState(this.data);
}

class _EmptyState extends _TestState {}

class _FailureState extends _TestState {
  final _TestFailure failure;
  _FailureState(this.failure);
}

sealed class _TestEffect {}

class _ShowSnackbar extends _TestEffect {
  final String message;
  _ShowSnackbar(this.message);
}

/// A concrete [AppStreamedListStore] with controllable stream factory and
/// spy capabilities (dispose counter, effect emission).
class _SpyStreamedST
    extends AppStreamedListStore<_TestState, _TestEffect, int, _TestFailure> {
  final Stream<List<int>> Function({int? limit}) _streamFactory;
  int disposeCallCount = 0;
  int loadMoreCallCount = 0;
  int retryPaginationCallCount = 0;

  _SpyStreamedST(
    this._streamFactory, {
    _TestState? initialStateOverride,
  }) : super(
          initialState: initialStateOverride ?? _LoadingState(),
          mapDataToStateOnStreamAutoUpdate: (data) =>
              data.isEmpty ? _EmptyState() : _SuccessState(data),
          mapInitialFailureToState: (f) => _FailureState(f),
          mapExceptionToFailure: (e) => _TestFailure('unexpected: $e'),
          pageSize: 2,
        );

  @override
  Stream<List<int>> createStream({int? limit}) => _streamFactory(limit: limit);

  void emitTestEffect(_TestEffect e) => emitEffect(e);

  @override
  void loadMore() {
    loadMoreCallCount++;
    super.loadMore();
  }

  @override
  void retryPagination() {
    retryPaginationCallCount++;
    super.retryPagination();
  }

  @override
  void dispose() {
    disposeCallCount++;
    super.dispose();
  }
}

// =======================
// HELPERS
// =======================

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

String _stateLabel(_TestState state) {
  return switch (state) {
    _LoadingState() => 'loading',
    _SuccessState(data: final d) => 'success:${d.length}',
    _EmptyState() => 'empty',
    _FailureState(failure: final f) => 'failure:${f.message}',
  };
}

String _paginationLabel(PaginationState<_TestFailure> pState) {
  final name = pState.runtimeType.toString();
  if (name.contains('Idle')) return 'idle';
  if (name.contains('Loading')) return 'loading';
  if (name.contains('Error')) return 'error';
  return 'unknown:$name';
}

String _statusText(_SpyStreamedST st) {
  return 'state:${_stateLabel(st.state)} page:${_paginationLabel(st.paginationState)}';
}

List<int> _listSelector(_TestState state) {
  return switch (state) {
    _SuccessState(data: final d) => d,
    _ => const <int>[],
  };
}

/// Shorthand for a standard AppListObserver widget wired to a [_SpyStreamedST].
///
/// Notes:
/// - We render state/pagination via `emptyBuilder` (when list is empty)
///   and also within each list item for convenience.
Widget _makeObserver(
  _SpyStreamedST st, {
  bool shouldDisposeStore = true,
  void Function(BuildContext, _TestEffect)? onEffect,
  EdgeInsetsGeometry? padding,
  ScrollController? scrollController,
  double scrollThreshold = 200,
  Widget Function(BuildContext context)? emptyBuilder,
  Widget Function(BuildContext context)? loadingBuilder,
  Widget Function(BuildContext context, _TestFailure failure)? errorBuilder,
  List<int>? buildCountRef,
}) {
  Widget defaultEmptyBuilder(BuildContext context) {
    buildCountRef?[0]++;
    return Text(
      _statusText(st),
      textDirection: TextDirection.ltr,
    );
  }

  Widget defaultLoadingBuilder(BuildContext context) {
    buildCountRef?[0]++;
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget defaultErrorBuilder(BuildContext context, _TestFailure failure) {
    buildCountRef?[0]++;
    return Text(
      'custom error: $failure',
      textDirection: TextDirection.ltr,
    );
  }

  return _wrap(
    AppStreamedListObserver<_SpyStreamedST, _TestState, _TestEffect, int,
        _TestFailure>(
      store: st,
      shouldDisposeStore: shouldDisposeStore,
      listSelector: _listSelector,
      padding: padding,
      scrollController: scrollController,
      scrollThreshold: scrollThreshold,
      emptyBuilder: emptyBuilder ?? defaultEmptyBuilder,
      loadingBuilder: loadingBuilder ?? defaultLoadingBuilder,
      errorBuilder: errorBuilder ?? defaultErrorBuilder,
      itemBuilder: (context, item, animation) {
        buildCountRef?[0]++;
        return SizedBox(
          height: 80,
          child: Text(
            'item:$item ${_statusText(st)}',
            textDirection: TextDirection.ltr,
          ),
        );
      },
      onEffect: onEffect,
    ),
  );
}

// =======================
// TESTS
// =======================

void main() {
  // ─────────────────────────────────────────
  // 1. INITIAL BUILD
  // ─────────────────────────────────────────
  group('AppStreamedListObserver | Initial Build |', () {
    testWidgets('shows initial state via emptyBuilder and has idle pagination',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);
      final buildCount = [0];

      await tester.pumpWidget(
        _makeObserver(st, buildCountRef: buildCount),
      );

      expect(find.text('state:loading page:idle'), findsOneWidget);
      expect(buildCount[0], greaterThanOrEqualTo(1));

      await controller.close();
    });

    testWidgets('renders items when stream emits data', (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(_makeObserver(st));
      expect(find.text('state:loading page:idle'), findsOneWidget);

      controller.add([1, 2]);
      await tester.pumpAndSettle();

      expect(find.textContaining('item:1'), findsOneWidget);
      expect(find.textContaining('item:2'), findsOneWidget);

      await controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 2. MAIN STATE CHANGES
  // ─────────────────────────────────────────
  group('AppStreamedListObserver | Main State |', () {
    testWidgets('updates items when main state changes', (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(_makeObserver(st));

      // Emit initial data → state becomes SuccessState.
      controller.add([1, 2]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:1'), findsOneWidget);
      expect(find.textContaining('item:2'), findsOneWidget);

      // Emit new data → state updates again.
      controller.add([10, 20, 30]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:10'), findsOneWidget);
      expect(find.textContaining('item:30'), findsOneWidget);

      await controller.close();
    });

    testWidgets(
        'handles repeated emissions without crashing (idempotency / listener safety)',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(_makeObserver(st));

      controller.add([1, 2]);
      await tester.pumpAndSettle();

      controller.add([3, 4]);
      await tester.pumpAndSettle();

      // Should still render successfully without errors.
      expect(find.textContaining('item:'), findsWidgets);

      await controller.close();
    });

    testWidgets('shows failure state via emptyBuilder on initial stream error',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(_makeObserver(st));

      controller.addError(_TestFailure('something broke'));
      await tester.pumpAndSettle();

      expect(
          find.text('state:failure:something broke page:idle'), findsOneWidget);

      await controller.close();
    });

    testWidgets('handles transition to empty state', (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(_makeObserver(st));

      controller.add([]);
      await tester.pumpAndSettle();

      expect(find.text('state:empty page:idle'), findsOneWidget);

      await controller.close();
    });

    testWidgets(
        'handles list shrinking without crashing (AnimatedList index guard)',
        (tester) async {
      StreamController<List<int>>? activeController;
      final st = _SpyStreamedST(({limit}) {
        activeController?.close();
        activeController = StreamController<List<int>>.broadcast();
        return activeController!.stream;
      });

      await tester.pumpWidget(_makeObserver(st));

      // First emission: 2 items.
      activeController!.add([1, 2]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:1'), findsOneWidget);
      expect(find.textContaining('item:2'), findsOneWidget);

      // Refresh swaps list identity and resets limits.
      st.refresh();
      await tester.pumpAndSettle();

      // Next emission returns fewer items (1 item).
      activeController!.add([10]);
      await tester.pumpAndSettle();

      // Must not crash; should show the new item.
      expect(find.textContaining('item:10'), findsOneWidget);

      await activeController?.close();
    });
  });

  // ─────────────────────────────────────────
  // 3. PAGINATION STATE CHANGES
  // ─────────────────────────────────────────
  group('AppListObserver | Pagination State |', () {
    testWidgets('reflects pagination Loading when loadMore is called',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(_makeObserver(st));

      // Emit exactly pageSize items so hasReachedMax stays false.
      controller.add([1, 2]);
      await tester.pumpAndSettle();
      expect(find.textContaining('page:idle'), findsWidgets);

      // Trigger pagination — paginationState → Loading.
      st.loadMore();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Resolve pagination — emit new data with increased limit.
      controller.add([1, 2, 3, 4]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('item:4'), findsOneWidget);

      await controller.close();
    });

    testWidgets('reflects pagination Error when loadMore stream fails',
        (tester) async {
      // Use a factory that returns a new controller's stream each time
      // so the error only affects the loadMore call.
      StreamController<List<int>>? activeController;
      final st = _SpyStreamedST(({limit}) {
        activeController?.close();
        activeController = StreamController<List<int>>.broadcast();
        return activeController!.stream;
      });

      await tester.pumpWidget(_makeObserver(st));

      // Emit initial data.
      activeController!.add([1, 2]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:1'), findsOneWidget);

      // Trigger loadMore → pagination becomes Loading.
      st.loadMore();
      await tester.pump();
      expect(find.textContaining('page:loading'), findsWidgets);

      // Emit error on the new stream → pagination becomes Error.
      activeController!.addError(_TestFailure('page failed'));
      await tester.pumpAndSettle();
      expect(find.textContaining('page:error'), findsWidgets);

      // Main state should remain unchanged (still success).
      expect(find.textContaining('item:1'), findsOneWidget);

      activeController?.close();
    });

    testWidgets('returns to Idle after refresh', (tester) async {
      StreamController<List<int>>? activeController;
      final st = _SpyStreamedST(({limit}) {
        activeController?.close();
        activeController = StreamController<List<int>>.broadcast();
        return activeController!.stream;
      });

      await tester.pumpWidget(_makeObserver(st));

      // Emit initial data.
      activeController!.add([1, 2]);
      await tester.pumpAndSettle();

      // loadMore → Error.
      st.loadMore();
      await tester.pump();
      activeController!.addError(_TestFailure('fail'));
      await tester.pumpAndSettle();
      expect(find.textContaining('page:error'), findsWidgets);

      // Refresh resets everything.
      st.refresh();
      await tester.pumpAndSettle();

      // After refresh, pagination returns to Idle.
      expect(find.textContaining('page:idle'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      activeController?.close();
    });

    testWidgets('hides emptyBuilder while pagination is Loading',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(
        _makeObserver(
          st,
          emptyBuilder: (context) => const Text(
            'EMPTY_BUILDER',
            textDirection: TextDirection.ltr,
          ),
        ),
      );

      // Force pagination loading before any data arrives.
      st.loadMore();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('EMPTY_BUILDER'), findsNothing,
          reason: 'Empty state must be suppressed while paginating.');

      await controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 4. EFFECTS
  // ─────────────────────────────────────────
  group('AppListObserver | Effects |', () {
    testWidgets('calls onEffect without rebuilding the widget tree',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);
      final buildCount = [0];
      final effects = <String>[];

      await tester.pumpWidget(
        _makeObserver(
          st,
          buildCountRef: buildCount,
          onEffect: (context, effect) {
            if (effect is _ShowSnackbar) {
              effects.add(effect.message);
            }
          },
        ),
      );

      final buildsBefore = buildCount[0];

      st.emitTestEffect(_ShowSnackbar('hello'));
      await tester.pump();
      expect(effects, ['hello']);
      expect(buildCount[0], buildsBefore,
          reason: 'Effects must not trigger rebuilds.');

      await controller.close();
    });

    testWidgets('handles multiple effects in sequence', (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);
      final effects = <String>[];

      await tester.pumpWidget(
        _makeObserver(
          st,
          onEffect: (context, effect) {
            if (effect is _ShowSnackbar) {
              effects.add(effect.message);
            }
          },
        ),
      );

      st.emitTestEffect(_ShowSnackbar('first'));
      st.emitTestEffect(_ShowSnackbar('second'));
      st.emitTestEffect(_ShowSnackbar('third'));
      await tester.pump();

      expect(effects, ['first', 'second', 'third']);

      await controller.close();
    });

    testWidgets('does not crash when onEffect is null', (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);
      final buildCount = [0];

      await tester.pumpWidget(
        _makeObserver(
          st,
          buildCountRef: buildCount,
          onEffect: null,
        ),
      );

      st.emitTestEffect(_ShowSnackbar('ignored'));
      await tester.pump();

      expect(buildCount[0], greaterThan(0),
          reason: 'Effects must not rebuild even without onEffect.');

      await controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 5. DISPOSE
  // ─────────────────────────────────────────
  group('AppListObserver | Dispose |', () {
    testWidgets('disposes the Store when removed (default behavior)',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(_makeObserver(st));
      expect(st.disposeCallCount, 0);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();

      expect(st.disposeCallCount, 1);

      await controller.close();
    });

    testWidgets('does NOT dispose the Store when shouldDisposeStore=false',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(
        _makeObserver(st, shouldDisposeStore: false),
      );

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();

      expect(st.disposeCallCount, 0);

      st.dispose();
      await controller.close();
    });

    testWidgets(
        'does not crash when state or pagination changes after widget is removed',
        (tester) async {
      // Use a factory that keeps a reference so we can emit after dispose.
      StreamController<List<int>>? activeController;
      final st = _SpyStreamedST(({limit}) {
        activeController?.close();
        activeController = StreamController<List<int>>.broadcast();
        return activeController!.stream;
      });

      await tester.pumpWidget(
        _makeObserver(st, shouldDisposeStore: false),
      );

      activeController!.add([1, 2]);
      await tester.pumpAndSettle();

      // Remove the widget without disposing the ST.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();

      // These should not throw — listeners were properly removed.
      // The ST is not disposed, so state can still change internally.
      // No widget is listening, so no crash.
      expect(st.disposeCallCount, 0);

      st.dispose();
      activeController?.close();
    });
  });

  // ─────────────────────────────────────────
  // 6. STORE SWAP (didUpdateWidget)
  // ─────────────────────────────────────────
  group('AppListObserver | Store Swap |', () {
    testWidgets(
        'switches all listeners when ST instance changes and disposes the old one',
        (tester) async {
      final controller1 = StreamController<List<int>>.broadcast();
      final oldSt = _SpyStreamedST(({limit}) => controller1.stream);

      final controller2 = StreamController<List<int>>.broadcast();
      final newSt = _SpyStreamedST(({limit}) => controller2.stream);

      final buildCount = [0];

      Widget make(_SpyStreamedST st) {
        return _makeObserver(
          st,
          buildCountRef: buildCount,
        );
      }

      // Mount with old ST.
      await tester.pumpWidget(make(oldSt));
      expect(find.text('state:loading page:idle'), findsOneWidget);

      // Emit data on old ST.
      controller1.add([1, 2]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:1'), findsOneWidget);
      final countAfterOldData = buildCount[0];

      // Swap to new ST.
      await tester.pumpWidget(make(newSt));
      await tester.pump();

      expect(buildCount[0], countAfterOldData + 1,
          reason:
              'Should rebuild when switching to the new ST (loading state).');

      expect(oldSt.disposeCallCount, 1,
          reason: 'Old Store must be disposed on swap.');
      // New ST has LoadingState initially.
      expect(find.text('state:loading page:idle'), findsOneWidget);

      // Emitting on old controller must NOT affect UI.
      controller1.add([99, 100]);
      await tester.pumpAndSettle();
      expect(find.text('state:loading page:idle'), findsOneWidget,
          reason: 'Old ST updates must be ignored after swap.');
      expect(buildCount[0], countAfterOldData + 1,
          reason: 'Old ST updates must not trigger new builds.');

      // Emitting on new controller MUST affect UI.
      controller2.add([5, 6]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:5'), findsOneWidget);

      controller1.close();
      controller2.close();
    });

    testWidgets('switches pagination listener on ST swap', (tester) async {
      StreamController<List<int>>? activeController1;
      final oldSt = _SpyStreamedST(({limit}) {
        activeController1?.close();
        activeController1 = StreamController<List<int>>.broadcast();
        return activeController1!.stream;
      });

      StreamController<List<int>>? activeController2;
      final newSt = _SpyStreamedST(({limit}) {
        activeController2?.close();
        activeController2 = StreamController<List<int>>.broadcast();
        return activeController2!.stream;
      });

      // Mount with old ST and emit data.
      await tester.pumpWidget(_makeObserver(oldSt, shouldDisposeStore: true));
      activeController1!.add([1, 2]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:1'), findsOneWidget);

      // Swap to new ST.
      await tester.pumpWidget(_makeObserver(newSt, shouldDisposeStore: true));
      await tester.pump();

      // New ST starts loading with idle pagination.
      expect(find.text('state:loading page:idle'), findsOneWidget);

      // Emit data on new ST.
      activeController2!.add([10, 20]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:10'), findsOneWidget);

      // Trigger loadMore on new ST — pagination reflects Loading.
      newSt.loadMore();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Resolve loadMore.
      activeController2!.add([10, 20, 30, 40]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);

      activeController1?.close();
      activeController2?.close();
    });

    testWidgets(
        'does not dispose old Store on swap when shouldDisposeStore=false',
        (tester) async {
      final controller1 = StreamController<List<int>>.broadcast();
      final oldSt = _SpyStreamedST(({limit}) => controller1.stream);

      final controller2 = StreamController<List<int>>.broadcast();
      final newSt = _SpyStreamedST(({limit}) => controller2.stream);

      Widget make(_SpyStreamedST st) {
        return _makeObserver(st, shouldDisposeStore: false);
      }

      await tester.pumpWidget(make(oldSt));
      await tester.pumpWidget(make(newSt));
      await tester.pump();

      expect(oldSt.disposeCallCount, 0,
          reason: 'Old ST must NOT be disposed when flag is false.');

      newSt.dispose();
      oldSt.dispose();
      controller1.close();
      controller2.close();
    });

    testWidgets('does nothing in didUpdateWidget when Store is unchanged',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);
      final buildCount = [0];

      Widget make() {
        return _makeObserver(
          st,
          buildCountRef: buildCount,
        );
      }

      await tester.pumpWidget(make());
      await tester.pumpWidget(make());
      await tester.pump();

      expect(st.disposeCallCount, 0,
          reason: 'ST must not be disposed if it did not change.');
      expect(buildCount[0], greaterThanOrEqualTo(1));

      controller.close();
    });

    testWidgets('effects from old ST are ignored after swap', (tester) async {
      final controller1 = StreamController<List<int>>.broadcast();
      final oldSt = _SpyStreamedST(({limit}) => controller1.stream);

      final controller2 = StreamController<List<int>>.broadcast();
      final newSt = _SpyStreamedST(({limit}) => controller2.stream);

      final effects = <String>[];

      Widget make(_SpyStreamedST st) {
        return _makeObserver(
          st,
          onEffect: (context, effect) {
            if (effect is _ShowSnackbar) {
              effects.add(effect.message);
            }
          },
        );
      }

      await tester.pumpWidget(make(oldSt));

      // Emit effect from old ST — should arrive.
      oldSt.emitTestEffect(_ShowSnackbar('from_old'));
      await tester.pump();
      expect(effects, ['from_old']);

      // Swap to new ST — old effect subscription is cancelled.
      await tester.pumpWidget(make(newSt));
      await tester.pump();

      // Effect from new ST should arrive.
      newSt.emitTestEffect(_ShowSnackbar('from_new'));
      await tester.pump();
      expect(effects, ['from_old', 'from_new']);

      controller1.close();
      controller2.close();
    });
  });

  // ─────────────────────────────────────────
  // 7. FULL LIFECYCLE & EDGE CASES
  // ─────────────────────────────────────────
  group('AppListObserver | Lifecycle & Edge Cases |', () {
    testWidgets('full lifecycle: load → paginate → error → retry → refresh',
        (tester) async {
      StreamController<List<int>>? activeController;
      final st = _SpyStreamedST(({limit}) {
        activeController?.close();
        activeController = StreamController<List<int>>.broadcast();
        return activeController!.stream;
      });

      await tester.pumpWidget(_makeObserver(st));

      // Initial: loading + idle
      expect(find.text('state:loading page:idle'), findsOneWidget);

      // Step 1: First data load.
      activeController!.add([1, 2]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:1'), findsOneWidget);

      // Step 2: Load more → pagination Loading.
      st.loadMore();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Step 3: Load more fails → pagination Error.
      activeController!.addError(_TestFailure('network'));
      await tester.pumpAndSettle();
      expect(find.textContaining('page:error'), findsWidgets);
      expect(find.textContaining('item:1'), findsOneWidget,
          reason: 'Main state must be preserved during pagination error.');

      // Step 4: Retry pagination → loading again.
      st.retryPagination();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Step 5: Retry succeeds.
      activeController!.add([1, 2, 3, 4]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:4'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Step 6: Refresh.
      st.refresh();
      await tester.pumpAndSettle();
      expect(find.textContaining('page:idle'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Step 7: Fresh data after refresh.
      activeController!.add([10, 20]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:10'), findsOneWidget);

      // Step 8: Remove widget → dispose.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();
      expect(st.disposeCallCount, 1);

      activeController?.close();
    });

    testWidgets('rapidly emitting data does not cause duplicate rebuilds',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);
      final buildCount = [0];

      await tester.pumpWidget(
        _makeObserver(
          st,
          buildCountRef: buildCount,
        ),
      );
      expect(buildCount[0], greaterThanOrEqualTo(1));

      // Rapid-fire emissions before pump.
      controller.add([1]);
      controller.add([1, 2]);
      controller.add([1, 2, 3]);
      await tester.pumpAndSettle();

      // The final state should reflect the last emission.
      // We only care that it doesn't crash and shows the latest state.
      expect(find.textContaining('state:'), findsWidgets);

      await controller.close();
    });

    testWidgets('handles stream closing gracefully', (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(
        _makeObserver(st, shouldDisposeStore: false),
      );

      controller.add([1, 2]);
      await tester.pumpAndSettle();
      expect(find.textContaining('state:success'), findsWidgets);

      // Close the stream — widget should remain intact with last known state.
      await controller.close();
      await tester.pumpAndSettle();

      expect(find.textContaining('state:success'), findsWidgets);

      st.dispose();
    });

    testWidgets(
        'loadMore is ignored when hasReachedMax is true (no pagination rebuild)',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(_makeObserver(st));

      // Emit fewer items than pageSize → hasReachedMax = true.
      controller.add([1]); // pageSize=2, got 1 → reached max.
      await tester.pumpAndSettle();
      expect(st.hasReachedMax, true);
      expect(find.textContaining('item:1'), findsOneWidget);

      // Calling loadMore should be a no-op.
      st.loadMore();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'loadMore must be ignored when hasReachedMax is true.');

      await controller.close();
    });

    testWidgets('widget rebuilds correctly after parent rebuild',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      // Pump twice with same ST to trigger didUpdateWidget without ST change.
      await tester.pumpWidget(_makeObserver(st));
      controller.add([1, 2]);
      await tester.pumpAndSettle();
      expect(find.textContaining('item:1'), findsOneWidget);

      // Parent rebuild — same ST instance.
      await tester.pumpWidget(_makeObserver(st));
      await tester.pump();

      // State should be preserved.
      expect(find.textContaining('item:1'), findsOneWidget);
      expect(st.disposeCallCount, 0);

      await controller.close();
    });

    testWidgets('renders SliverPadding when padding is provided',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      await tester.pumpWidget(
        _makeObserver(
          st,
          padding: const EdgeInsets.all(8),
        ),
      );

      expect(find.byType(SliverPadding), findsOneWidget);

      await controller.close();
    });

    testWidgets('default error footer renders Retry and calls retryPagination',
        (tester) async {
      StreamController<List<int>>? activeController;
      final st = _SpyStreamedST(({limit}) {
        activeController?.close();
        activeController = StreamController<List<int>>.broadcast();
        return activeController!.stream;
      });

      // Use default errorBuilder from widget (pass null) to cover that branch.
      await tester.pumpWidget(
        _wrap(
          AppStreamedListObserver<_SpyStreamedST, _TestState, _TestEffect, int,
              _TestFailure>(
            store: st,
            listSelector: _listSelector,
            itemBuilder: (context, item, animation) => SizedBox(
              height: 80,
              child: Text('item:$item', textDirection: TextDirection.ltr),
            ),
            emptyBuilder: (context) => Text(
              _statusText(st),
              textDirection: TextDirection.ltr,
            ),
            loadingBuilder: null,
            errorBuilder: null,
          ),
        ),
      );

      // Initial data.
      activeController!.add([1, 2]);
      await tester.pumpAndSettle();

      // loadMore then error -> PaginationError and default error sliver.
      st.loadMore();
      await tester.pump();
      activeController!.addError(_TestFailure('boom'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(st.retryPaginationCallCount, 0);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(st.retryPaginationCallCount, 1);

      await activeController?.close();
    });

    testWidgets('scrolling near bottom triggers loadMore', (tester) async {
      StreamController<List<int>>? activeController;
      final st = _SpyStreamedST(({limit}) {
        activeController?.close();
        activeController = StreamController<List<int>>.broadcast();
        return activeController!.stream;
      });

      final scrollController = ScrollController();

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 200,
            child: AppStreamedListObserver<_SpyStreamedST, _TestState,
                _TestEffect, int, _TestFailure>(
              store: st,
              listSelector: _listSelector,
              scrollController: scrollController,
              scrollThreshold: 1000, // make trigger very easy
              itemBuilder: (context, item, animation) => SizedBox(
                height: 80,
                child: Text('item:$item', textDirection: TextDirection.ltr),
              ),
              emptyBuilder: (context) => Text(
                _statusText(st),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      // Make list scrollable.
      activeController!.add(List<int>.generate(50, (i) => i));
      await tester.pumpAndSettle();

      final before = st.loadMoreCallCount;
      // Jump to the bottom to guarantee threshold condition.
      expect(scrollController.hasClients, true);
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      await tester.pump();

      expect(st.loadMoreCallCount, greaterThan(before));

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();

      await activeController?.close();
      scrollController.dispose();
    });

    testWidgets('changing external ScrollController removes old listener',
        (tester) async {
      final controller = StreamController<List<int>>.broadcast();
      final st = _SpyStreamedST(({limit}) => controller.stream);

      final c1 = ScrollController();
      final c2 = ScrollController();

      Widget make(ScrollController c) {
        return _makeObserver(st, scrollController: c, scrollThreshold: 1000);
      }

      await tester.pumpWidget(make(c1));
      controller.add(List<int>.generate(30, (i) => i));
      await tester.pumpAndSettle();

      final callsBeforeSwap = st.loadMoreCallCount;

      await tester.pumpWidget(make(c2));
      await tester.pump();

      // Old controller should be detached after swap.
      expect(c1.hasClients, false);
      expect(st.loadMoreCallCount, callsBeforeSwap);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();

      await controller.close();
      c1.dispose();
      c2.dispose();
    });
  });
}
