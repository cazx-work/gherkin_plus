import 'package:gherkin_plus/gherkin.dart';
import 'package:test/test.dart';

class _World extends World {}

class _SlugParameter extends CustomParameter<String> {
  _SlugParameter() : super('slug', RegExp('[a-z]+'), (value) => value);
}

void main() {
  group('FeatureStepSelector', () {
    test('matches backgrounds and expanded scenario outlines', () async {
      const source = '''
Feature: Selection
  Background: shared setup
    Given the app is ready

  Scenario: regular scenario
    When I open "panel"

  Scenario Outline: values
    Then the value is <value>

    Examples:
      | value |
      | 3     |
      | 7     |
''';
      final definitions = <StepDefinitionGeneric>[
        given<_World>('the app is ready', (_) async {}),
        when1<String?, _World>('I open {string}', (_, _) async {}),
        then1<int?, _World>('the value is {int}', (_, _) async {}),
      ];

      final selection = await const FeatureStepSelector().select(
        source: source,
        uri: 'features/selection.feature',
        stepDefinitions: definitions,
      );

      expect(selection.definitions, hasLength(3));
      expect(selection.unmatchedSteps, isEmpty);
      expect(selection.ambiguousSteps, isEmpty);
      expect(
        selection.matches.where((match) => match.stepText == 'the app is ready'),
        hasLength(3),
      );
      expect(
        selection.matches.where((match) => match.stepText.startsWith('the value is')),
        hasLength(2),
      );
      expect(selection.matches.first.uri, 'features/selection.feature');
      expect(selection.matches.first.line, 3);
    });

    test('reports unmatched and ambiguous step definitions', () async {
      const source = '''
Feature: Matching diagnostics
  Scenario: candidates
    Given a shared step
    When an undefined step
''';
      final definitions = <StepDefinitionGeneric>[
        given<_World>('a shared step', (_) async {}),
        given<_World>('a shared step', (_) async {}),
      ];

      final selection = await const FeatureStepSelector().select(
        source: source,
        uri: 'features/matching.feature',
        stepDefinitions: definitions,
      );

      expect(selection.definitions, hasLength(2));
      expect(selection.ambiguousSteps, hasLength(1));
      expect(selection.ambiguousSteps.single.candidates, hasLength(2));
      expect(selection.unmatchedSteps, hasLength(1));
      expect(selection.unmatchedSteps.single.stepText, 'an undefined step');
    });

    test('matches caller-provided custom parameters', () async {
      const source = '''
Feature: Custom parameters
  Scenario: custom token
    Given module key alpha
''';
      final customParameter = _SlugParameter();
      final definition = given1<String?, _World>(
        'module key {slug}',
        (_, _) async {},
      );

      final selection = await const FeatureStepSelector().select(
        source: source,
        uri: 'features/custom.feature',
        stepDefinitions: [definition],
        customParameters: [customParameter],
      );

      expect(selection.definitions, [definition]);
      expect(selection.unmatchedSteps, isEmpty);
    });
  });
}
