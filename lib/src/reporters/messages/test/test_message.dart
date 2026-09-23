part of '../messages.dart';

class TestMessage extends ActionMessage {
  final List<Tag> tags;

  TestMessage({
    required super.target,
    required super.name,
    required super.context,
    this.tags = const [],
  });

  TestMessage copyWith({
    Target? target,
    String? name,
    RunnableDebugInformation? context,
    List<Tag>? tags,
  }) {
    return TestMessage(
      target: target ?? this.target,
      name: name ?? this.name,
      context: context ?? this.context,
      tags: tags ?? this.tags,
    );
  }
}
