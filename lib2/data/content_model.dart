// class ContentModel {
//   final String contentId;
//   final String taskId;
//   final String csid;
//   final String sourceContent;
//   final String sourceWordCount;
//   final String sourceCharCount;
//   final String contentReference;
//   final String? targetContentPath;
//   final String? contentReferencePath;
//   final String targetLanguageId;
//   final String targetContent;
//   final String? reviewedContent;
//   final String? additionalNotes;
//   final String? raiseIssue;
//   final String? transLastModifiedBy;
//   final String? revLastModifiedBy;
//   final String? transLastModifiedDate;
//   final String? revLastModifiedDate;
//   final String reviewScoreStatus;
//   final String targetDigitizationStatus;
//   final String? targetreviewerReviewStatus;
//   final String taskTargetId;
//   final String projectName;

//   ContentModel({
//     required this.contentId,
//     required this.taskId,
//     required this.csid,
//     required this.sourceContent,
//     required this.sourceWordCount,
//     required this.sourceCharCount,
//     required this.contentReference,
//     required this.targetLanguageId,
//     required this.targetContent,
//     this.reviewedContent,
//     this.additionalNotes,
//     this.raiseIssue,
//     this.transLastModifiedBy,
//     this.revLastModifiedBy,
//     this.transLastModifiedDate,
//     this.revLastModifiedDate,
//     required this.reviewScoreStatus,
//     required this.targetDigitizationStatus,
//     this.targetreviewerReviewStatus,
//     required this.taskTargetId,
//     required this.projectName,
//     this.targetContentPath,
//     this.contentReferencePath,
//   });

//   factory ContentModel.fromJson(Map<String, dynamic> json) {
//     return ContentModel(
//       contentId: json['contentId'] ?? '',
//       taskId: json['taskId'] ?? '',
//       csid: json['csid'] ?? '',
//       sourceContent: json['sourceContent'] ?? '',
//       sourceWordCount: json['sourceWordCount'] ?? '',
//       sourceCharCount: json['sourceCharCount'] ?? '',
//       contentReference: json['contentReference'] ?? '',
//       targetLanguageId: json['targetLanguageId'] ?? '',
//       targetContent: json['targetContent'] ?? '',
//       reviewedContent: json['reviewedContent'],
//       additionalNotes: json['additionalNotes'],
//       raiseIssue: json['raiseIssue'],
//       transLastModifiedBy: json['transLastModifiedBy'],
//       revLastModifiedBy: json['revLastModifiedBy'],
//       transLastModifiedDate: json['transLastModifiedDate'],
//       revLastModifiedDate: json['revLastModifiedDate'],
//       reviewScoreStatus: json['reviewScoreStatus'] ?? '',
//       targetDigitizationStatus: json['targetDigitizationStatus'] ?? '',
//       targetreviewerReviewStatus: json['targetreviewerReviewStatus'],
//       taskTargetId: json['taskTargetId'] ?? '',
//       projectName: json['projectName'] ?? '',
//        targetContentPath: json['targetContentPath'],
//       contentReferencePath: json['contentReferencePath'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'contentId': contentId,
//       'taskId': taskId,
//       'csid': csid,
//       'sourceContent': sourceContent,
//       'sourceWordCount': sourceWordCount,
//       'sourceCharCount': sourceCharCount,
//       'contentReference': contentReference,
//       'targetLanguageId': targetLanguageId,
//       'targetContent': targetContent,
//       'reviewedContent': reviewedContent,
//       'additionalNotes': additionalNotes,
//       'raiseIssue': raiseIssue,
//       'transLastModifiedBy': transLastModifiedBy,
//       'revLastModifiedBy': revLastModifiedBy,
//       'transLastModifiedDate': transLastModifiedDate,
//       'revLastModifiedDate': revLastModifiedDate,
//       'reviewScoreStatus': reviewScoreStatus,
//       'targetDigitizationStatus': targetDigitizationStatus,
//       'targetreviewerReviewStatus': targetreviewerReviewStatus,
//       'taskTargetId': taskTargetId,
//       'projectName': projectName,
//     };
//   }
// }
//////////////////////
class ContentModel {
  final String contentId;
  final String taskId;
  final String csid;
  final String sourceContent;
  final String sourceWordCount;
  final String sourceCharCount;
  final String contentReferenceUrl;       // URL for reference content (renamed from contentReference)
  final String contentReferencePath;      // Local path for downloaded reference content
  final String targetLanguageId;
  final String targetContentUrl;          // URL for target content (renamed from targetContent)
  final String targetContentPath;         // Local path for downloaded target content
  final String? reviewedContent;
  final String? additionalNotes;
  final String? raiseIssue;
  final String? transLastModifiedBy;
  final String? revLastModifiedBy;
  final String? transLastModifiedDate;
  final String? revLastModifiedDate;
  final String reviewScoreStatus;
  final String targetDigitizationStatus;
  final String? targetreviewerReviewStatus;
  final String taskTargetId;
  final String projectName;

