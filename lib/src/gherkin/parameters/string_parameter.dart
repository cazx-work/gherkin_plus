import 'custom_parameter.dart';

class StringParameterBase extends CustomParameter<String> {
  StringParameterBase(String name)
    : super(name, RegExp("['\"]([\\s\\S]*)['\"]"), (String input) => input);
}

class StringParameterLower extends StringParameterBase {
  StringParameterLower() : super('string');
}

class StringParameterCamel extends StringParameterBase {
  StringParameterCamel() : super('String');
}
