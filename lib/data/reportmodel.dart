class Reportmodel {
  final String userName;
  final String totalTaskAssigned;
  final String tasksCompleted;
  final String taskWordCount;
  final String totalReviewAssigned;
  final String reviewCompleted;
  final String reviewWordCount;
  final DateTime fromDate;
  final DateTime toDate;

  Reportmodel({
    required this.userName,
    required this.totalTaskAssigned,
    required this.tasksCompleted,
    required this.taskWordCount,
    required this.totalReviewAssigned,
    required this.reviewCompleted,
    required this.reviewWordCount,
    required this.fromDate,
    required this.toDate,
  });

  // Factory constructor to create Reportmodel from JSON
  factory Reportmodel.fromJson(Map<String, dynamic> json) {
    return Reportmodel(
      userName: json['userName'] ?? '',
      totalTaskAssigned: json['totalTaskAssigned'] ?? '0',
      tasksCompleted: json['tasksCompleted'] ?? '0',
      taskWordCount: json['taskWordCount'] ?? '0',
      totalReviewAssigned: json['totalReviewAssigned'] ?? '0',
      reviewCompleted: json['reviewCompleted'] ?? '0',
      reviewWordCount: json['reviewWordCount'] ?? '0',
      fromDate: _parseDate(json['from']),
      toDate: _parseDate(json['to']),
    );
  }

  // Helper method to parse dates
  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Method to convert Reportmodel to JSON
  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'totalTaskAssigned': totalTaskAssigned,
      'tasksCompleted': tasksCompleted,
      'taskWordCount': taskWordCount,
      'totalReviewAssigned': totalReviewAssigned,
      'reviewCompleted': reviewCompleted,
      'reviewWordCount': reviewWordCount,
      'from': fromDate.toString().split(' ')[0], // Returns just the date part
      'to': toDate.toString().split(' ')[0],
    };
  }
}
