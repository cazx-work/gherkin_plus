import 'step_definition.dart';
import 'world.dart';

/// A named collection of step definitions that share a world type.
abstract interface class StepDefinitionGroup<TWorld extends World> {
  Iterable<StepDefinitionGeneric<TWorld>> get definitions;
}

/// Flattens groups in registration order for configuration or custom tooling.
List<StepDefinitionGeneric<TWorld>>
flattenStepDefinitionGroups<TWorld extends World>(
  Iterable<StepDefinitionGroup<TWorld>> groups,
) => [for (final group in groups) ...group.definitions];
