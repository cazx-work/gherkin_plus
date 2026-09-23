import '../../../gherkin.dart';
import '../cucumber_gherkin_parser.dart';
import '../runnables/tags.dart';

class FeatureFileVisitor {
  Future<void> visit(
    String featureFileContents,
    String path,
    LanguageService languageService,
    MessageReporter reporter,
  ) async {
    final featureFile = await CucumberGherkinParser().parseFeatureFile(
      featureFileContents,
      path,
      reporter,
      languageService.defaultLanguage,
    );

    for (final feature in featureFile.features) {
      await visitFeature(
        feature.name,
        feature.description,
        _tagsToList(feature.tags),
        feature.scenarios.length,
      );

      for (var i = 0; i < feature.scenarios.length; i += 1) {
        final scenario = feature.scenarios.elementAt(i);
        final isFirst = i == 0;
        final isLast = i == (feature.scenarios.length - 1);
        final allScenarios = [scenario];
        var acknowledgedScenarioPosition = false;

        for (final childScenario in allScenarios) {
          await visitScenario(
            feature.name,
            feature.description,
            _tagsToList(feature.tags),
            childScenario.name,
            childScenario.description,
            _tagsToList(childScenario.tags),
            path,
            isFirst: !acknowledgedScenarioPosition && isFirst,
            isLast: !acknowledgedScenarioPosition && isLast,
          );

          acknowledgedScenarioPosition = true;

          for (final step in childScenario.steps) {
            await visitScenarioStep(
              step.name,
              step.multilineStrings,
              step.table,
            );
          }
        }
      }
    }

    return Future.value(null);
  }

  Future<void> visitFeature(
    String name,
    String? description,
    Iterable<String> tags,
    int childScenarioCount,
  ) async {}

  Future<void> visitScenario(
    String featureName,
    String? featureDescription,
    Iterable<String> featureTags,
    String name,
    String? description,
    Iterable<String> tags,
    String path, {
    required bool isFirst,
    required bool isLast,
  }) async {}

  Future<void> visitScenarioStep(
    String name,
    Iterable<String> multiLineStrings,
    GherkinTable? table,
  ) async {}

  Iterable<String> _tagsToList(Iterable<TagsRunnable> tags) sync* {
    for (final tag in tags.expand((element) => element.tags)) {
      yield tag;
    }
  }
}
