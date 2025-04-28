import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:rail_madat_manager/home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isHidden = true;
  String _errorMessage = '';
  final box = GetStorage();

  // Replace with your computer's local IP address
  static const String _baseUrl = 'http://192.168.35.44:8000';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/manager/login/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          // Successful login
          final userId = json.decode(response.body)['user_id'];

          // Store user_id using GetStorage
          final box = GetStorage();
          await box.write('email', _emailController.text.trim());
          await box.write('user_id', userId);
          Get.off(() => HomePage()); // Navigate to home page
        } else {
          // Handle different status codes
          final errorResponse = json.decode(response.body);
          setState(() {
            _errorMessage =
                errorResponse['message'] ?? 'Login failed. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Connection error. Please check your network.';
        });
        print('Login error: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Text(
                "Rail Madat",
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xff6A8DFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 250,
                height: 250,
                child: DotLottieLoader.fromAsset(
                  "assets/animations/loginLottie.lottie",
                  frameBuilder: (ctx, dotlottie) {
                    if (dotlottie != null) {
                      return Lottie.memory(dotlottie.animations.values.single);
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(fontSize: 16),
                          prefixIcon: Icon(
                            Icons.alternate_email_rounded,
                            size: 20,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: TextFormField(
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        obscureText: _isHidden,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          suffix: GestureDetector(
                            child: Icon(
                              _isHidden
                                  ? Icons.remove_red_eye
                                  : Icons.visibility_off,
                            ),
                            onTap:
                                () => setState(() {
                                  _isHidden = !_isHidden;
                                }),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    _isLoading
                        ? CircularProgressIndicator()
                        : Container(
                          height: 50,
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                  Color(0xff6A8DFF),
                                ),
                                foregroundColor: MaterialStateProperty.all(
                                  Color(0xffffffff),
                                ),
                              ),
                              onPressed: _login,
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
