import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/strings/gen/goals_module_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// Store Mock simples para testes de tipos
class _MockStore {
  final String id;
  _MockStore(this.id);
}

class _AnotherStore {}

void main() {
  group('AppProvider |', () {
    testWidgets('provides Store to the subtree via AppProvider.of',
        (tester) async {
      final st = _MockStore('st_1');
      _MockStore? capturedSt;

      await tester.pumpWidget(
        MaterialApp(
          home: AppProvider<_MockStore>(
            store: st,
            child: Builder(
              builder: (context) {
                capturedSt = AppProvider.of<_MockStore>(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(capturedSt, isNotNull);
      expect(capturedSt!.id, 'st_1');
      expect(capturedSt, st);
    });

    testWidgets('provides Store via context.st<T>() extension', (tester) async {
      final st = _MockStore('extension_test');
      _MockStore? capturedSt;

      await tester.pumpWidget(
        MaterialApp(
          home: AppProvider<_MockStore>(
            store: st,
            child: Builder(
              builder: (context) {
                capturedSt = context.get<_MockStore>();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(capturedSt, st);
    });

    testWidgets('throws FlutterError when provider is not found',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return const Text(
                'try access',
                key: Key('access_attempt'),
              );
            },
          ),
        ),
      );

      final context = tester.element(find.byKey(const Key('access_attempt')));

      expect(
        () => AppProvider.of<_MockStore>(context),
        throwsA(isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('AppProvider<_MockStore> not found in context'),
        )),
      );
    });

    testWidgets('distinguishes between different Store types in the tree',
        (tester) async {
      final st1 = _MockStore('1');
      final st2 = _AnotherStore();

      _MockStore? capturedSt1;
      _AnotherStore? capturedSt2;

      await tester.pumpWidget(
        MaterialApp(
          home: AppProvider<_MockStore>(
            store: st1,
            child: AppProvider<_AnotherStore>(
              store: st2,
              child: Builder(
                builder: (context) {
                  capturedSt1 = context.get<_MockStore>();
                  capturedSt2 = context.get<_AnotherStore>();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(capturedSt1, st1);
      expect(capturedSt2, st2);
    });

    testWidgets(
        'updateShouldNotify returns true only when Store instance changes',
        (tester) async {
      final st1 = _MockStore('A');
      final st2 = _MockStore('B');

      final provider1 = AppProvider<_MockStore>(
        store: st1,
        child: const SizedBox.shrink(),
      );

      final provider2 = AppProvider<_MockStore>(
        store: st1,
        child: const SizedBox.shrink(),
      );

      final provider3 = AppProvider<_MockStore>(
        store: st2,
        child: const SizedBox.shrink(),
      );

      expect(provider2.updateShouldNotify(provider1), isFalse);
      expect(provider3.updateShouldNotify(provider1), isTrue);
    });
  });

  group('AppProviderExtension - Localizations', () {
    testWidgets(
        'Should return GoalsModuleLocalizations instance from context.strings extension',
        (WidgetTester tester) async {
      late GoalsModuleLocalizations stringsResult;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GoalsModuleLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: GoalsModuleLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              stringsResult = context.strings;
              return const Placeholder();
            },
          ),
        ),
      );

      await tester.pump();

      expect(stringsResult, isA<GoalsModuleLocalizations>());
    });
  });
}