  ContentModel({
    required this.contentId,
    required this.taskId,
    required this.csid,
    required this.sourceContent,
    required this.sourceWordCount,
    required this.sourceCharCount,
    required this.contentReferenceUrl,      // renamed
    this.contentReferencePath = '',         // new field with default value
    required this.targetLanguageId,
    required this.targetContentUrl,         // renamed
    this.targetContentPath = '',            // new field with default value
    this.reviewedContent,
    this.additionalNotes,
    this.raiseIssue,
    this.transLastModifiedBy,
    this.revLastModifiedBy,
    this.transLastModifiedDate,
    this.revLastModifiedDate,
    required this.reviewScoreStatus,
    required this.targetDigitizationStatus,
    this.targetreviewerReviewStatus,
    required this.taskTargetId,
    required this.projectName,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      contentId: json['contentId'] ?? '',
      taskId: json['taskId'] ?? '',
      csid: json['csid'] ?? '',
      sourceContent: json['sourceContent'] ?? '',
      sourceWordCount: json['sourceWordCount'] ?? '',
      sourceCharCount: json['sourceCharCount'] ?? '',
      contentReferenceUrl: json['contentReference'] ?? '',    // map from old field name
      contentReferencePath: json['contentReferencePath'] ?? '',
      targetLanguageId: json['targetLanguageId'] ?? '',
      targetContentUrl: json['targetContent'] ?? '',          // map from old field name
      targetContentPath: json['targetContentPath'] ?? '',
      reviewedContent: json['reviewedContent'],
      additionalNotes: json['additionalNotes'],
      raiseIssue: json['raiseIssue'],
      transLastModifiedBy: json['transLastModifiedBy'],
      revLastModifiedBy: json['revLastModifiedBy'],
      transLastModifiedDate: json['transLastModifiedDate'],
      revLastModifiedDate: json['revLastModifiedDate'],
      reviewScoreStatus: json['reviewScoreStatus'] ?? '',
      targetDigitizationStatus: json['targetDigitizationStatus'] ?? '',
      targetreviewerReviewStatus: json['targetreviewerReviewStatus'],
      taskTargetId: json['taskTargetId'] ?? '',
      projectName: json['projectName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'taskId': taskId,
      'csid': csid,
      'sourceContent': sourceContent,
      'sourceWordCount': sourceWordCount,
      'sourceCharCount': sourceCharCount,
      'contentReference': contentReferenceUrl,     // map to old field name
      'contentReferencePath': contentReferencePath,
      'targetLanguageId': targetLanguageId,
      'targetContent': targetContentUrl,           // map to old field name
      'targetContentPath': targetContentPath,
      'reviewedContent': reviewedContent,
      'additionalNotes': additionalNotes,
      'raiseIssue': raiseIssue,
      'transLastModifiedBy': transLastModifiedBy,
      'revLastModifiedBy': revLastModifiedBy,
      'transLastModifiedDate': transLastModifiedDate,
      'revLastModifiedDate': revLastModifiedDate,
      'reviewScoreStatus': reviewScoreStatus,
      'targetDigitizationStatus': targetDigitizationStatus,
      'targetreviewerReviewStatus': targetreviewerReviewStatus,
      'taskTargetId': taskTargetId,
      'projectName': projectName,
    };
  }
}