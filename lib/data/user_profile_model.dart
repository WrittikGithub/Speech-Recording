class UserProfileModel {
  final String? userId;
  final String? userName;
  final String? userCode;
  final String? userFullName;
  final String? userEmailAddress;
  final String? userContact;
  final String? userType;
  final String? userCv;
  final String? createdDate;
  final String? lastModifiedDate;
  final String? status;
  final String? mtongue;
  final String? loginStatus;
  final String? mTranslation;
  final String? verificationToken;

  UserProfileModel({
    this.userId,
    this.userName,
    this.userCode,
    this.userFullName,
    this.userEmailAddress,
    this.userContact,
    this.userType,
    this.userCv,
    this.createdDate,
    this.lastModifiedDate,
    this.status,
    this.mtongue,
    this.loginStatus,
    this.mTranslation,
    this.verificationToken,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      userCode: json['userCode'] as String?,
      userFullName: json['userFullName'] as String?,
      userEmailAddress: json['userEmailAddress'] as String?,
      userContact: json['userContact'] as String?,
      userType: json['userType'] as String?,
      userCv: json['user_cv'] as String?,
      createdDate: json['createdDate'] as String?,
      lastModifiedDate: json['lastModifiedDate'] as String?,
      status: json['status'] as String?,
      mtongue: json['mtongue'] as String?,
      loginStatus: json['loginStatus'] as String?,
      mTranslation: json['mTranslation'] as String?,
      verificationToken: json['verification_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userCode': userCode,
      'userFullName': userFullName,
      'userEmailAddress': userEmailAddress,
      'userContact': userContact,
      'userType': userType,
      'user_cv': userCv,
      'createdDate': createdDate,
      'lastModifiedDate': lastModifiedDate,
      'status': status,
      'mtongue': mtongue,
      'loginStatus': loginStatus,
      'mTranslation': mTranslation,
      'verification_token': verificationToken,
    };
  }
}
