// ignore_for_file: avoid_print

// This script runs all manual integration tests in the current directory
//
// To run this script, use the following command in your terminal:
// dart run test/manual_integration_tests/.run_all_manual_tests.dart

import 'dart:io';

void main() async {
  const filePrefix = 'mitest_';

  final currentScript = Platform.script.toFilePath();
  final currentDir = Directory(File(currentScript).parent.path);

  print('🔎 Searching tests in: ${currentDir.path}');
  print('Filter: files starting with "$filePrefix"');

  // List all files in the folder that match the prefix
  final files = currentDir
      .listSync()
      .whereType<File>()
      .where((file) =>
              file.path
                  .split(Platform.pathSeparator)
                  .last
                  .startsWith(filePrefix) &&
              file.path.endsWith('.dart') &&
              file.path != currentScript // Do not run itself
          )
      .toList();

  if (files.isEmpty) {
    print('⚠️ No test files found with the prefix "$filePrefix".');
    return;
  }

  print('Found ${files.length} tests. Starting execution...\n');
  int passed = 0;
  int failed = 0;
  final stopwatchTotal = Stopwatch()..start();

  for (final file in files) {
    final fileName = file.path.split(Platform.pathSeparator).last;

    print('------------------------------------------------------------');
    print('▶️  Running: $fileName');
    print('------------------------------------------------------------');

    final stopwatch = Stopwatch()..start();

    // Executes the process "dart file.dart"
    final result = await Process.run(
      'dart',
      [file.path],
      runInShell: true,
    );

    stopwatch.stop();

    // Shows the test output (what you printed)
    if (result.stdout.toString().isNotEmpty) {
      stdout.write(result.stdout);
    }

    // Checks if there was an error (exit code != 0 or output in stderr)
    if (result.exitCode != 0 || result.stderr.toString().isNotEmpty) {
      print('\n❌ TEST ERROR: $fileName');
      if (result.stderr.toString().isNotEmpty) {
        print('Error details:\n${result.stderr}');
      }
      failed++;
    } else {
      if (result.stdout.toString().contains('FAIL')) {
        print('\n⚠️  FAILURE DETECTED (Based on logs)');
        failed++;
      } else {
        passed++;
      }
    }
    print('\n⏱️  Time: ${stopwatch.elapsedMilliseconds}ms');
    print('');
  }

  stopwatchTotal.stop();

  print('============================================================');
  print('📊 EXECUTION SUMMARY');
  print('============================================================');
  print('TOTAL: ${files.length}');
  print('✅ SUCCESSES: $passed');
  print('❌ FAILURES:   $failed');
  print('⏱️  TOTAL TIME: ${stopwatchTotal.elapsed.inSeconds}s');

  if (failed > 0) exit(1); // Exit with error if any test failed
}
