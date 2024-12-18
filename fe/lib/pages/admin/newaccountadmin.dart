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

  // Account fields
  String username = '';
  String password = '';
  String role = 'admin';
  String status = '';

  // Member fields
  String name = '';
  String positionId = ''; // This will now be set using the dropdown
  String address = '';
  String phoneNumber = '';
  String email = '';

  bool isLoading = false;
  List<Map<String, dynamic>> positions = []; // To store positions from the API

  @override
  void initState() {
    super.initState();
    fetchPositions();
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

  // Create account and member API calls
  Future<void> createAccountAndMember() async {
    setState(() => isLoading = true);

    try {
      // First API call to create the account
      final accountResponse = await http.post(
        Uri.parse('http://10.0.2.2:8081/signUp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
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
      final accountId = accountData['username']; // Ensure API returns the username or account_id

      // Second API call to create the member
      final memberResponse = await http.post(
        Uri.parse('http://10.0.2.2:8081/createmembers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'account_id': accountId,
          'name': name,
          'position_id': positionId,
          'address': address,
          'phone_number': phoneNumber,
          'email': email,
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
              Text(
                'Account Information',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                onChanged: (value) => username = value, // Update variable directly
                onSaved: (value) => username = value!,
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
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => password = value, // Update variable directly
                onSaved: (value) => password = value!,
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
              Text(
                'Member Information',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value, // Update variable directly
                onSaved: (value) => name = value!,
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
                decoration: InputDecoration(labelText: 'Address'),
                onChanged: (value) => address = value, // Update variable directly
                onSaved: (value) => address = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.number,
                onChanged: (value) => phoneNumber = value, // Update variable directly
                onSaved: (value) => phoneNumber = value!,
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
                decoration: InputDecoration(labelText: 'Email'),
                onChanged: (value) => email = value, // Update variable directly
                onSaved: (value) => email = value!,
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
                    _formKey.currentState!.save();
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
