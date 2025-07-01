class Language {
  final String languageId;
  final String languageName;
  final String languageCode;
  final String? apiLangCode;
  final String? googleLangCode;

  Language({
    required this.languageId,
    required this.languageName,
    this.languageCode = '',
    this.apiLangCode,
    this.googleLangCode,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    // Print the JSON for debugging
    print('Parsing language: ${json['languageName']}');
    
    return Language(
      languageId: json['languageId']?.toString() ?? '',
      languageName: json['languageName']?.toString() ?? '',
      languageCode: json['languageCode']?.toString() ?? '',
      apiLangCode: json['apiLangCode']?.toString(),
      googleLangCode: json['googleLangCode']?.toString(),
    );
  }
} 