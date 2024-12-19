import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fe/pages/admin/addimageadmin.dart';

class NewAccAdmin extends StatefulWidget {
  const NewAccAdmin({Key? key}) : super(key: key);
  static String routeName = "/newaccount_admin";

  @override
  _NewAccAdminState createState() => _NewAccAdminState();
}

class _NewAccAdminState extends State<NewAccAdmin> {
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers for form fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String role = 'admin';
  String status = '';
  String positionId = '';
  bool isLoading = false;
  List<Map<String, dynamic>> positions = []; // To store positions from the API

  @override
  void initState() {
    super.initState();
    fetchPositions();
  }

  @override
  void dispose() {
    // Dispose controllers when not needed
    usernameController.dispose();
    passwordController.dispose();
    nameController.dispose();
    addressController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // Fetch positions from API
  Future<void> fetchPositions() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8081/getPosition'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          setState(() {
            positions = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch positions.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching positions.')),
      );
    }
  }
  Future<void> createAccountAndMember() async {
    setState(() => isLoading = true);

    try {
      final accountResponse = await http.post(
        Uri.parse('http://10.0.2.2:8081/signUp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text,
          'password': passwordController.text,
          'role': role,
          'status': status,
        }),
      );

      if (accountResponse.statusCode != 200) {
        final error = jsonDecode(accountResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Failed to create account.')),
        );
        return;
      }

      final accountData = jsonDecode(accountResponse.body);
      final accountId = accountData['username'];

      final memberResponse = await http.post(
        Uri.parse('http://10.0.2.2:8081/createmembers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'account_id': accountId,
          'name': nameController.text,
          'position_id': positionId,
          'address': addressController.text,
          'phone_number': phoneNumberController.text,
          'email': emailController.text,
        }),
      );

      if (memberResponse.statusCode == 201) {
        final memberData = jsonDecode(memberResponse.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(memberData['message'] ?? 'Member created successfully!')),
        );

        final memberId = memberData['member_id'].toString();

        Future.delayed(Duration(seconds: 2), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddImage(memberId: memberId)),
          );
        });
      } else {
        final error = jsonDecode(memberResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Failed to create member')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account and Member')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Account Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextFormField(
                controller: usernameController, // Use controller
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a username';
                  }
                  if (value.length < 4) {
                    return 'Username must be at least 4 characters long';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController, // Use controller
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Status'),
                value: status.isEmpty ? null : status,
                items: ['able', 'disable']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) => setState(() => status = value!),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Role'),
                value: role,
                items: ['admin', 'manager', 'staff']
                    .map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role),
                ))
                    .toList(),
                onChanged: (value) => setState(() => role = value!),
              ),
              SizedBox(height: 20),
              Text('Member Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: nameController, // Use controller
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a name';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Position'),
                value: positionId.isEmpty ? null : positionId,
                items: positions.map((position) {
                  return DropdownMenuItem(
                    value: position['id'].toString(),
                    child: Text(position['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => positionId = value!),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select a position';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: addressController, // Use controller
                decoration: InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: phoneNumberController, // Use controller
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a phone number';
                  }
                  if (value.length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController, // Use controller
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter an email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    createAccountAndMember();
                  }
                },
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Create Account and Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
