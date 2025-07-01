class LanguageModel {
  final String languageId;
  final String languageName;
  final String languageCode;
  final String? apiLangCode;
  final String? googleLangCode;
  final String status;
  final String createdDate;
  final String lastModifiedDate;

  LanguageModel({
    required this.languageId,
    required this.languageName,
    required this.languageCode,
    this.apiLangCode,
    this.googleLangCode,
    required this.status,
    required this.createdDate,
    required this.lastModifiedDate,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      languageId: json['languageId'] ?? '',
      languageName: json['languageName'] ?? '',
      languageCode: json['languageCode'] ?? '',
      apiLangCode: json['apiLangCode'],
      googleLangCode: json['googleLangCode'],
      status: json['status'] ?? '',
      createdDate: json['createdDate'] ?? '',
      lastModifiedDate: json['lastModifiedDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languageId': languageId,
      'languageName': languageName,
      'languageCode': languageCode,
      'apiLangCode': apiLangCode,
      'googleLangCode': googleLangCode,
      'status': status,
      'createdDate': createdDate,
      'lastModifiedDate': lastModifiedDate,
    };
  }
}
