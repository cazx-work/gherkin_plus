import 'gherkin_exception.dart';

class GherkinDialectNotSupportedException implements GherkinException {
  final String? dialect;

  GherkinDialectNotSupportedException(this.dialect);

  @override
  String toString() {
    if (dialect == null) {
      return 'GherkinDialectNotSupportedException';
    }

    return "GherkinDialectNotSupportedException: Dialect is not supported '$dialect'";
  }
}

@Deprecated('Use GherkinDialectNotSupportedException instead.')
typedef GherkinDialogNotSupportedException =
    GherkinDialectNotSupportedException;
