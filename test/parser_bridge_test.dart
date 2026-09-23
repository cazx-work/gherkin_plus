import 'package:gherkin_plus/gherkin_plus.dart';
import 'package:cucumber_messages/cucumber_messages.dart' as messages;
import 'package:test/test.dart';

void main() {
  test('maps Cucumber Messages into the internal feature model', () async {
    const source = '''
Feature: Sign in
  @smoke
  Scenario: valid credentials
    Given the sign-in screen is visible
    When I enter valid credentials
''';

    final feature = await ParserBridge().parse(
      source,
      uri: 'features/auth/sign_in.feature',
    );

    expect(feature, isNotNull);
    expect(feature!.name, 'Sign in');
    expect(feature.scenarios, hasLength(1));
    expect(feature.scenarios.single.name, 'valid credentials');
    expect(feature.scenarios.single.tags, ['@smoke']);
    expect(feature.scenarios.single.steps, hasLength(2));
    expect(
      feature.scenarios.single.steps.last.text,
      'I enter valid credentials',
    );
    expect(feature.scenarios.single.steps.last.location.line, 5);
  });

  test('exposes the full Cucumber document and compiled pickles', () async {
    const source = '''
Feature: Full fidelity
  Background:
    Given common setup

  Rule: Rule scope
    Scenario Outline: expanded scenario
      When I enter <value>
      Then I see <value>

      Examples:
        | value |
        | alpha |
        | beta  |
''';

    final envelopes = await ParserBridge().parseMessages(
      source,
      uri: 'features/full_fidelity.feature',
    );
    final document = envelopes
        .map((envelope) => envelope.gherkinDocument)
        .whereType<messages.GherkinDocument>()
        .single;
    final pickles = envelopes
        .map((envelope) => envelope.pickle)
        .whereType<messages.Pickle>()
        .toList(growable: false);

    expect(
      document.feature!.children.map((child) => child.rule).whereType<messages.Rule>(),
      hasLength(1),
    );
    expect(pickles, hasLength(2));
    expect(pickles.first.steps, hasLength(3));
    expect(pickles.first.steps.first.text, 'common setup');
    expect(pickles.first.steps[1].text, 'I enter alpha');
    expect(pickles.last.steps[1].text, 'I enter beta');
  });
}
