import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fe/pages/manager/fetchimagemanager.dart';
import 'package:fe/pages/manager/insertimagemanager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class DetailAccountmanager extends StatefulWidget {
  final Map<String, dynamic> accountDetails;

  DetailAccountmanager({required this.accountDetails});

  @override
  _DetailAccountmanagerState createState() => _DetailAccountmanagerState();
}

class _DetailAccountmanagerState extends State<DetailAccountmanager> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

  // Controllers for text fields
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Variables for dropdown selections
  String? _selectedStatus;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and dropdown values with existing data
    _passwordController = TextEditingController(text: ""); // Leave password blank for security
    _nameController = TextEditingController(text: widget.accountDetails['member_name']);
    _addressController = TextEditingController(text: widget.accountDetails['address']);
    _phoneController = TextEditingController(text: widget.accountDetails['phone']);
    _emailController = TextEditingController(text: widget.accountDetails['email']);

    _selectedStatus = widget.accountDetails['status'];
    _selectedRole = widget.accountDetails['role'];
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    _passwordController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateDetails() async {
    try {
      // Update Account Data
      final accountUrl = Uri.parse('$apiBaseUrl/updateaccountusername/${widget.accountDetails['username']}');
      final accountBody = {
        'status': _selectedStatus,
        'role': _selectedRole,
        'password': _passwordController.text.isNotEmpty ? _passwordController.text : null,
      };
      final accountResponse = await http.put(
        accountUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(accountBody),
      );

      // Update Member Data
      final memberUrl = Uri.parse('$apiBaseUrl/updateMember/${widget.accountDetails['id']}');
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

      if (accountResponse.statusCode == 200 && memberResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Details updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update details')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Details: ${widget.accountDetails['username']}'),
      ),
      body: SingleChildScrollView( // Wrap entire content in a scrollable area
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: ['able', 'disable'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
                decoration: InputDecoration(labelText: 'Status'),
              ),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              Text('Member Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),

              ElevatedButton(
                onPressed: _updateDetails,
                child: Text('Update'),
              ),

              Text('Image Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Registered Face: ${widget.accountDetails['registeredFace'] ?? 'N/A'}'),

              Container(
                height: 300, // Adjust this height as needed
                child: FetchFaceImagesPage(
                  memberId: widget.accountDetails['id'].toString(),
                ),
              ),
              SizedBox(height: 20),
              Container(
                height: 300, // Adjust this height as needed
                child: InsertImage(
                  memberId: widget.accountDetails['id'].toString(),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
