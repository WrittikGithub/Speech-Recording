class CommentModel {
  final String commentId;
  final String taskTargetId;
  final String comment;
  final String createdDate;
  final String lastModifiedDate;
  final String commentBy;

  CommentModel({
    required this.commentId,
    required this.taskTargetId,
    required this.comment,
    required this.createdDate,
    required this.lastModifiedDate,
    required this.commentBy,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId'] ?? '',
      taskTargetId: json['taskTargetId'] ?? '',
      comment: json['comment'] ?? '',
      createdDate: json['createdDate'] ?? '',
      lastModifiedDate: json['lastModifiedDate'] ?? '',
      commentBy: json['commentBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'taskTargetId': taskTargetId,
      'comment': comment,
      'createdDate': createdDate,
      'lastModifiedDate': lastModifiedDate,
      'commentBy': commentBy,
    };
  }
}
