import 'runnable.dart';

abstract class RunnableBlock extends Runnable {
  RunnableBlock(super.debug);

  void addChild(Runnable child);
}
