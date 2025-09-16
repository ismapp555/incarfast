import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_car/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_car/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum AuthMode { signIn, signUp }

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthMode _authMode = AuthMode.signIn;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  final Color _primaryColor = const Color(0xFFBEF574);
  final Color _backgroundColor = Colors.black;

  void _switchAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.signIn
          ? AuthMode.signUp
          : AuthMode.signIn;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return; // Invalid!
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    final authService = AuthService(FirebaseAuth.instance);
    String? result;

    if (_authMode == AuthMode.signIn) {
      result = await authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      result = await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        name: _nameController.text,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result != "Signed In" && result != "Signed Up") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? "An error occurred"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _authMode == AuthMode.signIn
                      ? 'Welcome Back'
                      : 'Create Account',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        !value.contains('@') ||
                        !value.contains('.')) {
                      return 'Invalid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_authMode == AuthMode.signUp) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Full Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.5),
                            end: const Offset(0, 0),
                          ).animate(animation),
                          child: child,
                        );
                      },
                  child: _authMode == AuthMode.signUp
                      ? Column(
                          children: [
                            TextFormField(
                              controller: _phoneController,
                              decoration: _inputDecoration('Mobile Number'),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null ||
                                    !RegExp(
                                      r'^\+?[0-9]{10,13}$',
                                    ).hasMatch(value)) {
                                  return 'Invalid mobile number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: _inputDecoration('Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? CircularProgressIndicator(color: _primaryColor)
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 80,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: Text(
                          _authMode == AuthMode.signIn ? 'Sign In' : 'Sign Up',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _switchAuthMode,
                  child: Text(
                    _authMode == AuthMode.signIn
                        ? 'No account? Sign up'
                        : 'Have an account? Sign in',
                    style: textTheme.bodyMedium?.copyWith(color: _primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withAlpha(178)),
      filled: true,
      fillColor: Colors.white.withAlpha(26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
    );
  }
}
