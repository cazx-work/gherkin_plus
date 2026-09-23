import 'package:gherkin_plus/gherkin.dart';
import 'package:test/test.dart';

class _World extends World {}

class _FirstGroup implements StepDefinitionGroup<_World> {
  @override
  Iterable<StepDefinitionGeneric<_World>> get definitions => [
    given<_World>('first step', (_) async {}),
  ];
}

class _SecondGroup implements StepDefinitionGroup<_World> {
  @override
  Iterable<StepDefinitionGeneric<_World>> get definitions => [
    when<_World>('second step', (_) async {}),
  ];
}

void main() {
  test('flattens groups in registration order', () {
    final definitions = flattenStepDefinitionGroups<_World>([
      _FirstGroup(),
      _SecondGroup(),
    ]);

    expect(
      definitions.map((definition) => (definition.pattern as RegExp).pattern),
      ['first step', 'second step'],
    );
  });

  test('configuration accepts grouped step definitions', () {
    final config = TestConfiguration(
      stepDefinitionGroups: [_FirstGroup(), _SecondGroup()],
    );

    expect(config.stepDefinitionGroups, hasLength(2));
  });
}
