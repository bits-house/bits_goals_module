import 'package:bits_goals_module/strings/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class AppProvider<ST> extends InheritedWidget {
  final ST store;

  const AppProvider({
    super.key,
    required this.store,
    required super.child,
  });

  static ST of<ST>(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppProvider<ST>>();
    if (provider == null) {
      throw FlutterError('AppProvider<$ST> not found in context.');
    }
    return provider.store;
  }

  @override
  bool updateShouldNotify(AppProvider<ST> oldWidget) =>
      store != oldWidget.store;
}

extension AppProviderExtension on BuildContext {
  T get<T>() => AppProvider.of<T>(this);

  AppLocalizations get strings => AppLocalizations.of(this);
}
