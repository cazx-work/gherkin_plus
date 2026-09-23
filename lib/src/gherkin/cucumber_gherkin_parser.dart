import 'package:cucumber_gherkin/cucumber_gherkin.dart';
import 'package:cucumber_messages/cucumber_messages.dart' as messages;

import 'exceptions/syntax_error.dart';
import 'models/table.dart';
import 'models/table_row.dart' as runnable_table;
import '../reporters/message_level.dart';
import '../reporters/reporter.dart';
import 'runnables/debug_information.dart';
import 'runnables/feature.dart';
import 'runnables/feature_file.dart';
import 'runnables/scenario.dart';
import 'runnables/scenario_expanded_from_outline_example.dart';
import 'runnables/step.dart';
import 'runnables/tags.dart';

class CucumberGherkinParser {
  Future<FeatureFile> parseFeatureFile(
    String source,
    String uri,
    MessageReporter reporter,
    String defaultLanguage,
  ) async {
    final injectedLanguage =
        defaultLanguage != 'en' && !_hasLanguageDirective(source);
    final parseSource = injectedLanguage
        ? '# language: $defaultLanguage\n$source'
        : source;
    final envelopes = generateMessages(
      parseSource,
      uri,
      const GherkinOptions(includeSource: false),
    );

    final parseErrors = envelopes
        .map((envelope) => envelope.parseError)
        .whereType<messages.ParseError>()
        .toList(growable: false);
    if (parseErrors.isNotEmpty) {
      final error = parseErrors.first;
      final message = 'Gherkin parse error at $uri: ${error.message}';
      await reporter.message(message, MessageLevel.error);
      throw GherkinSyntaxException(message);
    }

    final document = envelopes
        .map((envelope) => envelope.gherkinDocument)
        .whereType<messages.GherkinDocument>()
        .firstOrNull;
    final feature = document?.feature;
    final featureFile = FeatureFile(
      RunnableDebugInformation(uri, 0, ''),
      language: feature?.language ?? defaultLanguage,
    );
    if (feature == null) {
      return featureFile;
    }

    final index = _AstIndex(feature);
    final featureDebug = _debug(uri, feature.location, injectedLanguage);
    final featureRunnable = FeatureRunnable(feature.name, featureDebug)
      ..description = feature.description;
    for (final pickle
        in envelopes
            .map((envelope) => envelope.pickle)
            .whereType<messages.Pickle>()) {
      final scenarioAst = index.scenarioFor(pickle.astNodeIds);
      if (scenarioAst == null) {
        continue;
      }

      final exampleRow = index.exampleRowFor(pickle.astNodeIds);
      final scenarioLocation = exampleRow?.location ?? scenarioAst.location;
      final scenarioDebug = _debug(uri, scenarioLocation, injectedLanguage);
      final isOutline = scenarioAst.examples.isNotEmpty;
      final scenario = isOutline
          ? ScenarioExpandedFromOutlineExampleRunnable(
              pickle.name,
              scenarioAst.description,
              scenarioDebug,
            )
          : ScenarioRunnable(
              pickle.name,
              scenarioAst.description,
              scenarioDebug,
            );

      for (final pickleTag in pickle.tags) {
        if (index.featureTagIds.contains(pickleTag.astNodeId)) {
          continue;
        }
        final tag = index.tags[pickleTag.astNodeId];
        final tagLine = tag?.location.line ?? scenarioLocation.line;
        scenario.addTag(
          TagsRunnable(
              RunnableDebugInformation(
                uri,
                _runnableLine(tagLine, injectedLanguage),
                pickleTag.name,
              ),
            )
            ..tags = [pickleTag.name]
            ..isInherited = index.inheritedTagIds.contains(pickleTag.astNodeId),
        );
      }

      for (final pickleStep in pickle.steps) {
        final astStep = index.stepFor(pickleStep.astNodeIds);
        final keyword = astStep?.keyword ?? '';
        final stepText = pickleStep.text;
        final lineText = '$keyword$stepText';
        final stepLocation = astStep?.location ?? scenarioLocation;
        final step = StepRunnable(
          lineText,
          _debug(uri, stepLocation, injectedLanguage, lineText: lineText),
          keyword: keyword,
        );

        final argument = pickleStep.argument;
        final docString = argument?.docString;
        if (docString != null) {
          step.multilineStrings.add(docString.content);
        }
        final dataTable = argument?.dataTable;
        if (dataTable != null) {
          step.table = _toTable(dataTable);
        }
        scenario.addChild(step);
      }

      featureRunnable.scenarios.add(scenario);
    }

    for (final tag in feature.tags) {
      featureRunnable.addTag(
        TagsRunnable(
          RunnableDebugInformation(
            uri,
            _runnableLine(tag.location.line, injectedLanguage),
            tag.name,
          ),
        )..tags = [tag.name],
      );
    }

    featureFile.features.add(featureRunnable);
    return featureFile;
  }

