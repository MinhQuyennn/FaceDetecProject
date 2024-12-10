import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryAdmin extends StatefulWidget {
  const HistoryAdmin({Key? key}) : super(key: key);
  static String routeName = "/history_admin";

  @override
  _HistoryAdminState createState() => _HistoryAdminState();
}

class _HistoryAdminState extends State<HistoryAdmin> {
  late List<Map<String, dynamic>> _meetings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Histories'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Hi Huyen',
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