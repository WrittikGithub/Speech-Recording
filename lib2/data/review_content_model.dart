class ReviewContentModel {
  final String contentId;
  final String taskId;
  final String csid;
  final String sourceContent;
  final String sourceWordCount;
  final String maxCharCount;
  final String sourceCharCount;
  final String
      contentReferenceUrl; // URL for reference content (renamed from contentReference)
  final String contentReferencePath;
  final String targetLanguageId;
  final String? targetContent;
  final String? reviewedContent;
  final String targetWordCount;
  final String? additionalNotes;
  final String? var1;
  final String? var2;
  final String? var3;
  final String digitizationStatus;
  final String? reviewStatus;
  final String createdDate;
  final String lastModifiedDate;
  final String? digitizedDate;
  final String? reviewDate;
  final String? characterCount;
  final String? raiseIssue;
  final String? transLastModifiedBy;
  final String? revLastModifiedBy;
  final String? transLastModifiedDate;
  final String? revLastModifiedDate;
  final String? reviewScoreStatus;
  final String pageTitle;
  final String totalComments;
  final String sourceLanguage;
  final String targetLanguage;
  final String targetTaskTargetId;
  final String targetTargetContentUrl;
  final String targetTargetContentPath;
  final String targetDigitizationStatus;
  final String ttargetWordCount;
  final String ttargetCharacterCount;
  final String commentExist;
  final String targetContentId;
  final String? targetReviewStatus;
  final String projectName;

  ReviewContentModel({
    required this.contentId,
    required this.taskId,
    required this.csid,
    required this.sourceContent,
    required this.sourceWordCount,
    required this.maxCharCount,
    required this.sourceCharCount,
    required this.contentReferenceUrl, // renamed
    this.contentReferencePath = '',
    required this.targetLanguageId,
    this.targetContent,
    this.reviewedContent,
    required this.targetWordCount,
    this.additionalNotes,
    this.var1,
    this.var2,
    this.var3,
    required this.digitizationStatus,
    this.reviewStatus,
    required this.createdDate,
    required this.lastModifiedDate,
    this.digitizedDate,
    this.reviewDate,
    this.characterCount,
    this.raiseIssue,
    this.transLastModifiedBy,
    this.revLastModifiedBy,
    this.transLastModifiedDate,
    this.revLastModifiedDate,
    this.reviewScoreStatus,
    required this.pageTitle,
    required this.totalComments,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.targetTaskTargetId,
    required this.targetTargetContentUrl,
    this.targetTargetContentPath = '',
    required this.targetDigitizationStatus,
    required this.ttargetWordCount,
    required this.ttargetCharacterCount,
    required this.commentExist,
    required this.targetContentId,
    this.targetReviewStatus,
    required this.projectName,
  });

  factory ReviewContentModel.fromJson(Map<String, dynamic> json) {
    return ReviewContentModel(
      contentId: json['contentId'] ?? '',
      taskId: json['taskId'] ?? '',
      csid: json['csid'] ?? '',
      sourceContent: json['sourceContent'] ?? '',
      sourceWordCount: json['sourceWordCount'] ?? '',
      maxCharCount: json['maxCharCount'] ?? '',
      sourceCharCount: json['sourceCharCount'] ?? '',
      contentReferenceUrl: json['contentReference'] ?? '',
      contentReferencePath: json['contentReferencePath'] ?? '',
      targetLanguageId: json['targetLanguageId'] ?? '',
      targetContent: json['targetContent'],
      reviewedContent: json['reviewedContent'],
      targetWordCount: json['targetWordCount'] ?? '',
      additionalNotes: json['additionalNotes'],
      var1: json['var_1'],
      var2: json['var_2'],
      var3: json['var_3'],
      digitizationStatus: json['digitizationStatus'] ?? '',
      reviewStatus: json['reviewStatus'],
      createdDate: json['createdDate'] ?? '',
      lastModifiedDate: json['lastModifiedDate'] ?? '',
      digitizedDate: json['digitizedDate'],
      reviewDate: json['reviewDate'],
      characterCount: json['characterCount'],
      raiseIssue: json['raiseIssue'],
      transLastModifiedBy: json['transLastModifiedBy'],
      revLastModifiedBy: json['revLastModifiedBy'],
      transLastModifiedDate: json['transLastModifiedDate'],
      revLastModifiedDate: json['revLastModifiedDate'],
      reviewScoreStatus: json['reviewScoreStatus'],
      pageTitle: json['pageTitle'] ?? '',
      totalComments: json['totalComments'] ?? '',
      sourceLanguage: json['sourceLanguage'] ?? '',
      targetLanguage: json['targetLanguage'] ?? '',
      targetTaskTargetId: json['targetTaskTargetId'] ?? '',
      targetTargetContentUrl: json['targetTargetContent'] ?? '',
      targetTargetContentPath: json['targetContentPath'] ?? '',
      targetDigitizationStatus: json['targetDigitizationStatus'] ?? '',
      ttargetWordCount: json['TtargetWordCount'] ?? '',
      ttargetCharacterCount: json['TtargetCharacterCount'] ?? '',
      commentExist: json['commentExist'] ?? '',
      targetContentId: json['targetContentId'] ?? '',
      targetReviewStatus: json['targetReviewStatus'] ?? '',
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
      'maxCharCount': maxCharCount,
      'sourceCharCount': sourceCharCount,
      'contentReference': contentReferenceUrl,
      'contentReferencePath': contentReferencePath,
      'targetLanguageId': targetLanguageId,
      'targetContent': targetContent,
      'reviewedContent': reviewedContent,
      'targetWordCount': targetWordCount,
      'additionalNotes': additionalNotes,
      'var_1': var1,
      'var_2': var2,
      'var_3': var3,
      'digitizationStatus': digitizationStatus,
      'reviewStatus': reviewStatus,
      'createdDate': createdDate,
      'lastModifiedDate': lastModifiedDate,
      'digitizedDate': digitizedDate,
      'reviewDate': reviewDate,
      'characterCount': characterCount,
      'raiseIssue': raiseIssue,
      'transLastModifiedBy': transLastModifiedBy,
      'revLastModifiedBy': revLastModifiedBy,
      'transLastModifiedDate': transLastModifiedDate,
      'revLastModifiedDate': revLastModifiedDate,
      'reviewScoreStatus': reviewScoreStatus,
      'pageTitle': pageTitle,
      'totalComments': totalComments,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'targetTaskTargetId':targetTaskTargetId,
      'targetTargetContent': targetTargetContentUrl,
      'targetContentPath': targetTargetContentPath,
      'targetDigitizationStatus': targetDigitizationStatus,
      'TtargetWordCount': ttargetWordCount,
      'TtargetCharacterCount': ttargetCharacterCount,
      'commentExist': commentExist,
      'targetContentId': targetContentId,
      'targetReviewStatus': targetReviewStatus,
      'projectName': projectName,
    };
  }
}
///////////////////
// class ReviewContentModel {
//   final String taskId;
//   final String taskTargetId;
//   final String projectId;
//   final String taskPrefix;
//   final String csid;
//   final String sourceLanguageId;
//   final String targetLanguageId;
//   final String taskTitle;
//   final String taskType;
//   final String status;
//   final String reviewStatus;
//   final String createdBy;
//   final String createdMethod;
//   final String createdDate;
//   final String lastModifiedDate;
//   final String assignTranslation;
//   final String assignTranslationDate;
//   final String reviewTranslation;
//   final String reviewTranslationDate;
//   final String raiseIssue;
//   final String sourceWordCount;
//   final String importType;
//   final String newFileName;
//   final String digitizedDate;
//   final String reviewedDate;
//   final List<Content> contents;

