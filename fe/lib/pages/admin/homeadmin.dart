import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomepageAd extends StatefulWidget {
  const HomepageAd({Key? key}) : super(key: key);
  static String routeName = "/home_admin";

  @override
  _HomepageAdState createState() => _HomepageAdState();
}

class _HomepageAdState extends State<HomepageAd> {
  final _storage = const FlutterSecureStorage();
  String _memberName = ''; // Default name
  String _username = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      // Retrieve the username from secure storage using the correct key
      final username = await _storage.read(key: "KEY_USERNAME") ?? '';  // Use 'username' as the key

      // Debug: Print the retrieved username
      debugPrint('Retrieved username: $username');

      setState(() {
        _username = username;
      });

      // Proceed only if username exists
      if (username.isNotEmpty) {
        final response = await http.get(
          Uri.parse('http://10.0.2.2:8081/getAccountById/$username'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Debug: Print the API response
          debugPrint('API response: $data');

          // Update member name if available
          setState(() {
            _memberName = data['accountInfo']['member_name'] ?? 'Admin';
          });
        } else {
          // Handle non-200 status codes
          setState(() {
            _memberName = 'Admin';
          });
          debugPrint('Failed to fetch user details: ${response.body}');
        }
      }
    } catch (error) {
      // Handle exceptions during the API call or JSON decoding
      setState(() {
        _memberName = 'Admin';
      });
      debugPrint('Error fetching user details: $error');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Homepage'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Hi $_memberName',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            Text(
              'Welcome Back',
              style: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
