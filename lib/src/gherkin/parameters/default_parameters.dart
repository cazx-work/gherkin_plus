import 'custom_parameter.dart';
import 'float_parameter.dart';
import 'int_parameter.dart';
import 'plural_parameter.dart';
import 'string_parameter.dart';
import 'word_parameter.dart';

List<CustomParameter<dynamic>> defaultStepParameters() =>
    <CustomParameter<dynamic>>[
      FloatParameterLower(),
      FloatParameterCamel(),
      NumParameterLower(),
      NumParameterCamel(),
      IntParameterLower(),
      IntParameterCamel(),
      StringParameterLower(),
      StringParameterCamel(),
      WordParameterLower(),
      WordParameterCamel(),
      PluralParameter(),
    ];
