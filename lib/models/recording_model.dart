class RecordingModel {
  final String contentId;
  final String taskTargetId;
  final String projectId;
  final String userId;
  final String userType;
  final String audioContent;
  final String fileName;
  final String fileSize;
  final String duration;
  final String bitRate;
  final String channel;
  final String samplingRate;
  final String recordedBy;
  final DateTime dateRecorded;
  final String status;
  final String additionalNotes;

  RecordingModel({
    required this.contentId,
    required this.taskTargetId,
    required this.projectId,
    required this.userId,
    required this.userType,
    required this.audioContent,
    required this.fileName,
    required this.fileSize,
    required this.duration,
    required this.bitRate,
    required this.channel,
    required this.samplingRate,
    required this.recordedBy,
    required this.dateRecorded,
    required this.status,
    this.additionalNotes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'taskTargetId': taskTargetId,
      'projectId': projectId,
      'userId': userId,
      'userType': userType,
      'audioContent': audioContent,
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration,
      'bitRate': bitRate,
      'channel': channel,
      'samplingRate': samplingRate,
      'recordedBy': recordedBy,
      'dateRecorded': dateRecorded.toIso8601String(),
      'status': status,
      'additionalNotes': additionalNotes,
    };
  }

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      contentId: json['contentId'] ?? '',
      taskTargetId: json['taskTargetId'] ?? '',
      projectId: json['projectId'] ?? '',
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
      audioContent: json['audioContent'] ?? '',
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? '',
      duration: json['duration'] ?? '',
      bitRate: json['bitRate'] ?? '',
      channel: json['channel'] ?? '',
      samplingRate: json['samplingRate'] ?? '',
      recordedBy: json['recordedBy'] ?? '',
      dateRecorded: json['dateRecorded'] != null 
          ? DateTime.parse(json['dateRecorded']) 
          : DateTime.now(),
      status: json['status'] ?? '',
      additionalNotes: json['additionalNotes'] ?? '',
    );
  }
} 