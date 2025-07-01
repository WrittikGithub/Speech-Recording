class NotificationMOdel {
  final String notificationId;
  final String userId;
  final String notification;
  final String read;
  final DateTime createdDate;
  final DateTime lastModifiedDate;
  final String genuserId;
  final String taskId;
  final String projectId;

  NotificationMOdel({
    required this.notificationId,
    required this.userId,
    required this.notification,
    required this.read,
    required this.createdDate,
    required this.lastModifiedDate,
    required this.genuserId,
    required this.taskId,
    required this.projectId,
  });

  // Factory constructor to create a Notification from JSON
  factory  NotificationMOdel.fromJson(Map<String, dynamic> json) {
    return  NotificationMOdel(
      notificationId: json['notificationId'] ?? '',
      userId: json['userId'] ?? '',
      notification: json['notification'] ?? '',
      read: json['read'] ?? '0',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toString()),
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toString()),
      genuserId: json['genuserId'] ?? '',
      taskId: json['taskId'] ?? '',
      projectId: json['projectId'] ?? '',
    );
  }

  // Method to convert Notification to JSON
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'notification': notification,
      'read': read,
      'createdDate': createdDate.toString(),
      'lastModifiedDate': lastModifiedDate.toString(),
      'genuserId': genuserId,
      'taskId': taskId,
      'projectId': projectId,
    };
  }}