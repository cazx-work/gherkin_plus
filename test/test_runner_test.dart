import 'package:gherkin_plus/gherkin.dart';
import 'package:test/test.dart';

class _World extends World {}

class _SingleFeatureMatcher implements FeatureFileMatcher {
  @override
  Future<Iterable<String>> listFiles(Pattern pattern) async => [
    'sample.feature',
  ];
}

class _SingleFeatureReader implements FeatureFileReader {
  @override
  Future<String> read(String path) async => '''
Feature: Runner reuse
  Scenario: same expression
    Given run this step
''';
}

void main() {
  test('re-registers step definitions for each run', () async {
    var firstDefinitionRuns = 0;
    var secondDefinitionRuns = 0;
    final runner = GherkinRunner();

    TestConfiguration configurationFor(
      Future<void> Function(StepContext<_World>) definition,
    ) => TestConfiguration(
      features: ['sample.feature'],
      featureFileMatcher: _SingleFeatureMatcher(),
      featureFileReader: _SingleFeatureReader(),
      createWorld: (_) async => _World(),
      stepDefinitions: [given<_World>('run this step', definition)],
    );

    await runner.run(configurationFor((_) async => firstDefinitionRuns += 1));
    await runner.run(configurationFor((_) async => secondDefinitionRuns += 1));

    expect(firstDefinitionRuns, 1);
    expect(secondDefinitionRuns, 1);
  });
}
