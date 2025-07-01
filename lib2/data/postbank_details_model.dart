class PostbankDetailsModel {
  final String beneficiaryName;
  final String bankAccountNumber;
  final String ifsc;
  final String bankName;
  final String bankAddress;
  final String bankBranch;
  final String pan;
  final String aadhar;
  final String userId;
  final String? panCopy;
  final String? accountProof;

  PostbankDetailsModel({
    required this.beneficiaryName,
    required this.bankAccountNumber,
    required this.ifsc,
    required this.bankName,
    required this.bankAddress,
    required this.bankBranch,
    required this.pan,
    required this.aadhar,
    required this.userId,
    this.panCopy,
    this.accountProof,
  });

  Map<String, dynamic> toJson() {
    return {
      'beneficiaryName': beneficiaryName,
      'bankAccountNumber': bankAccountNumber,
      'ifsc': ifsc,
      'bankName': bankName,
      'bankAddress': bankAddress,
      'bankBranch': bankBranch,
      'pan': pan,
      'aadhar': aadhar,
      'userId': userId,
      if (panCopy != null) 'panCopy': panCopy,
      if (accountProof != null) 'accountProof': accountProof,
    };
  }

  factory PostbankDetailsModel.fromJson(Map<String, dynamic> json) {
    return PostbankDetailsModel(
      beneficiaryName: json['beneficiaryName'] as String,
      bankAccountNumber: json['bankAccountNumber'] as String,
      ifsc: json['ifsc'] as String,
      bankName: json['bankName'] as String,
      bankAddress: json['bankAddress'] as String,
      bankBranch: json['bankBranch'] as String,
      pan: json['pan'] as String,
      aadhar: json['aadhar'] as String,
      userId: json['userId'] as String,
      panCopy: json['panCopy'] as String?,
      accountProof: json['accountProof'] as String?,
    );
  }
}