  bool _hasLanguageDirective(String source) {
    final firstLine = source
        .trimLeft()
        .split(RegExp(r'\r\n|\r|\n'))
        .first
        .replaceFirst('\uFEFF', '')
        .trimLeft();
    return RegExp(
      r'^#\s*language\s*:',
      caseSensitive: false,
    ).hasMatch(firstLine);
  }

  GherkinTable _toTable(messages.PickleTable dataTable) {
    final sourceRows = dataTable.rows;
    final hasHeader = sourceRows.length > 1;
    final header = hasHeader
        ? runnable_table.TableRow(
            sourceRows.first.cells.map((cell) => cell.value),
            0,
            isHeaderRow: true,
          )
        : null;
    final rows = sourceRows
        .skip(hasHeader ? 1 : 0)
        .indexed
        .map(
          (entry) => runnable_table.TableRow(
            entry.$2.cells.map((cell) => cell.value),
            entry.$1 + (hasHeader ? 1 : 0),
            isHeaderRow: false,
          ),
        )
        .toList(growable: false);
    return GherkinTable(rows, header);
  }

  RunnableDebugInformation _debug(
    String uri,
    messages.Location location,
    bool injectedLanguage, {
    String? lineText,
  }) => RunnableDebugInformation(
    uri,
    _runnableLine(location.line, injectedLanguage),
    lineText ?? '',
  );

  int _runnableLine(int line, bool injectedLanguage) =>
      line - 1 - (injectedLanguage ? 1 : 0);
}

class _AstIndex {
  _AstIndex(messages.Feature feature) {
    _indexTags(feature.tags, inherited: false, featureTags: true);
    for (final child in feature.children) {
      final scenario = child.scenario;
      if (scenario != null) {
        _indexScenario(scenario);
      }
      final background = child.background;
      if (background != null) {
        _indexSteps(background.steps);
      }
      final rule = child.rule;
      if (rule != null) {
        _indexTags(rule.tags, inherited: true);
        for (final ruleChild in rule.children) {
          final ruleScenario = ruleChild.scenario;
          if (ruleScenario != null) {
            _indexScenario(ruleScenario);
          }
          final ruleBackground = ruleChild.background;
          if (ruleBackground != null) {
            _indexSteps(ruleBackground.steps);
          }
        }
      }
    }
  }

  final Map<String, messages.Step> _steps = {};
  final Map<String, messages.Scenario> _scenarios = {};
  final Map<String, messages.TableRow> _exampleRows = {};
  final Map<String, messages.Tag> tags = {};
  final Set<String> featureTagIds = {};
  final Set<String> inheritedTagIds = {};

  messages.Step? stepFor(Iterable<String> astNodeIds) {
    for (final id in astNodeIds) {
      final step = _steps[id];
      if (step != null) {
        return step;
      }
    }
    return null;
  }

  messages.Scenario? scenarioFor(Iterable<String> astNodeIds) {
    for (final id in astNodeIds) {
      final scenario = _scenarios[id];
      if (scenario != null) {
        return scenario;
      }
    }
    return null;
  }

  messages.TableRow? exampleRowFor(Iterable<String> astNodeIds) {
    for (final id in astNodeIds) {
      final row = _exampleRows[id];
      if (row != null) {
        return row;
      }
    }
    return null;
  }

  void _indexScenario(messages.Scenario scenario) {
    _scenarios[scenario.id] = scenario;
    _indexTags(scenario.tags, inherited: false);
    _indexSteps(scenario.steps);
    for (final examples in scenario.examples) {
      _indexTags(examples.tags, inherited: true);
      for (final row in examples.tableBody) {
        _exampleRows[row.id] = row;
      }
    }
  }

  void _indexSteps(Iterable<messages.Step> steps) {
    for (final step in steps) {
      _steps[step.id] = step;
    }
  }

  void _indexTags(
    Iterable<messages.Tag> sourceTags, {
    required bool inherited,
    bool featureTags = false,
  }) {
    for (final tag in sourceTags) {
      tags[tag.id] = tag;
      if (inherited) {
        inheritedTagIds.add(tag.id);
      }
      if (featureTags) {
        featureTagIds.add(tag.id);
      }
    }
  }
}
