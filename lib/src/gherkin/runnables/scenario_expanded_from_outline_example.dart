import 'scenario.dart';
import 'scenario_type_enum.dart';

class ScenarioExpandedFromOutlineExampleRunnable extends ScenarioRunnable {
  String _name;

  @override
  ScenarioType get scenarioType => ScenarioType.scenarioOutline;

  @override
  String get name => _name;

  ScenarioExpandedFromOutlineExampleRunnable(
    super.name,
    super.description,
    super.debug,
  ) : _name = name;

  void setStepParameter(String parameterName, String value) {
    _name = _name.replaceAll('<$parameterName>', value);
    debug = debug.copyWith(
      lineNumber: debug.lineNumber,
      lineText: debug.lineText.replaceAll('<$parameterName>', value),
    );
  }
}
