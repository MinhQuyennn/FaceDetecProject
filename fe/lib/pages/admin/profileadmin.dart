import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class viewProfileAd extends StatefulWidget {
  const viewProfileAd({Key? key}) : super(key: key);
  static String routeName = "/viewprofile_admin";

  @override
  _viewProfileAdState createState() => _viewProfileAdState();
}

class _viewProfileAdState extends State<viewProfileAd> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Controllers for text fields
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Variables for dropdown selections
  String? _selectedStatus;
  String? _selectedRole;

  Map<String, dynamic>? _profileDetails;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, String>> _faceImageData = [];

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  String _getUpdatedImageUrl(String imageUrl) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return imageUrl.replaceAll('localhost', '10.0.2.2');
    }
    return imageUrl;
  }

  Future<void> _fetchFaceData(String memberId) async {
    final url = Uri.parse('$apiBaseUrl/getImageByID/$memberId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          List<Map<String, String>> faceImageData = [];
          for (var item in data) {
            final String? faceImageUrl = item['face_image_url'];
            final String? imageId = item['id'].toString(); // Make sure it's a string
            if (faceImageUrl != null && imageId != null) {
              faceImageData.add({
                'id': imageId,  // Ensure 'id' is a string
                'url': _getUpdatedImageUrl(faceImageUrl),
              });
            }
          }


          setState(() {
            _faceImageData = faceImageData;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No valid data found for this member.';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'No face data found for this account.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch face data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching face data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeProfile() async {
    try {
      final username = await _storage.read(key: "KEY_USERNAME") ?? '';
      debugPrint('Retrieved username: $username');

      if (username.isEmpty) throw Exception("Username not found in storage.");

      final url = Uri.parse('$apiBaseUrl/getAccountById/$username');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Status'] == 'Success') {
          final accountInfo = data['accountInfo'];

          setState(() {
            _profileDetails = accountInfo;
            _passwordController = TextEditingController(text: "");
            _nameController = TextEditingController(text: accountInfo['member_name']?.toString() ?? '');
            _addressController = TextEditingController(text: accountInfo['address']?.toString() ?? '');
            _phoneController = TextEditingController(text: accountInfo['phone_number']?.toString() ?? '');
            _emailController = TextEditingController(text: accountInfo['email']?.toString() ?? '');
            _selectedStatus = accountInfo['status'];
            _selectedRole = accountInfo['role'];
            _isLoading = false;
          });

          // Ensure id is passed as string
          await _fetchFaceData(accountInfo['id']?.toString() ?? '');
        } else {
          throw Exception("Failed to fetch account info.");
        }
      } else {
        throw Exception("Failed to fetch profile details.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error1: $e")));
    }
  }

  Future<void> _updateDetails() async {
    if (_profileDetails == null) return;

    try {
      final accountUrl = Uri.parse(
          '$apiBaseUrl/updateaccountusername/${_profileDetails!['username']}');
      final accountBody = {
        'status': _selectedStatus,
        'role': _selectedRole,
        'password': _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      };
      final accountResponse = await http.put(
        accountUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(accountBody),
      );

      final memberUrl = Uri.parse(
          '$apiBaseUrl/updateMember/${_profileDetails!['id']}');
      final memberBody = {
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
      };
      final memberResponse = await http.put(
        memberUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(memberBody),
      );

      if (accountResponse.statusCode == 200 &&
          memberResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Details updated successfully')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update details')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Are you sure you want to log out?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storage.deleteAll();
        Navigator.pushReplacementNamed(context, '/login');
      } catch (error) {
        print('Error logging out: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading Profile...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile: ${_profileDetails?['username']}'),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              items: ['able', 'disable']
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => _selectedStatus = newValue!),
              decoration: InputDecoration(labelText: 'Status'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['manager', 'admin', 'staff']
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => _selectedRole = newValue!),
              decoration: InputDecoration(labelText: 'Role'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Text('Member Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name')),
            TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address')),
            TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number')),
            TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _updateDetails, child: Text('Update')),
            SizedBox(height: 20),
            Text('Image Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            if (_faceImageData.isNotEmpty)
              ..._faceImageData.map((image) => Image.network(
                    image['url']!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  )),
            if (_faceImageData.isEmpty)
              Text(
                'You don’t have an image.',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
