class PreviewScoremodel {
  final String rsid;
  final String taskId;
  final String taskTargetId;
  final String contentId;
  final String errorType;
  final String errorValue;
  final String errorScore;
  final String userId;
  final String comment;
  final DateTime createdDate;
  final DateTime lastModifiedDate;

  PreviewScoremodel({
    required this.rsid,
    required this.taskId,
    required this.taskTargetId,
    required this.contentId,
    required this.errorType,
    required this.errorValue,
    required this.errorScore,
    required this.userId,
    required this.comment,
    required this.createdDate,
    required this.lastModifiedDate,
  });

  factory PreviewScoremodel.fromJson(Map<String, dynamic> json) {
    return PreviewScoremodel(
      rsid: json['rsid'] ?? '',
      taskId: json['taskId'] ?? '',
      taskTargetId: json['taskTargetId'] ?? '',
      contentId: json['contentId'] ?? '',
      errorType: json['errorType'] ?? '',
      errorValue: json['errorValue'] ?? '',
      errorScore: json['errorScore'] ?? '',
      userId: json['userId'] ?? '',
      comment: json['comment'] ?? '',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toString()),
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rsid': rsid,
      'taskId': taskId,
      'taskTargetId': taskTargetId,
      'contentId': contentId,
      'errorType': errorType,
      'errorValue': errorValue,
      'errorScore': errorScore,
      'userId': userId,
      'comment': comment,
      'createdDate': createdDate.toIso8601String(),
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
    };
  }
}
