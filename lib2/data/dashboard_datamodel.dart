class DashboardDatamodel {
  final int totalTasks;
  final int totalCompletedTask;
  final int totalPendingTask;
  final int totalPendingRecordTask;
  final int totalPendingReviewTask;

  DashboardDatamodel({
    required this.totalTasks,
    required this.totalCompletedTask,
    required this.totalPendingTask,
    required this.totalPendingRecordTask,
    required this.totalPendingReviewTask,
  });

  factory DashboardDatamodel.fromJson(Map<String, dynamic> json) {
    return DashboardDatamodel(
      totalTasks: int.parse(json['totalTasks'] ?? '0'),
      totalCompletedTask: json['totalCompletedTask'] ?? 0,
      totalPendingTask: json['totalPendingTask'] ?? 0,
      totalPendingRecordTask: int.parse(json['totalPendingRecordTask'] ?? '0'),
      totalPendingReviewTask: int.parse(json['totalPendingReviewTask'] ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks.toString(),
      'totalCompletedTask': totalCompletedTask,
      'totalPendingTask': totalPendingTask,
      'totalPendingRecordTask': totalPendingRecordTask.toString(),
      'totalPendingReviewTask': totalPendingReviewTask.toString(),
    };
  }
}