//   ReviewContentModel({
//     required this.taskId,
//     required this.taskTargetId,
//     required this.projectId,
//     required this.taskPrefix,
//     required this.csid,
//     required this.sourceLanguageId,
//     required this.targetLanguageId,
//     required this.taskTitle,
//     required this.taskType,
//     required this.status,
//     required this.reviewStatus,
//     required this.createdBy,
//     required this.createdMethod,
//     required this.createdDate,
//     required this.lastModifiedDate,
//     required this.assignTranslation,
//     required this.assignTranslationDate,
//     required this.reviewTranslation,
//     required this.reviewTranslationDate,
//     required this.raiseIssue,
//     required this.sourceWordCount,
//     required this.importType,
//     required this.newFileName,
//     required this.digitizedDate,
//     required this.reviewedDate,
//     required this.contents,
//   });

//   factory ReviewContentModel.fromJson(Map<String, dynamic> json) {
//     return ReviewContentModel(
//       taskId: json['taskId'],
//       taskTargetId: json['taskTargetId'],
//       projectId: json['projectId'],
//       taskPrefix: json['taskPrefix'],
//       csid: json['csid'],
//       sourceLanguageId: json['sourceLanguageId'],
//       targetLanguageId: json['targetLanguageId'],
//       taskTitle: json['taskTitle'],
//       taskType: json['taskType'],
//       status: json['status'],
//       reviewStatus: json['reviewStatus'],
//       createdBy: json['createdBy'],
//       createdMethod: json['createdMethod'],
//       createdDate: json['createdDate'],
//       lastModifiedDate: json['lastModifiedDate'],
//       assignTranslation: json['assign_translation'],
//       assignTranslationDate: json['assign_translation_date'],
//       reviewTranslation: json['review_translation'],
//       reviewTranslationDate: json['review_translation_date'],
//       raiseIssue: json['raiseIssue'],
//       sourceWordCount: json['sourceWordCount'],
//       importType: json['importType'],
//       newFileName: json['newFileName'],
//       digitizedDate: json['digitizedDate'],
//       reviewedDate: json['reviewedDate'],
//       contents: List<Content>.from(
//           json['contents'].map((x) => Content.fromJson(x))),
//     );
//   }
// }
// class Content {
//   final String contentId;
//   final String taskId;
//   final String csid;
//   final String sourceContent;
//   final String sourceWordCount;
//   final String maxCharCount;
//   final String sourceCharCount;
//   final String contentReference;
//   final String? targetLanguageId;
//   final String? targetContent;
//   final String? reviewedContent;
//   final String? targetWordCount;
//   final String? additionalNotes;
//   final String? var1;
//   final String? var2;
//   final String? var3;
//   final String digitizationStatus;
//   final String? reviewStatus;
//   final String createdDate;
//   final String lastModifiedDate;
//   final String? digitizedDate;
//   final String? reviewDate;
//   final String? characterCount;
//   final String? raiseIssue;
//   final String? transLastModifiedBy;
//   final String? revLastModifiedBy;
//   final String? transLastModifiedDate;
//   final String? revLastModifiedDate;
//   final String? reviewScoreStatus;
//   final String pageTitle;
//   final String totalComments;
//   final String sourceLanguage;
//   final String targetLanguage;
//   final String targetTargetContent;
//   final String targetDigitizationStatus;
//   final String ttargetWordCount;
//   final String ttargetCharacterCount;
//   final String commentExist;
//   final String targetContentId;
//   final String targetReviewStatus;
//   final String projectName;

