import 'package:bits_goals_module/src/core/platform/network_info_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mocktail/mocktail.dart';

// =============================================================================
// MOCKS
// =============================================================================

class MockInternetConnection extends Mock implements InternetConnection {}

// =============================================================================
// TEST SUITE
// =============================================================================

void main() {
  late NetworkInfoImpl networkInfo;
  late MockInternetConnection mockInternetConnection;

  setUp(() {
    mockInternetConnection = MockInternetConnection();
    networkInfo = NetworkInfoImpl(mockInternetConnection);
  });

  group('NetworkInfoImpl', () {
    test(
      'should return [true] when the call to InternetConnection.hasInternetAccess is true',
      () async {
        // Arrange
        when(() => mockInternetConnection.hasInternetAccess)
            .thenAnswer((_) async => true);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, true);
        verify(() => mockInternetConnection.hasInternetAccess).called(1);
        verifyNoMoreInteractions(mockInternetConnection);
      },
    );

    test(
      'should return [false] when the call to InternetConnection.hasInternetAccess is false',
      () async {
        // Arrange
        when(() => mockInternetConnection.hasInternetAccess)
            .thenAnswer((_) async => false);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, false);

        verify(() => mockInternetConnection.hasInternetAccess).called(1);
        verifyNoMoreInteractions(mockInternetConnection);
      },
    );

    test(
      'should propagate exception when the call to InternetConnection throws',
      () async {
        // Arrange
        final tException = Exception('Platform channel failure');
        when(() => mockInternetConnection.hasInternetAccess)
            .thenThrow(tException);

        // Act
        call() => networkInfo.isConnected;

        // Assert
        expect(call, throwsException);
        verify(() => mockInternetConnection.hasInternetAccess).called(1);
      },
    );
  });
}
