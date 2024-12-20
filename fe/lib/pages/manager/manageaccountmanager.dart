import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fe/pages/manager/detailaccountmanager.dart';
import 'package:fe/pages/manager/newaccountmanager.dart';

class ManageAccmanager extends StatefulWidget {
  const ManageAccmanager({Key? key}) : super(key: key);
  static String routeName = "/account_manager";

  @override
  _ManageAccmanagerState createState() => _ManageAccmanagerState();
}

class _ManageAccmanagerState extends State<ManageAccmanager> {
  late Future<List<Map<String, dynamic>>> _accountsFuture;
  List<Map<String, dynamic>> _allAccounts = [];
  List<Map<String, dynamic>> _filteredAccounts = [];
  Map<String, bool> _faceStatusMap = {};
  TextEditingController _searchController = TextEditingController();
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _accountsFuture = fetchAccounts();
    _searchController.addListener(_filterAccounts);
  }

  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    final url = Uri.parse('http://10.0.2.2:8081/getAllInforAcc');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Status'] == 'Success') {
          _allAccounts = List<Map<String, dynamic>>.from(data['accountsInfo']);
          _filteredAccounts = _allAccounts;
          await _checkFaceStatus();
          return _allAccounts;
        } else {
          throw Exception('Failed to load accounts');
        }
      } else {
        throw Exception('Failed to connect to API');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<void> _checkFaceStatus() async {
    for (var account in _allAccounts) {
      String memberId = account['id'].toString();
      final url = Uri.parse('http://10.0.2.2:8081/getImageByID/$memberId');

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          setState(() {
            _faceStatusMap[memberId] = true;
          });
        } else {
          setState(() {
            _faceStatusMap[memberId] = false;
          });
        }
      } catch (e) {
        setState(() {
          _faceStatusMap[memberId] = false;
        });
      }
    }
  }

  void _filterAccounts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAccounts = _allAccounts.where((account) {
        final matchesSearch = account['username']
            .toLowerCase()
            .contains(query) ||
            (account['member_name']?.toLowerCase() ?? '').contains(query);
        final matchesRole = _selectedRole == null ||
            account['role'].toLowerCase() == _selectedRole!.toLowerCase();
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _showAccountDetailsPopup(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Account Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: ${account['username']}'),
                Text('Member Name: ${account['member_name'] ?? 'N/A'}'),
                Text('Role: ${account['role']}'),
                Text('Status: ${account['status']}'),
                Text('Email: ${account['email']}'),
                Text('Phone: ${account['phone'] ?? 'N/A'}'),
                Text('Address: ${account['address'] ?? 'N/A'}'),
                Text(
                    'Registered Face: ${_faceStatusMap[account['id'].toString()] == true ? 'Yes' : 'No'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            if (account['role'] != 'admin') // Check if the role is not admin
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailAccountmanager(
                        accountDetails: {
                          'id': account['id'],
                          'username': account['username'],
                          'member_name': account['member_name'],
                          'role': account['role'],
                          'status': account['status'],
                          'email': account['email'],
                          'phone': account['phone'],
                          'address': account['address'],
                          'registeredFace':
                          _faceStatusMap[account['id'].toString()],
                        },
                      ),
                    ),
                  );
                },
                child: Text('Detail'),
              ),
          ],
        );
      },
    );
  }


  Widget _buildFaceStatusBadge(bool isRegistered) {
    if (isRegistered) return SizedBox.shrink();

    return Positioned(
      top: 5,
      right: 5,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Account not registered face',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Accounts'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'List of Accounts',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewAccmanager(),
                      ),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('New Account'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(width: 10.0),
                DropdownButton<String>(
                  value: _selectedRole,
                  hint: Text('Filter by role'),
                  items: ['Admin', 'Staff', 'Manager']
                      .map(
                        (role) => DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                    _filterAccounts();
                  },
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _accountsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (_filteredAccounts.isEmpty) {
                    return Center(
                      child: Text('No accounts found'),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: _filteredAccounts.length,
                      itemBuilder: (context, index) {
                        final account = _filteredAccounts[index];
                        final isRegistered =
                            _faceStatusMap[account['id'].toString()] ?? false;

                        return Card(
                          color: isRegistered
                              ? Colors.green[100]
                              : Colors.red[100],
                          margin: EdgeInsets.symmetric(vertical: 10.0),
                          child: Stack(
                            children: [
                              ListTile(
                                title: Text(account['username']),
                                subtitle: Text(
                                  'Role: ${account['role']}\nStatus: ${account['status']}\nEmail: ${account['email']}',
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: Icon(Icons.visibility),
                                  onPressed: () {
                                    _showAccountDetailsPopup(account);
                                  },
                                ),
                              ),
                              _buildFaceStatusBadge(isRegistered),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AccountDetailPage extends StatelessWidget {
  final String accountId;
  final String memberId;

  const AccountDetailPage({
    Key? key,
    required this.accountId,
    required this.memberId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'List of Accounts',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewAccmanager(),
                      ),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('New Account'),
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Text('Account ID: $accountId'),
            SizedBox(height: 10.0),
            Text('Member ID: $memberId'),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
