import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart'; // Import intl package

class HomepageAd extends StatefulWidget {
  const HomepageAd({Key? key}) : super(key: key);
  static String routeName = "/home_admin";

  @override
  _HomepageAdState createState() => _HomepageAdState();
}

class _HomepageAdState extends State<HomepageAd> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final _storage = const FlutterSecureStorage();

  String _memberName = 'Admin';
  String _username = '';
  int _registeredCount = 0;
  int _notRegisteredCount = 0;
  String _lastEnterAt = 'N/A';
  String _lastAccountId = 'N/A';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchUserDetails();
    await _fetchFaceRegistrationStats();
    await _fetchHistoryData();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final username = await _storage.read(key: "KEY_USERNAME") ?? '';
      if (username.isEmpty) return;

      setState(() => _username = username);

      final response = await http.get(
        Uri.parse('$apiBaseUrl/getAccountById/$username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _memberName = data['accountInfo']['member_name'] ?? 'Admin';
        });
      } else {
        debugPrint('Failed to fetch user details: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error fetching user details: $error');
    }
  }

  Future<void> _fetchFaceRegistrationStats() async {
    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/getFaceRegistrationStats"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _registeredCount = data['data']['registeredCount'] ?? 0;
          _notRegisteredCount = data['data']['notRegisteredCount'] ?? 0;
        });
      } else {
        debugPrint('Failed to fetch stats: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error fetching stats: $error');
    }
  }

  Future<void> _fetchHistoryData() async {
    final String apiUrl = "$apiBaseUrl/getAllHistories";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'].isNotEmpty) {
          final lastEntry = data['data'].last;

          // Parse and format the date
          String formattedDate = 'N/A';
          if (lastEntry['enter_at'] != null) {
            DateTime parsedDate = DateTime.parse(lastEntry['enter_at']);
            formattedDate = DateFormat('dd/MM/yy HH:mm:ss').format(parsedDate);
          }

          setState(() {
            _lastEnterAt = formattedDate;
            _lastAccountId = lastEntry['account_id'] ?? 'N/A';
          });

          // Debugging information
          debugPrint('Formatted Date: $formattedDate');
          debugPrint('Last Account ID: $_lastAccountId');
        } else {
          debugPrint('No history records found.');
          setState(() {
            _lastEnterAt = 'No data';
            _lastAccountId = 'No data';
          });
        }
      } else {
        debugPrint('Failed to fetch history data: ${response.body}');
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
                      'Hello, \nAdmin $_memberName',
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
            startColor: const Color.fromRGBO(251, 121, 155, 1),
            endColor: const Color.fromRGBO(251, 53, 105, 1),
            title: _buildRichText('$_registeredCount\n', 'accounts registered face'),
          ),
          _buildCard(
            startColor: const Color.fromRGBO(122, 241, 250, 1.0),
            endColor: const Color.fromRGBO(15, 228, 241, 1.0),
            title: _buildRichText('$_notRegisteredCount\n', 'accounts not registered face'),
          ),
          _buildCard(
            startColor: const Color.fromRGBO(255, 204, 128, 1.0),
            endColor: const Color.fromRGBO(255, 152, 0, 1.0),
            title: _buildRichText(
              '$_lastAccountId\n',
              'Last detected: $_lastEnterAt',
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

