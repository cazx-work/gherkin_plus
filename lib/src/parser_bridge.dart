import 'package:cucumber_gherkin/cucumber_gherkin.dart';
import 'package:cucumber_messages/cucumber_messages.dart' as messages;

import 'feature_model.dart';

/// Parses standard Gherkin while keeping Cucumber Messages out of the runner API.
class ParserBridge {
  Future<FeatureModel?> parse(String source, {required String uri}) async {
    final envelopes = generateMessages(
      source,
      uri,
      const GherkinOptions(includeGherkinDocument: true),
    );
    for (final envelope in envelopes) {
      final document = envelope.gherkinDocument;
      if (document == null) {
        continue;
      }

      final feature = document.feature;
      if (feature == null) {
        return null;
      }

      final scenarios = <ScenarioModel>[];
      for (final child in feature.children) {
        final scenario = child.scenario;
        if (scenario == null) {
          continue;
        }

        scenarios.add(
          ScenarioModel(
            name: scenario.name,
            tags: scenario.tags.map((tag) => tag.name).toList(growable: false),
            location: _location(scenario.location),
            steps: scenario.steps
                .map(
                  (step) => StepModel(
                    keyword: step.keyword,
                    text: step.text,
                    location: _location(step.location),
                  ),
                )
                .toList(growable: false),
          ),
        );
      }

      return FeatureModel(
        name: feature.name,
        tags: feature.tags.map((tag) => tag.name).toList(growable: false),
        location: _location(feature.location),
        scenarios: scenarios,
      );
    }

    return null;
  }

  SourceLocation _location(messages.Location location) =>
      SourceLocation(line: location.line, column: location.column ?? 0);
}
