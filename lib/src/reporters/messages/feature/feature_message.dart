part of '../messages.dart';

/// {@template messages.featuremessage}
/// A message related to a feature
/// {@endtemplate}
class FeatureMessage extends ActionMessage {
  /// Gherkin format tags
  final List<Tag> tags;
  final String? description;

  /// {@macro messages.featuremessage}
  FeatureMessage({
    required super.name,
    required super.context,
    this.tags = const [],
    this.description,
  }) : super(
          target: Target.feature,
        );

  FeatureMessage copyWith({
    String? name,
    RunnableDebugInformation? context,
    List<Tag>? tags,
    String? description,
  }) {
    return FeatureMessage(
      name: name ?? this.name,
      context: context ?? this.context,
      tags: tags ?? this.tags,
      description: description ?? this.description,
    );
  }
}
