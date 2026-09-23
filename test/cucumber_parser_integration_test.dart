import 'package:gherkin_plus/gherkin_plus.dart';
import 'package:test/test.dart';

class _World extends World {
  String? tableValue;
  String? note;
  int value = 0;
}

class _FeatureMatcher implements FeatureFileMatcher {
  @override
  Future<Iterable<String>> listFiles(Pattern pattern) async => [
    'cucumber.feature',
  ];
}

class _FeatureReader implements FeatureFileReader {
  const _FeatureReader(this.source);

  final String source;

  @override
  Future<String> read(String path) async => source;
}

class _MessageCaptureReporter extends Reporter implements MessageReporter {
  final messages = <(String, MessageLevel)>[];

  @override
  Future<void> message(String message, MessageLevel level) async {
    messages.add((message, level));
  }
}

class _StepLocationReporter extends Reporter implements StepReporter {
  int? lineNumber;

  @override
  ReportActionHandler<StepMessage> get step => ReportActionHandler(
    onStarted: ([message]) async {
      lineNumber = message?.context.lineNumber;
    },
  );
}

const _pickleFeature = '''
@feature
Feature: Cucumber parser integration
  Background: common setup
    Given the scenario starts clean

  @selected
  Rule: Pickle compilation
    Background: rule setup
      Given the rule starts clean

    Scenario Outline: compiled values
      Given this data table is supplied
        | key  | value   |
        | item | <value> |
      When I submit the note
        """
        <note>
        """
      Then the value is <expected>

      Examples:
        | value | note  | expected |
        | alpha | first | 4        |
        | beta  | second| 9        |
''';

void main() {
  test('matches quoted outline values containing backslashes', () async {
    const source = r'''
Feature: Escaped outline value
  Scenario Outline: string parameter
    Given the characters "<characters>"

    Examples:
      | characters |
      | a \n b \c |
''';
    final definition = given1<String?, _World>(
      'the characters {string}',
      (_, _) async {},
    );

    final selection = await const FeatureStepSelector().select(
      source: source,
      uri: 'features/escaped.feature',
      stepDefinitions: [definition],
    );

    expect(selection.matches, hasLength(1));
    expect(selection.matches.single.stepText, 'the characters "a \n b \\c"');
    expect(selection.matches.single.candidates, contains(definition));
  });

  test(
    'executes Cucumber pickles with rule tags and expanded arguments',
    () async {
      var backgroundRuns = 0;
      final tableValues = <String?>[];
      final notes = <String?>[];
      final values = <int>[];

      final configuration = TestConfiguration(
        features: ['cucumber.feature'],
        featureFileMatcher: _FeatureMatcher(),
        featureFileReader: const _FeatureReader(_pickleFeature),
        tagExpression: '@feature and @selected',
        createWorld: (_) async => _World(),
        stepDefinitions: [
          given<_World>('the scenario starts clean', (context) async {
            backgroundRuns += 1;
            context.world
              ..tableValue = null
              ..note = null
              ..value = 0;
          }),
          given<_World>('the rule starts clean', (_) async {
            backgroundRuns += 1;
          }),
          given1<GherkinTable, _World>('this data table is supplied', (
            table,
            context,
          ) async {
            context.world.tableValue = table.asMap().single['value'];
            tableValues.add(context.world.tableValue);
          }),
          when1<String?, _World>('I submit the note', (note, context) async {
            context.world.note = note;
            notes.add(note);
          }),
          then1<int, _World>('the value is {int}', (expected, context) async {
            context.world.value = expected;
            values.add(expected);
            context.expectMatch(context.world.tableValue, isNotNull);
            context.expectMatch(context.world.note, isNotNull);
          }),
        ],
      );

      await GherkinRunner().run(configuration);

      expect(backgroundRuns, 4);
      expect(tableValues, ['alpha', 'beta']);
      expect(notes, ['first', 'second']);
      expect(values, [4, 9]);
    },
  );

  test('uses the configured default language without a directive', () async {
    var stepRuns = 0;
    final configuration = TestConfiguration(
      features: ['french.feature'],
      featureDefaultLanguage: 'fr',
      featureFileMatcher: _FeatureMatcher(),
      featureFileReader: const _FeatureReader('''

Fonctionnalité: Langue par défaut
  Scénario: dialecte configuré
    Soit le message est bonjour
'''),
      createWorld: (_) async => _World(),
      stepDefinitions: [
        given<_World>('le message est bonjour', (_) async {
          stepRuns += 1;
        }),
      ],
    );

    await GherkinRunner().run(configuration);

    expect(stepRuns, 1);
  });

  test('preserves original step line numbers when injecting a language', () async {
    final locationReporter = _StepLocationReporter();
    final configuration = TestConfiguration(
      features: ['french.feature'],
      featureDefaultLanguage: 'fr',
      featureFileMatcher: _FeatureMatcher(),
      featureFileReader: const _FeatureReader('''
    Fonctionnalité: Langue par défaut
  Scénario: dialecte configuré
    Soit le message est bonjour
'''),
      createWorld: (_) async => _World(),
      reporters: [locationReporter],
      stepDefinitions: [
        given<_World>('le message est bonjour', (_) async {}),
      ],
    );

    await GherkinRunner().run(configuration);

    expect(locationReporter.lineNumber, 2);
  });

  test('reports malformed Gherkin with a typed syntax exception', () async {
    final messageReporter = _MessageCaptureReporter();
    final configuration = TestConfiguration(
      features: ['broken.feature'],
      featureFileMatcher: _FeatureMatcher(),
      featureFileReader: const _FeatureReader('''
    Scenario: orphan
  Given a step
'''),
      reporters: [messageReporter],
    );

    await expectLater(
      GherkinRunner().run(configuration),
      throwsA(isA<GherkinSyntaxException>()),
    );
    expect(
      messageReporter.messages,
      contains(
        predicate<(String, MessageLevel)>(
          (entry) =>
              entry.$2 == MessageLevel.error &&
              entry.$1.contains('Gherkin parse error at cucumber.feature'),
        ),
      ),
    );
  });
}
