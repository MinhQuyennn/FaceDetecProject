import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fe/pages/admin/detailaccountadmin.dart';
import 'package:fe/pages/admin/newaccountadmin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ManageAccAdmin extends StatefulWidget {
  const ManageAccAdmin({Key? key}) : super(key: key);
  static String routeName = "/account_admin";

  @override
  _ManageAccAdminState createState() => _ManageAccAdminState();
}

class _ManageAccAdminState extends State<ManageAccAdmin> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

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
    final url = Uri.parse('$apiBaseUrl/getAllInforAcc');
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
      final url = Uri.parse('$apiBaseUrl/getImageByID/$memberId');

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
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewAccAdmin(),
                      ),
                    );
                  },
                  child:Icon(Icons.person_add),
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
                          color: Colors.white,
                          margin: EdgeInsets.symmetric(vertical: 10.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailAccountAdmin(
                                    accountDetails: {
                                      'id': account['id'],
                                      'username': account['username'],
                                      'member_name': account['member_name'],
                                      'role': account['role'],
                                      'status': account['status'],
                                      'email': account['email'],
                                      'phone': account['phone'],
                                      'address': account['address'],
                                      'registeredFace': _faceStatusMap[account['id'].toString()],
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                ListTile(
                                  title: Text(account['username']),
                                  subtitle: Text(
                                    'Name:${account['member_name']}\nRole: ${account['role']}\nEmail: ${account['email']}',
                                  ),
                                  isThreeLine: true,
                                ),
                                _buildFaceStatusBadge(isRegistered),
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: Icon(
                                    account['status'] == 'able'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: account['status'] == 'able'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
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
