import 'package:gherkin_plus/gherkin_plus.dart';

import '../worlds/custom_world.world.dart';

StepDefinitionGeneric givenTheCharacters() {
  return given1<String, CalculatorWorld>('the characters {string}', (
    input1,
    context,
  ) async {
    context.world.calculator.storeCharacterInput(input1);
  });
}
