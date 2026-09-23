import 'package:gherkin_plus/gherkin_plus.dart';
import '../worlds/custom_world.world.dart';

StepDefinitionGeneric whenTheStoredNumbersAreAdded() {
  return given<CalculatorWorld>(
    'they are added',
    (context) async {
      context.world.calculator.add();
    },
  );
}
