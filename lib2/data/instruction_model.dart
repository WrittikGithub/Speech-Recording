class InstructionDataModel {
  final String? contentReference;
  final String? additionalNotes;

  InstructionDataModel({
     this.contentReference,
     this.additionalNotes,
  });

  // Factory constructor for creating an instance from JSON
  factory InstructionDataModel.fromJson(Map<String, dynamic> json) {
    return InstructionDataModel(
      contentReference: json['contentReference']??'',
      additionalNotes: json['additionalNotes']??'',
    );
  }

  // Method to convert an instance into JSON
  Map<String, dynamic> toJson() {
    return {
      'contentReference': contentReference,
      'additionalNotes': additionalNotes,
    };
  }
}