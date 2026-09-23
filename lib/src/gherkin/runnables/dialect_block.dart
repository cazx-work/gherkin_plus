import '../languages/dialect.dart';
import '../languages/language_service.dart';

import 'runnable.dart';

abstract class DialectBlock extends Runnable {
  DialectBlock(super.debug);

  GherkinDialect getDialect(LanguageService languageService);
}
