import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/colors.dart'; // Adjust import for your colors
import 'package:sdcp_rebuild/core/endpoints.dart'; // Your Endpoints
import 'package:sdcp_rebuild/presentation/blocs/login_bloc/login_bloc.dart';

// Placeholder Country Model - ADAPT TO YOUR API RESPONSE
class Country {
  final String id;
  final String name;
  final String countryCode; // e.g., "+91" or "91"
  final String flagFile;

  Country({required this.id, required this.name, required this.countryCode, required this.flagFile});

  // Generate the full URL for the flag
  String get flagFileUrl => 'https://vacha.langlex.com/assets/images/countryFlags/$flagFile';

  factory Country.fromJson(Map<String, dynamic> json) {
    // Common keys are 'id', 'name', 'country_code', 'phonecode', 'dial_code'
    return Country(
      id: json['id']?.toString() ?? '', // Assuming 'id' is the direct key for country ID
      name: json['CountryName']?.toString() ?? '', // Matching API key 'CountryName'
      countryCode: json['ISD']?.toString() ?? '', // Matching API key 'ISD' for country code
      flagFile: json['flagFile']?.toString() ?? '', // Matching API key 'flagFile' for country flag
    );
  }

  // For DropdownSearch comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name; // Important for DropdownSearch to display name
}

// Placeholder Language Model - ADAPT TO YOUR API RESPONSE
class Language {
  final String id;
  final String name;

  Language({required this.id, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) {
    // Common keys are 'id', 'name', 'language_id', 'language_name'
    return Language(
      id: json['languageId']?.toString() ?? '', // Matching API key 'languageId'
      name: json['languageName']?.toString() ?? '', // Matching API key 'languageName'
    );
  }

  // For DropdownSearch comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name; // Important for DropdownSearch to display name
}

class AdditionalInfoPage extends StatefulWidget {
  final String googleUserId;
  final String email;
  final String displayName;
  final String? existingUserId;
  final String source; // 'signup' or 'signin'

  const AdditionalInfoPage({
    super.key,
    required this.googleUserId,
    required this.email,
    required this.displayName,
    this.existingUserId,
    this.source = 'signin', // Default to signin
  });

  @override
  _AdditionalInfoPageState createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends State<AdditionalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();

  List<Country> _countries = [];
  Country? _selectedCountry;
  bool _isLoadingCountries = true;
  String? _countriesError;

  List<Language> _languages = [];
  Language? _selectedLanguage;
  bool _isLoadingLanguages = true;
  String? _languagesError;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
    _fetchLanguages();
  }

  Future<void> _fetchCountries() async {
    setState(() {
      _isLoadingCountries = true;
      _countriesError = null;
    });
    try {
      // Your Endpoints.baseurl likely is 'https://vacha.langlex.com/Api/ApiController'
      // So, Endpoints.getCountries should be '/getCountry'
      final url = Uri.parse('${Endpoints.baseurl}${Endpoints.getCountries}');
      print('[AdditionalInfoPage] Fetching countries from: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data'] is List && (responseData['error'] == false || responseData['error'] == null) ) {
          List<Country> loadedCountries = (responseData['data'] as List)
              .map((countryJson) => Country.fromJson(countryJson as Map<String, dynamic>))
              .toList();
          setState(() {
            _countries = loadedCountries;
            if (_countries.isNotEmpty && _selectedCountry == null) {
              // Optionally pre-select or just load
            }
          });
        } else {
          throw Exception(responseData['message'] ?? 'Unexpected country data format or API error');
        }
      } else {
        throw Exception('Failed to load countries: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("[AdditionalInfoPage] Error fetching countries: $e");
      setState(() {
        _countriesError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingCountries = false;
      });
    }
  }

