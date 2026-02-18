import 'dart:async';
import 'package:flutter/material.dart';
// Certifique-se de importar o caminho correto do seu ViewModel e Estados
import 'package:bits_goals_module/src/core/presentation/state_management/view_model/impl/app_streamed_list_view_model.dart';

/// A self-contained, reactive Observer for [AppStreamedListViewModel] with built-in Infinite Scroll.
///
/// It automatically handles:
/// 1. **Data Binding**: Listens to state changes and updates the UI.
/// 2. **Animations**: Calculates diffs and animates insertions in [SliverAnimatedList].
/// 3. **Pagination UI**: Renders Loading/Error footers based on [PaginationState].
/// 4. **Infinite Scroll**: Detects scroll position and calls [viewModel.loadMore] automatically.
class AppListObserver<VM extends AppStreamedListViewModel<S, E, T, F>, S, E, T,
    F> extends StatefulWidget {
  final VM viewModel;

  /// Function to extract the List<T> from your main State <S>.
  final List<T> Function(S state) listSelector;

  /// Builder for the animated list items.
  final Widget Function(
      BuildContext context, T item, Animation<double> animation) itemBuilder;

  /// Builder for the Pagination Loading state (footer).
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for the Pagination Error state (footer).
  final Widget Function(BuildContext context, F failure)? errorBuilder;

  /// Builder for the Empty state.
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Animation duration for insertions.
  final Duration animationDuration;

  /// Whether to dispose the ViewModel when this widget is disposed.
  final bool shouldDisposeViewModel;

  /// Callback for side effects.
  final void Function(BuildContext context, E effect)? onEffect;

  /// Optional ScrollController. If null, an internal one is created.
  final ScrollController? scrollController;

  /// Distance from the bottom (in pixels) to trigger [loadMore].
  /// Defaults to 200.0.
  final double scrollThreshold;

  final EdgeInsetsGeometry? padding;

  const AppListObserver({
    super.key,
    required this.viewModel,
    required this.listSelector,
    required this.itemBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
    this.shouldDisposeViewModel = true,
    this.onEffect,
    this.scrollController,
    this.scrollThreshold = 200.0,
    this.padding,
  });

  @override
  State<AppListObserver<VM, S, E, T, F>> createState() =>
      _AppListObserverState<VM, S, E, T, F>();
}

