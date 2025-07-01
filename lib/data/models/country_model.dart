class Country {
  final String id;
  final String CountryName;
  final String ISD;
  final String flagFile;

  Country({
    required this.id,
    required this.CountryName,
    required this.ISD,
    required this.flagFile,
  });

  // Generate the full URL for the flag
  String get flagFileUrl => 'https://vacha.langlex.com/assets/images/countryFlags/$flagFile';

  factory Country.fromJson(Map<String, dynamic> json) {
    // Print the JSON for debugging
    print('Parsing country: ${json['CountryName']}');
    
    return Country(
      id: json['id']?.toString() ?? '',
      CountryName: json['CountryName']?.toString() ?? '',
      ISD: json['ISD']?.toString() ?? '',
      flagFile: json['flagFile']?.toString() ?? '',
    );
  }
} 