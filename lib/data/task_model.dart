// ignore: file_names
class TaskModel {
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

  TaskModel({
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
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
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
    );
  }
}

