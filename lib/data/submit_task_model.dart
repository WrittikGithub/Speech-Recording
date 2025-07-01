class SubmitTaskModel {
  final String contentId;
  final String taskTargetId;
  final String targetContent;
  final bool isForceOnline;

  SubmitTaskModel({
    required this.contentId,
    required this.taskTargetId,
    required this.targetContent,
    this.isForceOnline = false,
  });

  // Convert a SubmitTaskModel object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'taskTargetId': taskTargetId,
      'targetContent': targetContent,
      'isForceOnline': isForceOnline,
    };
  }

  // Create a SubmitTaskModel object from a JSON map
  factory SubmitTaskModel.fromJson(Map<String, dynamic> json) {
    return SubmitTaskModel(
      contentId: json['contentId'],
      taskTargetId: json['taskTargetId'],
      targetContent: json['targetContent'],
      isForceOnline: json['isForceOnline'] ?? false,
    );
  }
}