  Future<void> _fetchLanguages() async {
    setState(() {
      _isLoadingLanguages = true;
      _languagesError = null;
    });
    try {
      final url = Uri.parse('${Endpoints.baseurl}${Endpoints.getLanguages}');
      print('[AdditionalInfoPage] Fetching languages from: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data'] is List && (responseData['error'] == false || responseData['error'] == null)) {
          List<Language> loadedLanguages = (responseData['data'] as List)
              .map((langJson) => Language.fromJson(langJson as Map<String, dynamic>))
              .toList();
          setState(() {
            _languages = loadedLanguages;
          });
        } else {
          throw Exception(responseData['message'] ?? 'Unexpected language data format or API error');
        }
      } else {
        throw Exception('Failed to load languages: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("[AdditionalInfoPage] Error fetching languages: $e");
      setState(() {
        _languagesError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingLanguages = false;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCountry == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your country.'), backgroundColor: Colors.amber),
        );
        return;
      }
      if (_selectedLanguage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your mother tongue.'), backgroundColor: Colors.amber),
        );
        return;
      }
      
      String countryCodeToSend = _selectedCountry!.countryCode;
      if (!countryCodeToSend.startsWith('+') && countryCodeToSend.isNotEmpty) {
          countryCodeToSend = '+$countryCodeToSend';
      } else if (countryCodeToSend.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected country does not have a valid country code.'), backgroundColor: Colors.red),
        );
        return;
      }

