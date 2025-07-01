// ignore_for_file: non_constant_identifier_names

class DashboardTaskModel {
  final String taskId;
  final String taskTargetId;
  final String projectId;
  final String taskPrefix;
  final String csid;
  final String sourceLanguageId;
  final String targetLanguageId;
  final String taskTitle;
  final String taskType;
  final String status;
  final String? reviewStatus;
  final String createdBy;
  final String createdMethod;
  final String createdDate;
  final String lastModifiedDate;
  final String assign_translation;
  final String assign_translation_date;
  final String review_translation;
  final String review_translation_date;
  final String raiseIssue;
  final String sourceWordCount;
  final String importType;
  final String newFileName;
  final String digitizedDate;
  final String reviewedDate;
  final String project;
  final int contents;
  final int contentspending;
  final double pendingPercent;

  DashboardTaskModel({
    required this.taskId,
    required this.taskTargetId,
    required this.projectId,
    required this.taskPrefix,
    required this.csid,
    required this.sourceLanguageId,
    required this.targetLanguageId,
    required this.taskTitle,
    required this.taskType,
    required this.status,
    this.reviewStatus,
    required this.createdBy,
    required this.createdMethod,
    required this.createdDate,
    required this.lastModifiedDate,
    required this.assign_translation,
    required this.assign_translation_date,
    required this.review_translation,
    required this.review_translation_date,
    required this.raiseIssue,
    required this.sourceWordCount,
    required this.importType,
    required this.newFileName,
    required this.digitizedDate,
    required this.reviewedDate,
    required this.project,
    required this.contents,
    required this.contentspending,
    required this.pendingPercent,
  });

  factory  DashboardTaskModel.fromJson(Map<String, dynamic> json) {
    return  DashboardTaskModel(
      taskId: json['taskId'] ?? '',
      taskTargetId: json['taskTargetId'] ?? '',
      projectId: json['projectId'] ?? '',
      taskPrefix: json['taskPrefix'] ?? '',
      csid: json['csid'] ?? '',
      sourceLanguageId: json['sourceLanguageId'] ?? '',
      targetLanguageId: json['targetLanguageId'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      taskType: json['taskType'] ?? '',
      status: json['status'] ?? '',
      reviewStatus: json['reviewStatus'],
      createdBy: json['createdBy'] ?? '',
      createdMethod: json['createdMethod'] ?? '',
      createdDate: json['createdDate'] ?? '',
      lastModifiedDate: json['lastModifiedDate'] ?? '',
      assign_translation: json['assign_translation'] ?? '',
      assign_translation_date: json['assign_translation_date'] ?? '',
      review_translation: json['review_translation'] ?? '',
      review_translation_date: json['review_translation_date'] ?? '',
      raiseIssue: json['raiseIssue'] ?? '',
      sourceWordCount: json['sourceWordCount'] ?? '',
      importType: json['importType'] ?? '',
      newFileName: json['newFileName'] ?? '',
      digitizedDate: json['digitizedDate'] ?? '',
      reviewedDate: json['reviewedDate'] ?? '',
      project: json['project'] ?? '',
      contents: int.parse(json['contents'] ?? '0'),
      contentspending: int.parse(json['contentspending']?.toString() ?? '0'),
      pendingPercent: double.parse(json['pendingPercent']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskTargetId': taskTargetId,
      'projectId': projectId,
      'taskPrefix': taskPrefix,
      'csid': csid,
      'sourceLanguageId': sourceLanguageId,
      'targetLanguageId': targetLanguageId,
      'taskTitle': taskTitle,
      'taskType': taskType,
      'status': status,
      'reviewStatus': reviewStatus,
      'createdBy': createdBy,
      'createdMethod': createdMethod,
      'createdDate': createdDate,
      'lastModifiedDate': lastModifiedDate,
      'assign_translation': assign_translation,
      'assign_translation_date': assign_translation_date,
      'review_translation': review_translation,
      'review_translation_date': review_translation_date,
      'raiseIssue': raiseIssue,
      'sourceWordCount': sourceWordCount,
      'importType': importType,
      'newFileName': newFileName,
      'digitizedDate': digitizedDate,
      'reviewedDate': reviewedDate,
      'project': project,
      'contents': contents,
      'contentspending': contentspending,
      'pendingPercent': pendingPercent,
    };
  }
}