import 'package:gherkin_plus/gherkin.dart';
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
}
