import 'package:bits_goals_module/strings/gen/goals_module_localizations.dart';
import 'package:flutter/material.dart';

class AppProvider<R> extends InheritedWidget {
  final R resource;

  const AppProvider({
    super.key,
    required this.resource,
    required super.child,
  });

  static R of<R>(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppProvider<R>>();
    if (provider == null) {
      throw FlutterError('AppProvider<$R> not found in context.');
    }
    return provider.resource;
  }

  @override
  bool updateShouldNotify(AppProvider<R> oldWidget) =>
      resource != oldWidget.resource;
}

extension AppProviderExtension on BuildContext {
  T get<T>() => AppProvider.of<T>(this);

  GoalsModuleLocalizations get strings => GoalsModuleLocalizations.of(this);
}
