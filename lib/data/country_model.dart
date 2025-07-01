class Country {
  final String id;
  final String CountryName;
  final String flagFile;
  final String ISD;

  Country({
    required this.id,
    required this.CountryName,
    required this.flagFile,
    required this.ISD,
  });

  String get flagFileUrl => 'https://vacha.langlex.com/assets/images/countryFlags/$flagFile';

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'].toString(),
      CountryName: json['CountryName'].toString(),
      flagFile: json['flagFile'].toString(),
      ISD: json['ISD'].toString(),
    );
  }
} 