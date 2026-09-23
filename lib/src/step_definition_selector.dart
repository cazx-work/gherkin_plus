import 'dart:io';

import 'gherkin/expressions/gherkin_expression.dart';
import 'gherkin/cucumber_gherkin_parser.dart';
import 'gherkin/parameters/custom_parameter.dart';
import 'gherkin/parameters/default_parameters.dart';
import 'gherkin/runnables/feature_file.dart';
import 'gherkin/steps/step_definition.dart';
import 'reporters/message_level.dart';
import 'reporters/reporter.dart';

/// A step occurrence and every registered definition that matches it.
class FeatureStepMatch {
  FeatureStepMatch({
    required this.featureName,
    required this.scenarioName,
    required this.stepText,
    required this.uri,
    required this.line,
    required Iterable<StepDefinitionGeneric> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final String featureName;
  final String scenarioName;
  final String stepText;
  final String uri;
  final int line;
  final List<StepDefinitionGeneric> candidates;

  bool get isUnmatched => candidates.isEmpty;
  bool get isAmbiguous => candidates.length > 1;
}

/// The definitions required by a feature and per-step match diagnostics.
class FeatureStepSelection {
  FeatureStepSelection({
    required Iterable<StepDefinitionGeneric> definitions,
    required Iterable<FeatureStepMatch> matches,
  }) : definitions = List.unmodifiable(definitions),
       matches = List.unmodifiable(matches);

  final List<StepDefinitionGeneric> definitions;
  final List<FeatureStepMatch> matches;

  List<FeatureStepMatch> get unmatchedSteps =>
      matches.where((match) => match.isUnmatched).toList(growable: false);

  List<FeatureStepMatch> get ambiguousSteps =>
      matches.where((match) => match.isAmbiguous).toList(growable: false);
}

/// Parses feature source with the package parser and selects matching steps.
class FeatureStepSelector {
  const FeatureStepSelector({this.defaultLanguage = 'en'});

  final String defaultLanguage;

  /// Selects definitions from in-memory [source].
  Future<FeatureStepSelection> select({
    required String source,
    required String uri,
    required Iterable<StepDefinitionGeneric> stepDefinitions,
    Iterable<CustomParameter<dynamic>> customParameters = const [],
  }) async {
    final featureFile = await CucumberGherkinParser().parseFeatureFile(
      source,
      uri,
      _SilentMessageReporter(),
      defaultLanguage,
    );

    return _selectParsedFeature(
      featureFile: featureFile,
      stepDefinitions: stepDefinitions,
      customParameters: customParameters,
    );
  }

  /// Reads and selects definitions from a feature [path].
  Future<FeatureStepSelection> selectFile({
    required String path,
    required Iterable<StepDefinitionGeneric> stepDefinitions,
    Iterable<CustomParameter<dynamic>> customParameters = const [],
  }) async => select(
    source: await File(path).readAsString(),
    uri: path,
    stepDefinitions: stepDefinitions,
    customParameters: customParameters,
  );

  FeatureStepSelection _selectParsedFeature({
    required FeatureFile featureFile,
    required Iterable<StepDefinitionGeneric> stepDefinitions,
    required Iterable<CustomParameter<dynamic>> customParameters,
  }) {
    final parameters = [...defaultStepParameters(), ...customParameters];
    final definitions = stepDefinitions.toList(growable: false);
    final selected = <StepDefinitionGeneric>[];
    final seenDefinitions = <StepDefinitionGeneric>{};
    final matches = <FeatureStepMatch>[];

    for (final feature in featureFile.features) {
      for (final scenario in feature.scenarios) {
        final steps = [...?feature.background?.steps, ...scenario.steps];

        for (final step in steps) {
          final candidates = definitions
              .where((definition) {
                final pattern = definition.pattern is RegExp
                    ? definition.pattern as RegExp
                    : RegExp(definition.pattern.toString());
                return GherkinExpression(
                  pattern,
                  parameters,
                ).isMatch(step.stepText);
              })
              .toList(growable: false);

          matches.add(
            FeatureStepMatch(
              featureName: feature.name,
              scenarioName: scenario.name,
              stepText: step.stepText,
              uri: step.debug.filePath,
              line: step.debug.nonZeroAdjustedLineNumber,
              candidates: candidates,
            ),
          );

          for (final candidate in candidates) {
            if (seenDefinitions.add(candidate)) {
              selected.add(candidate);
            }
          }
        }
      }
    }

    return FeatureStepSelection(definitions: selected, matches: matches);
  }
}

class _SilentMessageReporter implements MessageReporter {
  @override
  Future<void> message(String message, MessageLevel level) async {}
}
