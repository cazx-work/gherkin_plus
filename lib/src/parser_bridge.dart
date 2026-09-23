import 'package:cucumber_gherkin/cucumber_gherkin.dart';
import 'package:cucumber_messages/cucumber_messages.dart' as messages;

import 'feature_model.dart';

/// Exposes Cucumber Gherkin parsing and a lightweight feature-model projection.
class ParserBridge {
  /// Returns the Cucumber Messages generated from [source].
  ///
  /// This is the full-fidelity API for callers that need rules, backgrounds,
  /// scenario-outline pickles, parse errors, or source references.
  Future<List<messages.Envelope>> parseMessages(
    String source, {
    required String uri,
  }) async => generateMessages(source, uri, const GherkinOptions());

  /// Returns a lightweight projection of the feature document.
  ///
  /// This projection includes direct scenarios only. Use [parseMessages] when
  /// full Cucumber Gherkin structure and compiled pickles are required.
  Future<FeatureModel?> parse(String source, {required String uri}) async {
    final envelopes = await parseMessages(source, uri: uri);
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
