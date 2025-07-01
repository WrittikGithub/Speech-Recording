class User {
  final String id;
  final String userName;
  final String userFullName;
  final String userEmailAddress;
  final String userContact;
  final String token;
  final String signupApp;
  
  User({
    required this.id,
    required this.userName,
    required this.userFullName,
    required this.userEmailAddress,
    required this.userContact,
    required this.token,
    this.signupApp = "0",
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing user data: $json');
    
    // Try different possible field names for signup_app
    String signupAppValue = '0';
    if (json['signup_app'] != null) {
      signupAppValue = json['signup_app'].toString();
    } else if (json['signupApp'] != null) {
      signupAppValue = json['signupApp'].toString();
    } else if (json['signup_app_value'] != null) {
      signupAppValue = json['signup_app_value'].toString();
    }
    
    print('signup_app value: $signupAppValue');
    
    return User(
      id: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userFullName: json['userFullName']?.toString() ?? '',
      userEmailAddress: json['userEmailAddress']?.toString() ?? '',
      userContact: json['userContact']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      signupApp: signupAppValue,
    );
  }
} 