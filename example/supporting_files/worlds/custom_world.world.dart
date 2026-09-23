import 'package:gherkin_plus/gherkin_plus.dart';

import '../../calculator.dart';

class CalculatorWorld extends World {
  final Calculator calculator = Calculator();

  @override
  void dispose() {
    calculator.dispose();
  }
}
