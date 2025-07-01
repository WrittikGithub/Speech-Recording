class BankdetailsModel {
  final String userBankId;
  final String userId;
  final String beneficiaryName;
  final String bankAccountNumber;
  final String ifsc;
  final String bankName;
  final String bankAddress;
  final String bankBranch;
  final String pan;
  final String aadhar;
  final String panCopy;
  final String accountProof;
  final String status;
  final DateTime createdDate;
  final DateTime lastModifiedDate;

  BankdetailsModel({
    required this.userBankId,
    required this.userId,
    required this.beneficiaryName,
    required this.bankAccountNumber,
    required this.ifsc,
    required this.bankName,
    required this.bankAddress,
    required this.bankBranch,
    required this.pan,
    required this.aadhar,
    required this.panCopy,
    required this.accountProof,
    required this.status,
    required this.createdDate,
    required this.lastModifiedDate,
  });

  factory BankdetailsModel.fromJson(Map<String, dynamic> json) {
    return BankdetailsModel(
      userBankId: json['userbankid'] ?? '',
      userId: json['userId'] ?? '',
      beneficiaryName: json['beneficiaryName'] ?? '',
      bankAccountNumber: json['bankAccountNumber'] ?? '',
      ifsc: json['ifsc'] ?? '',
      bankName: json['bankName'] ?? '',
      bankAddress: json['bankAddress'] ?? '',
      bankBranch: json['bankBranch'] ?? '',
      pan: json['pan'] ?? '',
      aadhar: json['aadhar'] ?? '',
      panCopy: json['panCopy'] ?? '',
      accountProof: json['accountProof'] ?? '',
      status: json['status'] ?? '',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toString()),
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userbankid': userBankId,
      'userId': userId,
      'beneficiaryName': beneficiaryName,
      'bankAccountNumber': bankAccountNumber,
      'ifsc': ifsc,
      'bankName': bankName,
      'bankAddress': bankAddress,
      'bankBranch': bankBranch,
      'pan': pan,
      'aadhar': aadhar,
      'panCopy': panCopy,
      'accountProof': accountProof,
      'status': status,
      'createdDate': createdDate.toIso8601String(),
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
    };
  }

  BankdetailsModel copyWith({
    String? userBankId,
    String? userId,
    String? beneficiaryName,
    String? bankAccountNumber,
    String? ifsc,
    String? bankName,
    String? bankAddress,
    String? bankBranch,
    String? pan,
    String? aadhar,
    String? panCopy,
    String? accountProof,
    String? status,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) {
    return BankdetailsModel(
      userBankId: userBankId ?? this.userBankId,
      userId: userId ?? this.userId,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifsc: ifsc ?? this.ifsc,
      bankName: bankName ?? this.bankName,
      bankAddress: bankAddress ?? this.bankAddress,
      bankBranch: bankBranch ?? this.bankBranch,
      pan: pan ?? this.pan,
      aadhar: aadhar ?? this.aadhar,
      panCopy: panCopy ?? this.panCopy,
      accountProof: accountProof ?? this.accountProof,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }
}