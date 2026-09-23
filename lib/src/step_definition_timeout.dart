import 'gherkin/steps/step_definition.dart';

/// Returns the largest effective timeout among selected step definitions.
///
/// Definitions without an explicit timeout use [defaultTimeout]. When no
/// definitions are selected, [defaultTimeout] is returned. [buffer] is added
/// to the result for callers that need time for feature-level overhead.
Duration maxStepDefinitionTimeout(
  Iterable<StepDefinitionGeneric> definitions, {
  required Duration defaultTimeout,
  Duration buffer = Duration.zero,
}) {
  Duration? maximum;
  for (final definition in definitions) {
    final timeout = definition.timeout ?? defaultTimeout;
    if (maximum == null || timeout.compareTo(maximum) > 0) {
      maximum = timeout;
    }
  }

  return (maximum ?? defaultTimeout) + buffer;
}
