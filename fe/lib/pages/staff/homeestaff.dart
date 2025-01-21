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
                  'Your Dashboard',
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
    return Container(
      height: 220,
      width: double.infinity,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20, left: 20),
        scrollDirection: Axis.horizontal,
        children: [
          _buildCard(
            startColor: const Color.fromRGBO(255, 0, 59, 1.0),
            endColor: const Color.fromRGBO(235, 135, 135, 1.0),
            title: Text(
              _lastAccountId,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildCard(
            startColor: const Color.fromRGBO(30, 91, 250, 1.0),
            endColor: const Color.fromRGBO(136, 176, 250, 1.0),
            title: Text(
              _mostRecentTime,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRichText(String accountId, String lastDetected) {
    final parts = lastDetected.split(': '); // Split the string to separate label and date
    final label = parts.first; // 'Last detected'
    final date = parts.length > 1 ? parts.last : ''; // 'dd/MM/yy HH:mm:ss'

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: accountId,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          TextSpan(
            text: date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold, // Bold style for the date
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Color startColor,
    required Color endColor,
    required Widget title,
  }) {
    return GestureDetector(
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              colors: [startColor, endColor],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 10,
                offset: const Offset(5, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title],
            ),
          ),
        ),
      ),
    );
  }
}

