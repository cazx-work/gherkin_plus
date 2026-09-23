import '../exceptions/syntax_error.dart';
import '../models/table.dart';
import 'debug_information.dart';
import 'runnable.dart';
import 'table.dart';
import 'taggable_runnable_block.dart';
import 'tags.dart';

class ExampleRunnable extends TaggableRunnableBlock {
  final String _name;
  GherkinTable? table;
  String? description;

  ExampleRunnable(this._name, RunnableDebugInformation debug) : super(debug);

  @override
  String get name => _name;

  @override
  void addChild(Runnable child) {
    if (child case final TableRunnable tableRunnable) {
      if (table != null) {
        throw GherkinSyntaxException(
          "Only a single table can be added to the example '$name'",
        );
      }

      table = tableRunnable.toTable();
    } else if (child case final TagsRunnable tagsRunnable) {
      addTag(tagsRunnable);
    } else {
      throw Exception(
        "Unknown runnable child given to Step '${child.runtimeType}'",
      );
    }
  }
}
