import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Historystaff extends StatefulWidget {
  const Historystaff({Key? key}) : super(key: key);
  static String routeName = "/history_staff";

  @override
  _HistorystaffScreenState createState() => _HistorystaffScreenState();
}

class _HistorystaffScreenState extends State<Historystaff> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final _storage = const FlutterSecureStorage(); // Secure storage instance

  List<Map<String, String>> _historyData = [];
  List<Map<String, String>> _filteredHistoryData = [];
  bool _isLoading = true;
  String? _errorMessage;
  TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  String _getUpdatedImageUrl(String imageUrl) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return imageUrl.replaceAll('http://localhost:8081', '$apiBaseUrl');
    }
    return imageUrl;
  }

  String _formatDateTime(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime).toLocal();
      return "${parsedDate.day.toString().padLeft(2, '0')}/"
          "${parsedDate.month.toString().padLeft(2, '0')}/"
          "${parsedDate.year} "
          "${parsedDate.hour.toString().padLeft(2, '0')}:"
          "${parsedDate.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTime;
    }
  }

  Future<void> _fetchHistoryData() async {
    final String getAccountApi = "$apiBaseUrl/getAccountById/";
    final String getHistoriesApi = "$apiBaseUrl/getHistoriesByMemberId/";

    try {
      // Fetch username from secure storage
      final username = await _storage.read(key: "KEY_USERNAME") ?? '';
      print("Fetched username: $username");

      if (username.isEmpty) {
        setState(() {
          _errorMessage = 'Username not found in storage.';
          _isLoading = false;
        });
        return;
      }

      // Get Member ID using username
      final accountResponse = await http.get(Uri.parse('$getAccountApi$username'));
      print("Account API Response: ${accountResponse.body}");

      if (accountResponse.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to fetch account information.';
          _isLoading = false;
        });
        return;
      }

      final accountData = jsonDecode(accountResponse.body);
      final String memberId = accountData['accountInfo']['id'].toString();
      print("Fetched Member ID: $memberId");

      // Get history by Member ID
      final historyResponse = await http.get(Uri.parse('$getHistoriesApi$memberId'));
      print("History API Response: ${historyResponse.body}");

      if (historyResponse.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to fetch history records.';
          _isLoading = false;
        });
        return;
      }

      final List<dynamic> data = jsonDecode(historyResponse.body)['data'];
      print("History Data: $data");

      if (data.isNotEmpty) {
        List<Map<String, String>> historyData = [];
        for (var item in data) {
          final String? faceImageUrl = item['face_image'];
          final String? historyId = item['id']?.toString();
          final String? enterAt = item['enter_at'];
          final String? name = item['name'];

          // Check null values and provide fallback values
          historyData.add({
            'id': historyId ?? '',  // Provide empty string if null
            'account_id': memberId,
            'name': name ?? '',  // Provide empty string if null
            'enter_at': _formatDateTime(enterAt ?? ''),  // Provide empty string if null
            'url': _getUpdatedImageUrl(faceImageUrl ?? ''),  // Provide empty string if null
          });
        }

        setState(() {
          _historyData = historyData;
          _filteredHistoryData = historyData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No history records found for this member.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching history data: $e';
        _isLoading = false;
      });
      print("Unexpected error: $e");
    }
  }


  void _applyFilters() {
    String searchQuery = _searchController.text.trim().toLowerCase();
    DateTime? startDate = _selectedDateRange?.start;
    DateTime? endDate = _selectedDateRange?.end;
    DateFormat customFormat = DateFormat("dd/MM/yyyy HH:mm");

    setState(() {
      _filteredHistoryData = _historyData.where((record) {
        bool matchesAccountId = searchQuery.isEmpty ||
            record['account_id']!.toLowerCase().contains(searchQuery);
        bool matchesDate = true;

        if (startDate != null && endDate != null) {
          try {
            DateTime enterAtDate = customFormat.parse(record['enter_at']!);
            matchesDate = enterAtDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                enterAtDate.isBefore(endDate.add(Duration(days: 1)));
          } catch (e) {
            matchesDate = false;
          }
        }

        return matchesAccountId && matchesDate;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [

                ElevatedButton.icon(
                  onPressed: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateRange = picked;
                      });
                      _applyFilters();
                    }
                  },
                  icon: Icon(Icons.date_range),
                  label: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: _filteredHistoryData.length,
                itemBuilder: (context, index) {
                  final data = _filteredHistoryData[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Name: ${data['name']}',  // Corrected from 'Name' to 'name'
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Enter At: ${data['enter_at']}'),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      child: Image.network(
                                        data['url']!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.broken_image,
                                            size: 200,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data['url']!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
