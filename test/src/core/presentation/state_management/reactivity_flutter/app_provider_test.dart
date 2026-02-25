import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/strings/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// ViewModel Mock simples para testes de tipos
class _MockViewModel {
  final String id;
  _MockViewModel(this.id);
}

class _AnotherViewModel {}

void main() {
  group('AppProvider |', () {
    testWidgets('provides ViewModel to the subtree via AppProvider.of',
        (tester) async {
      final vm = _MockViewModel('vm_1');
      _MockViewModel? capturedVm;

      await tester.pumpWidget(
        MaterialApp(
          home: AppProvider<_MockViewModel>(
            viewModel: vm,
            child: Builder(
              builder: (context) {
                capturedVm = AppProvider.of<_MockViewModel>(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(capturedVm, isNotNull);
      expect(capturedVm!.id, 'vm_1');
      expect(capturedVm, vm);
    });

    testWidgets('provides ViewModel via context.vm<T>() extension',
        (tester) async {
      final vm = _MockViewModel('extension_test');
      _MockViewModel? capturedVm;

      await tester.pumpWidget(
        MaterialApp(
          home: AppProvider<_MockViewModel>(
            viewModel: vm,
            child: Builder(
              builder: (context) {
                capturedVm = context.get<_MockViewModel>();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(capturedVm, vm);
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
        () => AppProvider.of<_MockViewModel>(context),
        throwsA(isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('AppProvider<_MockViewModel> não encontrado no contexto'),
        )),
      );
    });

    testWidgets('distinguishes between different ViewModel types in the tree',
        (tester) async {
      final vm1 = _MockViewModel('1');
      final vm2 = _AnotherViewModel();

      _MockViewModel? capturedVm1;
      _AnotherViewModel? capturedVm2;

      await tester.pumpWidget(
        MaterialApp(
          home: AppProvider<_MockViewModel>(
            viewModel: vm1,
            child: AppProvider<_AnotherViewModel>(
              viewModel: vm2,
              child: Builder(
                builder: (context) {
                  capturedVm1 = context.get<_MockViewModel>();
                  capturedVm2 = context.get<_AnotherViewModel>();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(capturedVm1, vm1);
      expect(capturedVm2, vm2);
    });

    testWidgets(
        'updateShouldNotify returns true only when ViewModel instance changes',
        (tester) async {
      final vm1 = _MockViewModel('A');
      final vm2 = _MockViewModel('B');

      final provider1 = AppProvider<_MockViewModel>(
        viewModel: vm1,
        child: const SizedBox.shrink(),
      );

      final provider2 = AppProvider<_MockViewModel>(
        viewModel: vm1,
        child: const SizedBox.shrink(),
      );

      final provider3 = AppProvider<_MockViewModel>(
        viewModel: vm2,
        child: const SizedBox.shrink(),
      );

      expect(provider2.updateShouldNotify(provider1), isFalse);
      expect(provider3.updateShouldNotify(provider1), isTrue);
    });
  });

  group('AppProviderExtension - Localizations', () {
    testWidgets(
        'Should return AppLocalizations instance from context.strings extension',
        (WidgetTester tester) async {
      late AppLocalizations stringsResult;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              stringsResult = context.strings;
              return const Placeholder();
            },
          ),
        ),
      );

      await tester.pump();

      expect(stringsResult, isA<AppLocalizations>());
    });
  });
}
