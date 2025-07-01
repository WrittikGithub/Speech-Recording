import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_editingtextfield.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_elevatedbutton.dart';
import 'package:sdcp_rebuild/core/appconstants.dart';
import 'package:sdcp_rebuild/presentation/blocs/cubit/toggle_password_cubit.dart';
import 'dart:math' as math;
import 'package:sdcp_rebuild/presentation/blocs/signup_bloc/signup_bloc.dart';
import 'package:sdcp_rebuild/data/models/country_model.dart';
import 'package:sdcp_rebuild/data/models/language_model.dart';
import 'package:sdcp_rebuild/presentation/screens/login_page/loginpage.dart';
import 'package:sdcp_rebuild/presentation/blocs/login_bloc/login_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/login_page/apple_email_form.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  bool _rememberMe = false;
  
  String? _selectedCountryId;
  String? _selectedLanguageId;
  List<Country> countries = [];
  List<Language> languages = [];
  bool isLoadingCountries = true;
  bool isLoadingLanguages = true;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadLanguages();
  }

  Future<void> _loadCountries() async {
    final response = await context.read<SignupBloc>().repository.getCountries();
    if (!response.error && response.data != null) {
      setState(() {
        countries = response.data!;
        isLoadingCountries = false;
      });
    } else {
      setState(() {
        isLoadingCountries = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load countries: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadLanguages() async {
    final response = await context.read<SignupBloc>().repository.getLanguages();
    if (!response.error && response.data != null) {
      setState(() {
        languages = response.data!;
        isLoadingLanguages = false;
      });
    } else {
      setState(() {
        isLoadingLanguages = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load languages: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCountrySearchSheet(BuildContext context) {
    if (isLoadingCountries) return;

    List<Country> filteredCountries = List.from(countries);

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
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search country...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              filteredCountries = countries
                                  .where((country) => 
                                      country.CountryName.toLowerCase()
                                          .contains(value.toLowerCase()) ||
                                      country.ISD.toLowerCase()
                                          .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          leading: country.flagFileUrl.isNotEmpty
                              ? Image.network(
                                  country.flagFileUrl,
                                  height: 24,
                                  width: 24,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.flag),
                                )
                              : const Icon(Icons.flag),
                          title: Text('${country.CountryName} (${country.ISD})'),
                          onTap: () {
                            setState(() {
                              _selectedCountryId = country.id;
                              _countryController.text = country.CountryName;
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

  void _showLanguageSearchSheet(BuildContext context) {
    if (isLoadingLanguages) return;

    List<Language> filteredLanguages = List.from(languages);

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
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search language...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              filteredLanguages = languages
                                  .where((language) => 
                                      language.languageName.toLowerCase()
                                          .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filteredLanguages.length,
                      itemBuilder: (context, index) {
                        final language = filteredLanguages[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.language,
                              color: Colors.purple,
                              size: 20,
                            ),
                          ),
                          title: Text(language.languageName),
                          onTap: () {
                            setState(() {
                              _selectedLanguageId = language.languageId;
                              _languageController.text = language.languageName;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Purple circular background
          Positioned(
            right: -ResponsiveUtils.wp(25),
            top: -ResponsiveUtils.hp(15),
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                height: ResponsiveUtils.hp(40),
                width: ResponsiveUtils.wp(80),
                decoration: BoxDecoration(
                  color: Appcolors.kpurpleColor.withOpacity(.8),
                  borderRadius: BorderRadius.circular(150),
                ),
              ),
            ),
          ),
          // Add BlocListener for Apple Sign-In states
          BlocListener<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state is AppleSignInNeedsMoreInfoState) {
                // Show the email dialog when Apple doesn't provide email
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) => AppleEmailFormDialog(
                    appleUserId: state.appleUserId,
                    displayName: state.displayName,
                  ),
                );
              }
            },
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.wp(5)),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        ResponsiveSizedBox.height20,
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                Appconstants.logo,
                                height: ResponsiveUtils.hp(17),
                                width: ResponsiveUtils.wp(55),
                                fit: BoxFit.contain,
                              ),
                              ResponsiveSizedBox.height20,
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.wp(6),
                                  fontWeight: FontWeight.bold,
                                  color: Appcolors.kpurpleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ResponsiveSizedBox.height30,
                        // Form fields
                        CustomEditingTextField(
                          title: 'Full Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                          icon: Icons.person,
                          controller: _fullNameController,
                          hintText: 'Enter Full Name',
                        ),
                        ResponsiveSizedBox.height20,
                        CustomEditingTextField(
                          title: 'Email Address',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                          icon: Icons.email,
                          controller: _emailController,
                          hintText: 'Enter Email Address',
                        ),
                        ResponsiveSizedBox.height20,
                        CustomEditingTextField(
                          title: 'Username',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                          icon: Icons.account_circle,
                          controller: _usernameController,
                          hintText: 'Enter Username',
                        ),
                        ResponsiveSizedBox.height20,
                        BlocBuilder<TogglepasswordCubit, bool>(
                          builder: (context, state) {
                            return CustomEditingTextField(
                              title: 'Password',
                              obscureText: state,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  state ? Icons.visibility_off : Icons.visibility,
                                  color: Appcolors.kpurpleColor,
                                ),
                                onPressed: () {
                                  context.read<TogglepasswordCubit>().togglePassword();
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                return null;
                              },
                              icon: Icons.lock,
                              controller: _passwordController,
                              hintText: 'Enter Password',
                            );
                          },
                        ),
                        ResponsiveSizedBox.height20,
                        BlocBuilder<TogglepasswordCubit, bool>(
                          builder: (context, state) {
                            return CustomEditingTextField(
                              title: 'Confirm Password',
                              obscureText: state,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  state ? Icons.visibility_off : Icons.visibility,
                                  color: Appcolors.kpurpleColor,
                                ),
                                onPressed: () {
                                  context.read<TogglepasswordCubit>().togglePassword();
                                },
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              icon: Icons.lock_outline,
                              controller: _confirmPasswordController,
                              hintText: 'Confirm Password',
                            );
                          },
                        ),
                        ResponsiveSizedBox.height20,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Appcolors.kpurplelightColor.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 2,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Country',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.wp(4),
                                  color: Colors.black87,
                                ),
                              ),
                              if (isLoadingCountries)
                                const Center(
                                  child: CircularProgressIndicator(),
                                )
                              else
                                TextFormField(
                                  readOnly: true,
                                  controller: _countryController,
                                  decoration: InputDecoration(
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      width: ResponsiveUtils.wp(8),
                                      height: ResponsiveUtils.wp(8),
                                      decoration: BoxDecoration(
                                        color: Appcolors.kpurplelightColor.withOpacity(.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.flag,
                                        color: Appcolors.kpurpleColor,
                                        size: ResponsiveUtils.wp(5),
                                      ),
                                    ),
                                    suffixIcon: const Icon(Icons.arrow_drop_down),
                                    border: InputBorder.none,
                                    hintText: 'Select Country',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty || _selectedCountryId == null) {
                                      return 'Please select a country';
                                    }
                                    return null;
                                  },
                                  onTap: () => _showCountrySearchSheet(context),
                                ),
                            ],
                          ),
                        ),
                        ResponsiveSizedBox.height20,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Appcolors.kpurplelightColor.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 2,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mother Tongue',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.wp(4),
                                  color: Colors.black87,
                                ),
                              ),
                              if (isLoadingLanguages)
                                const Center(
                                  child: CircularProgressIndicator(),
                                )
                              else
                                TextFormField(
                                  readOnly: true,
                                  controller: _languageController,
                                  decoration: InputDecoration(
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      width: ResponsiveUtils.wp(8),
                                      height: ResponsiveUtils.wp(8),
                                      decoration: BoxDecoration(
                                        color: Appcolors.kpurplelightColor.withOpacity(.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.language,
                                        color: Appcolors.kpurpleColor,
                                        size: ResponsiveUtils.wp(5),
                                      ),
                                    ),
                                    suffixIcon: const Icon(Icons.arrow_drop_down),
                                    border: InputBorder.none,
                                    hintText: 'Select Mother Tongue',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty || _selectedLanguageId == null) {
                                      return 'Please select a mother tongue';
                                    }
                                    return null;
                                  },
                                  onTap: () => _showLanguageSearchSheet(context),
                                ),
                            ],
                          ),
                        ),
                        ResponsiveSizedBox.height20,
                        CustomEditingTextField(
                          title: 'Contact Number',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your contact number';
                            }
                            return null;
                          },
                          icon: Icons.phone,
                          controller: _contactController,
                          hintText: 'Enter Contact Number',
                        ),
                        ResponsiveSizedBox.height20,
                        // Terms and Conditions checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: Appcolors.kpurpleColor,
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: const Text(
                                  'I agree to the Terms and Conditions',
                                  style: TextStyle(
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ResponsiveSizedBox.height30,
                        // Signup Button
                        _buildSignupButton(),
                        ResponsiveSizedBox.height20,
                        // Login option
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? "),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Appcolors.kpurpleColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ResponsiveSizedBox.height30,
                        // Google Sign-Up Button
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        ResponsiveSizedBox.height20,
                        _buildSocialButton(
                          text: 'Sign up with Google',
                          icon: Icons.login,
                          backgroundColor: Colors.white,
                          textColor: Colors.black87,
                          onPressed: () {
                            final loginBloc = BlocProvider.of<LoginBloc>(context);
                            loginBloc.add(GoogleSignInEvent());
                          },
                        ),
                        const SizedBox(height: 10),
                        // _buildSocialButton(
                        //   text: 'Sign up with Apple',
                        //   icon: Icons.apple,
                        //   backgroundColor: Colors.black,
                        //   textColor: Colors.white,
                        //   onPressed: () {
                        //     final loginBloc = BlocProvider.of<LoginBloc>(context);
                        //     loginBloc.add(AppleSignInEvent());
                        //   },
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupButton() {
    return BlocConsumer<SignupBloc, SignupState>(
      listener: (context, state) {
        print('Current SignupBloc state: $state');
        
        if (state is SignupSuccessState) {
          print('Signup success detected! Message: ${state.message}');
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to login page using MaterialPageRoute instead of named route
          print('Navigating to login page...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScreenLoginPage()),
          );
        } else if (state is SignupErrorState) {
          print('Signup error detected! Message: ${state.message}');
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        // Show loading indicator during signup process
        if (state is SignupLoadingState) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        // Return signup button
        return CustomElevatedButton(
          backgroundcolor: Appcolors.kpurpleColor.withOpacity(.8),
          onpress: () {
            if (_formKey.currentState!.validate()) {
              if (!_rememberMe) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please accept the terms and conditions'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Dispatch signup event
              context.read<SignupBloc>().add(
                SignupButtonClickEvent(
                  userFullName: _fullNameController.text,
                  userEmailAddress: _emailController.text,
                  userName: _usernameController.text,
                  userPassword: _passwordController.text,
                  passwordConfirmation: _confirmPasswordController.text,
                  country: _selectedCountryId ?? '',
                  userContact: _contactController.text,
                  mtongue: _selectedLanguageId ?? '',
                  authRememberCheck: _rememberMe ? "1" : "0",
                ),
              );
            }
          },
          text: 'Sign Up',
        );
      },
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: textColor, size: 22),
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 1,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactController.dispose();
    _countryController.dispose();
    _languageController.dispose();
    super.dispose();
  }
} 