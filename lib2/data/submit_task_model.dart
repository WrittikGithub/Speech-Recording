class SubmitTaskModel {
  final String contentId;
  final String taskTargetId;
  final String targetContent;

  SubmitTaskModel({
    required this.contentId,
    required this.taskTargetId,
    required this.targetContent,
  });

  // Convert a SubmitTaskModel object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'taskTargetId': taskTargetId,
      'targetContent': targetContent,
    };
  }

  // Create a SubmitTaskModel object from a JSON map
  factory SubmitTaskModel.fromJson(Map<String, dynamic> json) {
    return SubmitTaskModel(
      contentId: json['contentId'],
      taskTargetId: json['taskTargetId'],
      targetContent: json['targetContent'],
    );
  }
}
