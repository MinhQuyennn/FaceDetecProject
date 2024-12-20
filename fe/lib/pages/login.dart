import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../pages/admin/homeadmin.dart';
import '../pages/staff/homeestaff.dart';
import 'package:fe/constants/colors.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);
  static String routeName = "/login";

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Login> {
  final _storage = const FlutterSecureStorage();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  var pathURLL = "http://10.0.2.2:8081";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    final String? username = await _storage.read(key: "KEY_USERNAME");
    final String? password = await _storage.read(key: "KEY_PASSWORD");
    debugPrint('Auto-login username: $username');
    debugPrint('Auto-login password: $password');

    if (username != null && password != null) {
      _emailController.text = username;
      _passwordController.text = password;
      _handleSubmit();
    }
  }

  void _handleSubmit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$pathURLL/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _emailController.text,
          'password': _passwordController.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['token'];
        final String userRole = data['role'];
        final String username = data['username'].toString();

        // Store data in secure storage
        await _storage.write(key: 'KEY_USERNAME', value: _emailController.text);
        await _storage.write(
            key: 'KEY_PASSWORD', value: _passwordController.text);
        await _storage.write(key: 'username', value: username);
        await _storage.write(
            key: 'currentRole', value: userRole); // If user is an admin

        if (userRole == 'staff') {
          print('Navigating to staff homepage');
          await _storage.write(key: 'token-staff', value: token);
          Navigator.pushReplacementNamed(context, Homepagestaff.routeName);
        } else if (userRole == 'admin') {
          print('Navigating to admin homepage');
          await _storage.write(key: 'token-admin', value: token);
          Navigator.pushReplacementNamed(context, Homepagestaff.routeName);
        } else {
          print('Invalid user role: $userRole');
          Fluttertoast.showToast(msg: 'Invalid user role');
        }
      }
    } catch (error) {
      print('An error occurred during login: $error');
      Fluttertoast.showToast(msg: 'An error occurred during login');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.1),
              Text(
                "Welcome back.",
                style: TextStyle(
                  color: Color(0xFF161925),
                  fontWeight: FontWeight.w600,
                  fontSize: 32,
                ),
              ),
              SizedBox(height: size.height * 0.15),
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Username",
                        labelStyle: TextStyle(color: CustomColor.bluePrimary),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: CustomColor.bluePrimary, width: 2),
                        ),
                      ),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: size.height * 0.02),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: CustomColor.bluePrimary),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: CustomColor.bluePrimary, width: 2),
                        ),
                      ),
                      controller: _passwordController,
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.045),
              CheckboxListTile(
                value: _isLoading,
                onChanged: (bool? newValue) {
                  setState(() {
                    _isLoading = newValue!;
                  });
                },
                title: Text(
                  "Remember me",
                  style: TextStyle(color: CustomColor.bluePrimary),
                ),
                activeColor: CustomColor.bluePrimary,
              ),
              SizedBox(height: size.height * 0.05),
              Container(
                width: MediaQuery.of(context).size.width - 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColor.bluePrimary,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    textStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 5,
                  ).copyWith(
                    backgroundColor:
                        MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return CustomColor.bluePrimary.withOpacity(0.8);
                      } else if (states.contains(MaterialState.disabled)) {
                        return Colors.blue;
                      }
                      return CustomColor.bluePrimary;
                    }),
                    foregroundColor:
                        MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.white.withOpacity(0.8);
                      }
                      return Colors.white;
                    }),
                  ),
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.015),
            ],
          ),
        ),
      ),
    );
  }
}
