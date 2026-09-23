class SourceLocation {
  const SourceLocation({required this.line, required this.column});

  final int line;
  final int column;
}

class FeatureModel {
  const FeatureModel({
    required this.name,
    required this.scenarios,
    required this.location,
    this.tags = const [],
  });

  final String name;
  final List<ScenarioModel> scenarios;
  final List<String> tags;
  final SourceLocation location;
}

class ScenarioModel {
  const ScenarioModel({
    required this.name,
    required this.steps,
    required this.location,
    this.tags = const [],
  });

  final String name;
  final List<StepModel> steps;
  final List<String> tags;
  final SourceLocation location;
}

class StepModel {
  const StepModel({
    required this.keyword,
    required this.text,
    required this.location,
  });

  final String keyword;
  final String text;
  final SourceLocation location;
}
