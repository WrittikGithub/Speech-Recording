class ReviewsModel {
  final String taskId;
  final String taskTargetId;
  final String projectId;
  final String languageName;
  final String taskPrefix;
  final String taskTitle;
  final String taskType;
  final String status;
  final String createdDate;
  final String assignedTo;
  final String project;
  final String contents;

  ReviewsModel({
    required this.taskId,
    required this.taskTargetId,
    required this.projectId,
    required this.languageName,
    required this.taskPrefix,
    required this.taskTitle,
    required this.taskType,
    required this.status,
    required this.createdDate,
    required this.assignedTo,
    required this.project,
    required this.contents,
  });

  factory ReviewsModel.fromJson(Map<String, dynamic> json) {
    return ReviewsModel(
      taskId: json['taskId'] ?? '',
      taskTargetId: json['taskTargetId'] ?? '',
      projectId: json['projectId'] ?? '',
      languageName: json['languageName'] ?? '',
      taskPrefix: json['taskPrefix'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      taskType: json['taskType'] ?? '',
      status: json['status'] ?? '',
      createdDate: json['createdDate'] ?? '',
      assignedTo: json['assignedTo'] ?? '',
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
      'taskPrefix': taskPrefix,
      'taskTitle': taskTitle,
      'taskType': taskType,
      'status': status,
      'createdDate': createdDate,
      'assignedTo': assignedTo,
      'project': project,
      'contents': contents,
    };
  }
}