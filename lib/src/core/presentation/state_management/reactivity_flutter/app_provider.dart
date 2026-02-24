import 'package:flutter/material.dart';

class AppProvider<VM> extends InheritedWidget {
  final VM viewModel;

  const AppProvider({
    super.key,
    required this.viewModel,
    required super.child,
  });

  static VM of<VM>(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppProvider<VM>>();
    if (provider == null) {
      throw FlutterError('AppProvider<$VM> não encontrado no contexto.');
    }
    return provider.viewModel;
  }

  @override
  bool updateShouldNotify(AppProvider<VM> oldWidget) =>
      viewModel != oldWidget.viewModel;
}

extension AppProviderExtension on BuildContext {
  T get<T>() => AppProvider.of<T>(this);
}