class _AppListObserverState<VM extends AppStreamedListViewModel<S, E, T, F>, S,
    E, T, F> extends State<AppListObserver<VM, S, E, T, F>> {
  late GlobalKey<SliverAnimatedListState> _listKey;

  late ScrollController _scrollController;
  bool _isInternalScrollController = false;

  late S _currentState;
  late PaginationState<F> _currentPaginationState;
  StreamSubscription<E>? _effectSubscription;

  // Diffing snapshots
  int _lastItemCount = 0;
  Object? _lastListIdentity;

  @override
  void initState() {
    super.initState();
    _listKey = GlobalKey<SliverAnimatedListState>();
    _initScrollController();
    _bind(widget.viewModel);
  }

  @override
  void didUpdateWidget(covariant AppListObserver<VM, S, E, T, F> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _unbind(oldWidget.viewModel, disposeVM: oldWidget.shouldDisposeViewModel);
      _bind(widget.viewModel);
    }
    // Handle external controller changes
    if (oldWidget.scrollController != widget.scrollController) {
      _disposeScrollController();
      _initScrollController();
    }
  }

  @override
  void dispose() {
    _unbind(widget.viewModel, disposeVM: widget.shouldDisposeViewModel);
    _disposeScrollController();
    super.dispose();
  }

  // ================= SCROLL LOGIC =================

  void _initScrollController() {
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
      _isInternalScrollController = false;
    } else {
      _scrollController = ScrollController();
      _isInternalScrollController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  void _disposeScrollController() {
    _scrollController.removeListener(_onScroll);
    if (_isInternalScrollController) {
      _scrollController.dispose();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Check if we are near the bottom
    if (maxScroll - currentScroll <= widget.scrollThreshold) {
      // The ViewModel handles the "isLoading" check internally,
      // so we can safely call this multiple times.
      widget.viewModel.loadMore();
    }
  }

  // ================= BINDING LOGIC =================

  void _bind(VM viewModel) {
    _currentState = viewModel.state;
    _currentPaginationState = viewModel.paginationState;
    _lastItemCount = viewModel.currentItemCount;
    _lastListIdentity = viewModel.listIdentity;

    viewModel.addStateListener(_onStateChanged);
    viewModel.addPaginationStateListener(_onPaginationChanged);

    _effectSubscription = viewModel.effects.listen((effect) {
      if (mounted) widget.onEffect?.call(context, effect);
    });
  }

  void _unbind(VM viewModel, {required bool disposeVM}) {
    _effectSubscription?.cancel();
    viewModel.removeStateListener(_onStateChanged);
    viewModel.removePaginationStateListener(_onPaginationChanged);
    if (disposeVM) viewModel.dispose();
  }

  // ================= LISTENERS =================

  void _onStateChanged() {
    if (!mounted) return;

    final vm = widget.viewModel;
    final newIdentity = vm.listIdentity;
    final newList = widget.listSelector(vm.state);
    final currentItemCount = newList.length;

    final isSameList = _lastListIdentity == newIdentity;

    // If the list identity changed (e.g. initial load, refresh, full reload),
    // we need to recreate the SliverAnimatedList so it picks up the new
    // `initialItemCount`. Otherwise, AnimatedList's internal state would keep
    // the old item count and the UI would never show the new items.
    if (!isSameList) {
      _listKey = GlobalKey<SliverAnimatedListState>();
    }

    final hasNewItems = currentItemCount > _lastItemCount;

    if (isSameList && hasNewItems) {
      final itemsToAdd = currentItemCount - _lastItemCount;
      for (int i = 0; i < itemsToAdd; i++) {
        _listKey.currentState?.insertItem(
          _lastItemCount + i,
          duration: widget.animationDuration,
        );
      }
    }

    _lastItemCount = currentItemCount;
    _lastListIdentity = newIdentity;

    if (vm.state != _currentState) {
      setState(() => _currentState = vm.state);
    }
  }

  void _onPaginationChanged() {
    if (!mounted) return;
    if (widget.viewModel.paginationState != _currentPaginationState) {
      setState(
          () => _currentPaginationState = widget.viewModel.paginationState);
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final items = widget.listSelector(_currentState);
    final isEmpty = items.isEmpty;

    return CustomScrollView(
      controller: _scrollController, // Uses the managed controller
      slivers: [
        if (widget.padding != null)
          SliverPadding(
            padding: widget.padding!,
            sliver: _buildAnimatedList(items),
          ),
        if (widget.padding == null) _buildAnimatedList(items),
        _buildPaginationSliver(),
        if (isEmpty && _shouldShowEmptyState())
          if (widget.emptyBuilder != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: widget.emptyBuilder!(context),
            ),
      ],
    );
  }

  Widget _buildAnimatedList(List<T> items) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: items.length,
      itemBuilder: (context, index, animation) {
        if (index >= items.length) return const SizedBox.shrink();
        return widget.itemBuilder(context, items[index], animation);
      },
    );
  }

  Widget _buildPaginationSliver() {
    return switch (_currentPaginationState) {
      PaginationIdle() => const SliverToBoxAdapter(child: SizedBox.shrink()),
      PaginationLoading() => SliverToBoxAdapter(
          child: widget.loadingBuilder?.call(context) ??
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
        ),
      PaginationError(failure: final failure) => SliverToBoxAdapter(
          child: widget.errorBuilder?.call(context, failure) ??
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Text('Error: $failure'),
                      TextButton(
                        onPressed: widget.viewModel.retryPagination,
                        child: const Text("Retry"),
                      )
                    ],
                  ),
                ),
              ),
        ),
    };
  }

  bool _shouldShowEmptyState() {
    return switch (_currentPaginationState) {
      PaginationLoading() => false,
      _ => true
    };
  }
}
