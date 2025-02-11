import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart'; // Import intl package

class Homepagestaff extends StatefulWidget {
  const Homepagestaff({Key? key}) : super(key: key);
  static String routeName = "/home_staff";

  @override
  _HomepagestaffScreenState createState() => _HomepagestaffScreenState();
}

class _HomepagestaffScreenState extends State<Homepagestaff> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final _storage = const FlutterSecureStorage();

  String _memberName = 'Staff';
  String _username = '';
  String _lastAccountId = 'Please contact the manager to register your face.';
  String _mostRecentTime = 'No history';
  int _memberId = 0;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchUserDetails();
    await _fetchHistoryData();
  }

  Future<void> _fetchUserDetails() async {
    try {
      // Fetch username from storage
      final username = await _storage.read(key: "KEY_USERNAME") ?? '';
      if (username.isEmpty) return;

      setState(() => _username = username);
      print(username);
      // Fetch account details
      final accountResponse = await http.get(
        Uri.parse('$apiBaseUrl/getAccountById/$username'),
      );

      if (accountResponse.statusCode == 200) {
        final data = json.decode(accountResponse.body);
        setState(() {
          _memberName = data['accountInfo']['member_name'] ?? 'Staff';
          _memberId = data['accountInfo']['id'] ?? 0; // Save member_id as an integer
        });
      } else {
        debugPrint('Failed to fetch user details: ${accountResponse.body}');
      }

      // Fetch face registration status
      final faceResponse = await http.get(
        Uri.parse('$apiBaseUrl/getAllDataWithUsername'),
      );

      if (faceResponse.statusCode == 200) {
        final data = json.decode(faceResponse.body);
        print('Face data response: $data'); // Debugging the structure of data

        // Check if the response data is a list and filter for the user data
        if (data is List) {
          final userFaceData = data.firstWhere(
                (item) => item['username'] == _username,
            orElse: () => null,
          );

          setState(() {
            // Check if face registration exists
            if (userFaceData != null && userFaceData['face_image_url'] != null) {
              _lastAccountId = 'You have registered your face in the system.';
            } else {
              print('User face data: $userFaceData');
              _lastAccountId =
              'Please contact the manager to register your face.';
            }
          });
        } else {
          debugPrint('Unexpected data format: Not a list');
        }
      } else {
        debugPrint('Failed to fetch face registration details: ${faceResponse.body}');
      }
    } catch (error) {
      debugPrint('Error fetching user details: $error');
    }
  }



  Future<void> _fetchHistoryData() async {
    try {
      if (_memberId == 0) return; // Use member_id as an integer
      print(_memberId);
      // Fetch history by member_id
      final response = await http.get(
        Uri.parse('$apiBaseUrl/getHistoriesByMemberId/$_memberId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        if (data['data'] != null && data['data'].isNotEmpty) {
          // Use 'enter_at' instead of 'timestamp'
          final mostRecent = data['data'][0]['enter_at'];
          final formattedTime = DateFormat('d/MM/yyyy HH:mm').format(
            DateTime.parse(mostRecent).toLocal(),
          );

          setState(() {
            _mostRecentTime = 'Most recent time: $formattedTime';
          });
        } else {
          setState(() {
            _mostRecentTime = 'No history available.';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _mostRecentTime = 'No history.';
        });
      } else {
        debugPrint('Failed to fetch history: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error fetching history data: $error');
    }
  }









  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(25),
              child: FadeInUp(
                duration: const Duration(milliseconds: 1200),
                child: const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color.fromRGBO(97, 90, 90, 1),
                  ),
                ),
              ),
            ),
            _buildStatsCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        height: 280,
        width: double.infinity,
        padding: const EdgeInsets.only(left: 25, right: 25, top: 60),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(50.0),
            bottomLeft: Radius.circular(50.0),
          ),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            colors: [
              Color.fromRGBO(182, 233, 255, 1.0),
              Color.fromRGBO(78, 128, 255, 1.0),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 4,
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 1200),
                    child: Text(
                      'Hello, \nStaff $_memberName',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(250, 250, 250, 1),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 1300),
                    child: Image.asset('assets/images/home.png'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 200,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            SizedBox(width: 15),
            _buildCard("Status", _lastAccountId, Colors.blueAccent),
            SizedBox(width: 15),
            _buildCard("Lastest Entrance", _mostRecentTime, Colors.greenAccent),
            SizedBox(width: 15),

          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String content, Color color) {
    return Container(
      width: 220,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 200,
            height: 140,
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }





}