//   Content({
//     required this.contentId,
//     required this.taskId,
//     required this.csid,
//     required this.sourceContent,
//     required this.sourceWordCount,
//     required this.maxCharCount,
//     required this.sourceCharCount,
//     required this.contentReference,
//     this.targetLanguageId,
//     this.targetContent,
//     this.reviewedContent,
//     this.targetWordCount,
//     this.additionalNotes,
//     this.var1,
//     this.var2,
//     this.var3,
//     required this.digitizationStatus,
//     this.reviewStatus,
//     required this.createdDate,
//     required this.lastModifiedDate,
//     this.digitizedDate,
//     this.reviewDate,
//     this.characterCount,
//     this.raiseIssue,
//     this.transLastModifiedBy,
//     this.revLastModifiedBy,
//     this.transLastModifiedDate,
//     this.revLastModifiedDate,
//     this.reviewScoreStatus,
//     required this.pageTitle,
//     required this.totalComments,
//     required this.sourceLanguage,
//     required this.targetLanguage,
//     required this.targetTargetContent,
//     required this.targetDigitizationStatus,
//     required this.ttargetWordCount,
//     required this.ttargetCharacterCount,
//     required this.commentExist,
//     required this.targetContentId,
//     required this.targetReviewStatus,
//     required this.projectName,
//   });

//   factory Content.fromJson(Map<String, dynamic> json) {
//     return Content(
//       contentId: json['contentId'],
//       taskId: json['taskId'],
//       csid: json['csid'],
//       sourceContent: json['sourceContent'],
//       sourceWordCount: json['sourceWordCount'],
//       maxCharCount: json['maxCharCount'],
//       sourceCharCount: json['sourceCharCount'],
//       contentReference: json['contentReference'],
//       targetLanguageId: json['targetLanguageId'],
//       targetContent: json['targetContent'],
//       reviewedContent: json['reviewedContent'],
//       targetWordCount: json['targetWordCount'],
//       additionalNotes: json['additionalNotes'],
//       var1: json['var_1'],
//       var2: json['var_2'],
//       var3: json['var_3'],
//       digitizationStatus: json['digitizationStatus'],
//       reviewStatus: json['reviewStatus'],
//       createdDate: json['createdDate'],
//       lastModifiedDate: json['lastModifiedDate'],
//       digitizedDate: json['digitizedDate'],
//       reviewDate: json['reviewDate'],
//       characterCount: json['characterCount'],
//       raiseIssue: json['raiseIssue'],
//       transLastModifiedBy: json['transLastModifiedBy'],
//       revLastModifiedBy: json['revLastModifiedBy'],
//       transLastModifiedDate: json['transLastModifiedDate'],
//       revLastModifiedDate: json['revLastModifiedDate'],
//       reviewScoreStatus: json['reviewScoreStatus'],
//       pageTitle: json['pageTitle'],
//       totalComments: json['totalComments'],
//       sourceLanguage: json['sourceLanguage'],
//       targetLanguage: json['targetLanguage'],
//       targetTargetContent: json['targetTargetContent'],
//       targetDigitizationStatus: json['targetDigitizationStatus'],
//       ttargetWordCount: json['TtargetWordCount'],
//       ttargetCharacterCount: json['TtargetCharacterCount'],
//       commentExist: json['commentExist'],
//       targetContentId: json['targetContentId'],
//       targetReviewStatus: json['targetReviewStatus'],
//       projectName: json['projectName'],
//     );
//   }
// }