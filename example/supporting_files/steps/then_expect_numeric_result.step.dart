import 'package:gherkin_plus/gherkin_plus.dart';
import '../worlds/custom_world.world.dart';

StepDefinitionGeneric thenExpectNumericResult() {
  return given1<num, CalculatorWorld>('the expected result is {num}', (
    input1,
    context,
  ) async {
    final result = context.world.calculator.getNumericResult();
    context.expectMatch(result, input1);
  });
}
