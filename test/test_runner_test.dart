import 'package:gherkin_plus/gherkin_plus.dart';
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

class _FailingFeatureReader implements FeatureFileReader {
  @override
  Future<String> read(String path) async =>
      throw StateError('feature source unavailable');
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

  test('formats feature loading errors with the affected patterns', () async {
    final configuration = TestConfiguration(
      features: ['sample.feature'],
      featureFileMatcher: _SingleFeatureMatcher(),
      featureFileReader: _FailingFeatureReader(),
    );

    await expectLater(
      GherkinRunner().run(configuration),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains(
            'Error while loading feature files for patterns sample.feature: '
            'Bad state: feature source unavailable',
          ),
        ),
      ),
    );
  });
}
