import 'package:flutter/material.dart';
import 'package:fe/pages/admin/newaccountadmin.dart';

class ManageAccAdmin extends StatefulWidget {
  const ManageAccAdmin({Key? key}) : super(key: key);
  static String routeName = "/account_admin";

  @override
  _ManageAccAdminState createState() => _ManageAccAdminState();
}

class _ManageAccAdminState extends State<ManageAccAdmin> {
  late List<Map<String, dynamic>> _meetings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Accounts'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Histories',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewAccAdmin()),
                );
              },
              child: Text('New Account'),
            ),
          ],
        ),
      ),
    );
  }
}
