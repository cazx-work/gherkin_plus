import '../exceptions/syntax_error.dart';
import '../models/table.dart';
import 'debug_information.dart';
import 'multi_line_string.dart';
import 'runnable.dart';
import 'runnable_block.dart';
import 'table.dart';

class StepRunnable extends RunnableBlock {
  String _name;
  final String keyword;
  String? description;
  GherkinTable? table;
  List<String> multilineStrings = <String>[];

  StepRunnable(
    this._name,
    RunnableDebugInformation debug, {
    this.keyword = '',
  }) : super(debug);

  @override
  String get name => _name;

  String get stepText => debug.lineText.substring(keyword.length).trimLeft();

  @override
  void addChild(Runnable child) {
    switch (child.runtimeType) {
      case MultilineStringRunnable:
        multilineStrings
            .add((child as MultilineStringRunnable).lines.join('\n'));
      case TableRunnable:
        if (table != null) {
          throw GherkinSyntaxException(
            "Only a single table can be added to the step '$name'",
          );
        }

        table = (child as TableRunnable).toTable();
      default:
        throw Exception(
          "Unknown runnable child given to Step '${child.runtimeType}'",
        );
    }
  }

  void setStepParameter(String parameterName, String value) {
    _name = _name.replaceAll('<$parameterName>', value);
    table?.setStepParameter(parameterName, value);
    debug = debug.copyWith(
      lineNumber: debug.lineNumber,
      lineText: debug.lineText.replaceAll('<$parameterName>', value),
    );
  }

  StepRunnable clone() {
    final cloned = StepRunnable(_name, debug, keyword: keyword);
    cloned.multilineStrings = multilineStrings.map((s) => s).toList();
    cloned.table = table?.clone();

    return cloned;
  }
}
