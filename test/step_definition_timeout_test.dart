import 'package:gherkin_plus/gherkin_plus.dart';
import 'package:test/test.dart';

class _World extends World {}

void main() {
  group('maxStepDefinitionTimeout', () {
    test('uses the largest effective timeout plus the supplied buffer', () {
      final definitions = [
        given<_World>(
          'short timeout',
          (_) async {},
          configuration: StepDefinitionConfiguration()
            ..timeout = const Duration(seconds: 3),
        ),
        given<_World>(
          'long timeout',
          (_) async {},
          configuration: StepDefinitionConfiguration()
            ..timeout = const Duration(seconds: 8),
        ),
        given<_World>('inherited timeout', (_) async {}),
      ];

      expect(
        maxStepDefinitionTimeout(
          definitions,
          defaultTimeout: const Duration(seconds: 5),
          buffer: const Duration(seconds: 2),
        ),
        const Duration(seconds: 10),
      );
    });

    test('uses the default when the selection is empty', () {
      expect(
        maxStepDefinitionTimeout(
          const <StepDefinitionGeneric>[],
          defaultTimeout: const Duration(seconds: 5),
          buffer: const Duration(seconds: 1),
        ),
        const Duration(seconds: 6),
      );
    });

    test('does not apply the default to explicitly shorter timeouts', () {
      final definition = given<_World>(
        'explicit timeout',
        (_) async {},
        configuration: StepDefinitionConfiguration()
          ..timeout = const Duration(seconds: 2),
      );

      expect(
        maxStepDefinitionTimeout([
          definition,
        ], defaultTimeout: const Duration(seconds: 5)),
        const Duration(seconds: 2),
      );
    });
  });
}
