import '../languages/dialect.dart';
import '../languages/language_service.dart';

import 'dialect_block.dart';

class LanguageRunnable extends DialectBlock {
  late String language;

  @override
  String get name => 'Language';

  LanguageRunnable(super.debug);

  @override
  GherkinDialect getDialect(LanguageService languageService) =>
      languageService.getDialect(language);
}
