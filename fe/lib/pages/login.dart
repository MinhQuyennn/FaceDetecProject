import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../pages/admin/homeadmin.dart';
import '../pages/staff/homeestaff.dart';
import '../pages/manager/homemanager.dart';
import 'package:fe/components/background.dart';

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
  final String pathURLL = "http://10.0.2.2:8081";
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    final String? username = await _storage.read(key: "KEY_USERNAME");
    final String? password = await _storage.read(key: "KEY_PASSWORD");

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
          'password': _passwordController.text,
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
          Navigator.pushReplacementNamed(context, HomepageAd.routeName);
        } else if (userRole == 'manager') {
          print('Navigating to manager homepage');
          await _storage.write(key: 'token-manager', value: token);
          Navigator.pushReplacementNamed(context, HomepageManager.routeName);
        } else {
          print('Invalid user role: $userRole');
          Fluttertoast.showToast(msg: 'Invalid user role');
        }
      } else if (response.statusCode == 403) {
        // Handle "Account is disabled" error
        final data = jsonDecode(response.body);
        final String errorMessage = data['error'] ?? 'Account is disabled';
        print('Account disabled error: $errorMessage');
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        final data = jsonDecode(response.body);
        final String errorMessage = data['error'] ?? 'Login failed';
        print('Error: $errorMessage');
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (error) {
      print('An error occurred during login: $error');
      Fluttertoast.showToast(
        msg: 'An error occurred during login',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Background(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                "LOGIN",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2661FA),
                    fontSize: 36),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
            ),
            SizedBox(height: size.height * 0.05),
            Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  const Text(
                    "Remember me",
                    style: TextStyle(fontSize: 14, color: Color(0xFF2661FA)),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Blue button color
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "LOGIN",
                  style: TextStyle(
                    color: Colors.white, // White text
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
