import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import '../../Modules/Purchase/features/pages/masters/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFF2563EB); // Primary theme color
  bool _showError = false; // To control the visibility of the error message
  bool _obscurePassword = true; // To control password visibility

  @override
  void initState() {
    super.initState();
    // Pre-fill the email and password fields
    _emailController.text = 'user@gmail.com';
    _passwordController.text = 'Admin@123';
  }

  // Initialize Hive and navigate to HomePage after successful login
  Future<void> _initializeAppAfterLogin() async {
    try {
      // Ensure Hive is initialized
      if (!Hive.isAdapterRegistered(0)) {
        // Register any adapters if needed
      }

      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      // Navigate to the HomePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      print('Error initializing app after login: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing app: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;

      if (email == 'user@gmail.com' && password == 'Admin@123') {
        // Initialize Hive and navigate to HomePage
        _initializeAppAfterLogin();
      } else {
        setState(() {
          _showError = true; // Show error message
        });
      }
    }
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF9FAFB), // Updated background color
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine responsive values based on screen width
            double screenWidth = constraints.maxWidth;
            bool isTabletOrWeb = screenWidth > 600;

            // Calculate responsive padding
            double horizontalPadding = isTabletOrWeb
                ? screenWidth * 0.15
                : 24.0;
            double verticalPadding = isTabletOrWeb ? 40.0 : 24.0;

            // Calculate responsive font sizes
            double titleFontSize = isTabletOrWeb ? 32.0 : 28.0;
            double subtitleFontSize = isTabletOrWeb ? 18.0 : 16.0;
            double buttonFontSize = isTabletOrWeb ? 20.0 : 18.0;
            double errorFontSize = isTabletOrWeb ? 16.0 : 14.0;

            // Calculate responsive icon size
            double iconSize = isTabletOrWeb ? 80.0 : 60.0;
            double fieldIconSize = isTabletOrWeb ? 24.0 : 20.0;

            // Calculate responsive button height
            double buttonHeight = isTabletOrWeb ? 64.0 : 56.0;

            // Calculate responsive field padding
            double fieldVerticalPadding = isTabletOrWeb ? 20.0 : 16.0;
            double fieldHorizontalPadding = isTabletOrWeb ? 20.0 : 16.0;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Error Message (shown when _showError is true)
                        if (_showError)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              isTabletOrWeb ? 16.0 : 12.0,
                            ),
                            margin: EdgeInsets.only(
                              bottom: isTabletOrWeb ? 24.0 : 16.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: isTabletOrWeb ? 24.0 : 20.0,
                                ),
                                SizedBox(width: isTabletOrWeb ? 12.0 : 8.0),
                                Expanded(
                                  child: Text(
                                    'Invalid email or password. Please try again.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: errorFontSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // App Logo/Icon
                        Container(
                          padding: EdgeInsets.all(isTabletOrWeb ? 20.0 : 16.0),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isTabletOrWeb ? 32.0 : 24.0),

                        // App Title
                        Text(
                          'Fabric Purchase App',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: isTabletOrWeb ? 12.0 : 8.0),
                        Text(
                          'Please login to continue',
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: isTabletOrWeb ? 48.0 : 40.0),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            NoLeadingOrMultipleSpacesFormatter(), // Apply the formatter
                          ],
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: primaryColor,
                              size: fieldIconSize,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: fieldVerticalPadding,
                              horizontal: fieldHorizontalPadding,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) {
                            // Hide error message when user starts typing
                            if (_showError) {
                              setState(() {
                                _showError = false;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isTabletOrWeb ? 24.0 : 20.0),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          inputFormatters: [
                            NoLeadingOrMultipleSpacesFormatter(), // Apply the formatter
                          ],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: primaryColor,
                              size: fieldIconSize,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                // Updated icon logic:
                                // When password is hidden (dots) -> show eye with strike
                                // When password is visible (text) -> show eye without strike
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: primaryColor,
                                size: fieldIconSize,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: fieldVerticalPadding,
                              horizontal: fieldHorizontalPadding,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) {
                            // Hide error message when user starts typing
                            if (_showError) {
                              setState(() {
                                _showError = false;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isTabletOrWeb ? 12.0 : 8.0),

                        // Forgot Password (optional)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Handle forgot password
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ),
                        SizedBox(height: isTabletOrWeb ? 32.0 : 24.0),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: primaryColor.withOpacity(0.3),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isTabletOrWeb ? 32.0 : 24.0),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: subtitleFontSize,
                              ),
                            ),
                            Text(
                              'Sign Up',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: subtitleFontSize,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
