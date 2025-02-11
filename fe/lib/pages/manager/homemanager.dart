import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import for chart visualization

class HomepageManager extends StatefulWidget {
  const HomepageManager({Key? key}) : super(key: key);
  static String routeName = "/home_manager";

  @override
  _HomepageManagerState createState() => _HomepageManagerState();
}

class _HomepageManagerState extends State<HomepageManager> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final _storage = const FlutterSecureStorage();

  String _memberName = 'Manager';
  String _username = '';
  String _lastEnterAt = 'N/A';
  String _lastAccountId = 'N/A';
  int _totalEntries = 0;
  int _totalImporters = 0;

  int _totalAccounts = 0;
  int _enabledAccounts = 0;
  int _registeredFaceAccounts = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _chartData = [];
  int _selectedDays = 3;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchStatistics();
    _fetchStatistics1();
    _fetchHistoryData1(days: _selectedDays); // Fetch initial data
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchUserDetails(),
      _fetchHistoryData1(),
      _fetchHistoryData()
    ]);
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
            DateTime parsedDate = DateTime.parse(lastEntry['enter_at']).toLocal();
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

  Future<void> _fetchUserDetails() async {
    try {
      final username = await _storage.read(key: "KEY_USERNAME") ?? '';
      if (username.isEmpty) return;

      setState(() => _username = username);

      final response = await http.get(Uri.parse('$apiBaseUrl/getAccountById/$username'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _memberName = data['accountInfo']['member_name'] ?? 'Manager';
        });
      } else {
        debugPrint('Failed to fetch user details: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error fetching user details: $error');
    }
  }

  Future<void> _fetchStatistics() async {
    final apiUrl = "$apiBaseUrl/AccStatistics";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _totalAccounts = data['totalAccounts'] ?? 0;
          _enabledAccounts = data['enabledAccounts'] ?? 0;
          _registeredFaceAccounts = data['registeredFaceAccounts'] ?? 0;
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch statistics: ${response.body}');
        throw Exception('Failed to fetch account statistics');
      }
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStatistics1() async {
    final apiUrl = "$apiBaseUrl/HisStatistics";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _totalEntries = data['totalEntries'] ?? 0;
          _totalImporters = data['totalImporters'] ?? 0;
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch statistics: ${response.body}');
        throw Exception('Failed to fetch account statistics');
      }
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _fetchHistoryData1({int days = 3}) async {
    final apiUrl = "$apiBaseUrl/getAllHistories";
    print('Fetching history data from $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Data fetched successfully: $data');

        if (data['data'] != null && data['data'].isNotEmpty) {
          final List<dynamic> historyData = data['data'];
          print('History data: $historyData');

          // Group data by date and count accesses
          final Map<String, int> dateAccessCounts = {};
          final DateTime now = DateTime.now();
          final DateTime startDate = now.subtract(Duration(days: days));
          print('Start Date: $startDate'); // Check calculated start date

          for (var entry in historyData) {
            final DateTime enterAt = DateTime.parse(entry['enter_at']).toLocal();
            print('Entry Date: $enterAt'); // Check each entry's date

            // Ensure that the date entry falls within the date range (startDate to now)
            if (enterAt.isAfter(startDate) && enterAt.isBefore(now)) {
              final String dateKey = DateFormat('yyyy-MM-dd').format(enterAt);
              dateAccessCounts[dateKey] = (dateAccessCounts[dateKey] ?? 0) + 1;
              print('Date Access Count: $dateKey -> ${dateAccessCounts[dateKey]}');
            }
          }

          // Verify that the data is not empty before updating the UI
          if (dateAccessCounts.isNotEmpty) {
            setState(() {
              _chartData = dateAccessCounts.entries
                  .map((entry) => {'date': entry.key, 'count': entry.value})
                  .toList();
              debugPrint("Chart Data After SetState: $_chartData");  // Check the data after setState
            });
          } else {
            debugPrint('No data to display on chart.');
            setState(() {
              _chartData = [];
            });
          }
        } else {
          debugPrint('No history records found.');
          setState(() {
            _chartData = [];
          });
        }
      } else {
        debugPrint('Failed to fetch history data: ${response.body}');
      }
    } catch (error) {
      print('Error fetching history data: $error');
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
            _buildFilterDropdown(),
            _buildAccessChart(),
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
                      'Hello, \nManager $_memberName',
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
            _buildCard("Account", "Total: $_totalAccounts\nEnable: $_enabledAccounts\nRegistered: $_registeredFaceAccounts", Colors.blueAccent),
            SizedBox(width: 15),
            _buildCard("Entrance", "Total: $_totalEntries\nAnonymous: $_totalImporters", Colors.greenAccent),
            SizedBox(width: 15),
            _buildCard("Lastest Entrance", "$_lastAccountId\nLast detected: $_lastEnterAt", Colors.orangeAccent),
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
            width: 210,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Select Data Range:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          DropdownButton<int>(
            value: _selectedDays,
            underline: Container(),
            items: [3, 7, 10, 14]
                .map(
                  (days) => DropdownMenuItem<int>(
                value: days,
                child: Text('$days Days'),
              ),
            )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDays = value ?? 3;
                _fetchHistoryData1(days: _selectedDays);
              });
            },
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessChart() {
    if (_chartData.isEmpty) {
      debugPrint("Chart Data: $_chartData");
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: const Text(
          "No data to display",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        height: 300, // Adjust height for better display
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: _chartData.map((data) {
              final DateTime date = DateTime.parse(data['date']);
              return BarChartGroupData(
                x: date.day,
                barRods: [
                  BarChartRodData(
                    toY: data['count'].toDouble(),
                    color: Colors.blueAccent,
                    width: 15,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    try {
                      final matchedDate = _chartData.firstWhere(
                            (data) => DateTime.parse(data['date']).day == value,
                      );
                      return Text(
                        DateFormat('dd/MM').format(DateTime.parse(matchedDate['date'])),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      );
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true),
          ),
        ),
      ),
    );
  }

}




