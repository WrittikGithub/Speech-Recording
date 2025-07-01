class CompletedTaskmodel {
  final String taskId;
  final String taskTargetId;
  final String projectId;
  final String languageName;
  final String targetLanguageId;
  final String taskPrefix;
  final String taskTitle;
  final String taskType;
  final String status;
  final String createdDate;
  final String assignTranslation;
  final String reviewTranslation;
  final String project;
  final String contents;

  CompletedTaskmodel({
    required this.taskId,
    required this.taskTargetId,
    required this.projectId,
    required this.languageName,
    required this.targetLanguageId,
    required this.taskPrefix,
    required this.taskTitle,
    required this.taskType,
    required this.status,
    required this.createdDate,
    required this.assignTranslation,
    required this.reviewTranslation,
    required this.project,
    required this.contents,
  });

  factory CompletedTaskmodel.fromJson(Map<String, dynamic> json) {
    return CompletedTaskmodel(
      taskId: json['taskId'] ?? '',
      taskTargetId: json['taskTargetId'] ?? '',
      projectId: json['projectId'] ?? '',
      languageName: json['languageName'] ?? '',
      targetLanguageId: json['targetLanguageId'] ?? '',
      taskPrefix: json['taskPrefix'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      taskType: json['taskType'] ?? '',
      status: json['status'] ?? '',
      createdDate: json['createdDate'] ?? '',
      assignTranslation: json['assign_translation'] ?? '',
      reviewTranslation: json['review_translation'] ?? '',
      project: json['project'] ?? '',
      contents: json['contents'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskTargetId': taskTargetId,
      'projectId': projectId,
      'languageName': languageName,
      'targetLanguageId': targetLanguageId,
      'taskPrefix': taskPrefix,
      'taskTitle': taskTitle,
      'taskType': taskType,
      'status': status,
      'createdDate': createdDate,
      'assign_translation': assignTranslation,
      'review_translation': reviewTranslation,
      'project': project,
      'contents': contents,
    };
  }
}