      context.read<LoginBloc>().add(CompleteGoogleRegistrationEvent(
            googleUserId: widget.googleUserId,
            email: widget.email,
            displayName: widget.displayName,
            mobileNumber: _mobileController.text.trim(),
            countryCode: countryCodeToSend,
            motherTongueId: _selectedLanguage!.id,
          ));
    }
  }

  Widget _buildCountryDropdown() {
    return GestureDetector(
      onTap: () => _showCountrySearchSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          readOnly: true,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Country',
            hintText: 'Select your country',
            prefixIcon: _selectedCountry != null && _selectedCountry!.flagFile.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        _selectedCountry!.flagFileUrl,
                        height: 24,
                        width: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.flag_circle_outlined, color: Appcolors.kpurpleColor),
                      ),
                    ),
                  )
                : const Icon(Icons.flag_circle_outlined, color: Appcolors.kpurpleColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
          ),
          controller: TextEditingController(text: _selectedCountry?.name ?? ''),
          validator: (value) => _selectedCountry == null ? 'Please select a country' : null,
        ),
      ),
    );
  }

  void _showCountrySearchSheet(BuildContext context) {
    if (_isLoadingCountries) return;

    List<Country> filteredCountries = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          width: 40,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Select Country',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search country...',
                            prefixIcon: const Icon(Icons.search, color: Appcolors.kpurpleColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              filteredCountries = _countries
                                  .where((country) => 
                                      country.name.toLowerCase()
                                          .contains(value.toLowerCase()) ||
                                      country.countryCode.toLowerCase()
                                          .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoadingCountries
                      ? const Center(child: CircularProgressIndicator())
                      : _countriesError != null
                          ? Center(child: Text('Error: $_countriesError'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filteredCountries.length,
                              itemBuilder: (context, index) {
                                final country = filteredCountries[index];
                                return ListTile(
                                  leading: country.flagFile.isNotEmpty
                                    ? Image.network(
                                        country.flagFileUrl,
                                        height: 24,
                                        width: 40,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Appcolors.kpurpleColor.withOpacity(.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.flag,
                                            color: Appcolors.kpurpleColor,
                                            size: 20,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Appcolors.kpurpleColor.withOpacity(.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.flag,
                                          color: Appcolors.kpurpleColor,
                                          size: 20,
                                        ),
                                      ),
                                  title: Text('${country.name} (${country.countryCode})'),
                                  onTap: () {
                                    setState(() {
                                      _selectedCountry = country;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return GestureDetector(
      onTap: () => _showLanguageSearchSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          readOnly: true,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Mother Tongue',
            hintText: 'Select your mother tongue',
            prefixIcon: Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: Appcolors.kpurpleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.translate_outlined, color: Appcolors.kpurpleColor, size: 20),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
          ),
          controller: TextEditingController(text: _selectedLanguage?.name ?? ''),
          validator: (value) => _selectedLanguage == null ? 'Please select your mother tongue' : null,
        ),
      ),
    );
  }

  void _showLanguageSearchSheet(BuildContext context) {
    if (_isLoadingLanguages) return;

    List<Language> filteredLanguages = List.from(_languages);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          width: 40,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Select Mother Tongue',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search language...',
                            prefixIcon: const Icon(Icons.search, color: Appcolors.kpurpleColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              filteredLanguages = _languages
                                  .where((language) => 
                                      language.name.toLowerCase()
                                          .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoadingLanguages
                      ? const Center(child: CircularProgressIndicator())
                      : _languagesError != null
                          ? Center(child: Text('Error: $_languagesError'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filteredLanguages.length,
                              itemBuilder: (context, index) {
                                final language = filteredLanguages[index];
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Appcolors.kpurpleColor.withOpacity(.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.language,
                                      color: Appcolors.kpurpleColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(language.name),
                                  onTap: () {
                                    setState(() {
                                      _selectedLanguage = language;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to handle back navigation
  void _handleBackNavigation() {
    if (widget.source == 'signup') {
      Navigator.of(context).pushReplacementNamed('/signup');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.grey[50], // Lighter background for modern look
      appBar: AppBar(
        title: const Text('Complete Your Profile', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            fontSize: 20,
          )
        ),
        backgroundColor: Appcolors.kpurpleColor,
        elevation: 0, // Flat appbar for modern look
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _handleBackNavigation,
        ),
      ),
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccessState || state is LoginSuccessAppOneState) {
            // Consider a more robust navigation solution if you have nested navigators
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/main_page', (route) => false);
          } else if (state is LoginErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.redAccent),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Appcolors.kpurpleColor.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView( // Ensures content is scrollable
            child: Padding(
              padding: const EdgeInsets.all(24.0), // More padding for better spacing
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Profile Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Appcolors.kpurpleColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Appcolors.kpurpleColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome, ${widget.displayName}!', 
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700, 
                                        color: Appcolors.kpurpleColor,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.email,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.existingUserId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'ID: ${widget.existingUserId}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Section Header
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Appcolors.kpurpleColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Your Details", 
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Country Dropdown with improved styling
                    _buildCountryDropdown(),
                    const SizedBox(height: 20),

                    // Mobile Number with improved styling
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _mobileController,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: 'Enter your mobile number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Appcolors.kpurpleColor, width: 1.5),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 15.0, right: 10.0, top: 14, bottom: 14), // Adjust padding for alignment
                            child: _selectedCountry != null && _selectedCountry!.countryCode.isNotEmpty 
                                      ? Text(
                                          _selectedCountry!.countryCode.startsWith('+') 
                                              ? _selectedCountry!.countryCode 
                                              : '+${_selectedCountry!.countryCode}', 
                                          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)
                                        )
                                      : const Icon(Icons.phone_android_outlined, color: Appcolors.kpurpleColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (!RegExp(r'^[0-9]{7,15}$').hasMatch(value.trim())) {
                             return 'Enter a valid mobile number (7-15 digits).';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Language Dropdown
                    _buildLanguageDropdown(),
                    const SizedBox(height: 40),

                    // Button Row
                    Row(
                      children: [
                        // Back Button
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: _handleBackNavigation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(0, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('BACK', 
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              )
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Submit Button
                        Expanded(
                          flex: 2,
                          child: BlocBuilder<LoginBloc, LoginState>(
                            builder: (context, state) {
                              if (state is LoginLoadingState) {
                                return Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Appcolors.kpurpleColor.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              }
                              return ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Appcolors.kpurpleColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(0, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                ),
                                child: const Text('SUBMIT AND CONTINUE', 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  )
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24), // Extra space at the bottom
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }
} 