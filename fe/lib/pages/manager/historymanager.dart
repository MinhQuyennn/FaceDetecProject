import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class Historymanager extends StatefulWidget {
  const Historymanager({Key? key}) : super(key: key);
  static String routeName = "/history_manager";

  @override
  _HistorymanagerState createState() => _HistorymanagerState();
}

class _HistorymanagerState extends State<Historymanager> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

  List<Map<String, String>> _historyData = [];
  List<Map<String, String>> _filteredHistoryData = [];
  bool _isLoading = true;
  String? _errorMessage;
  TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  Timer? _timer;
  bool _isFetching = false;


  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
    _startAutoReload();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose(); // Dispose the controller as well
    super.dispose();
  }


  void _startAutoReload() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_isFetching) {
        _fetchHistoryData();
      }
    });
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
  Future<void> _deleteHistory(String historyId) async {
    final String deleteApiUrl = "$apiBaseUrl/deleteHistories/$historyId";

    try {
      final response = await http.delete(Uri.parse(deleteApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _historyData.removeWhere((data) => data['id'] == historyId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('History record deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete record: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting history: $e')),
      );
    }
  }
  Future<void> _fetchHistoryData() async {
    if (_isFetching) return; // Prevent overlapping fetches
    _isFetching = true;

    final String apiUrl = "$apiBaseUrl/getAllHistories";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];

        if (data.isNotEmpty) {
          List<Map<String, String>> historyData = [];
          for (var item in data) {
            final String? faceImageUrl = item['face_image'];
            final String? historyId = item['id'].toString();
            final String? accountId = item['account_id'];
            final String? enterAt = item['enter_at'];

            if (faceImageUrl != null && historyId != null && accountId != null && enterAt != null) {
              historyData.add({
                'id': historyId,
                'account_id': accountId,
                'enter_at': enterAt,
                'url': _getUpdatedImageUrl(faceImageUrl),
                'name': item['name'] ?? '', // Add name if available
              });
            }
          }

          historyData.sort((a, b) {
            DateTime dateA = DateTime.parse(a['enter_at']!);
            DateTime dateB = DateTime.parse(b['enter_at']!);
            return dateB.compareTo(dateA);
          });

          setState(() {
            _historyData = historyData.map((item) {
              item['enter_at'] = _formatDateTime(item['enter_at']!);
              return item;
            }).toList();

            // Reapply filters after fetching new data
            _applyFilters();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No valid history data found.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch history data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching history data: $e';
        _isLoading = false;
      });
    } finally {
      _isFetching = false; // Ensure this is set back to false
    }
  }



  void _applyFilters() {
    String searchQuery = _searchController.text.trim().toLowerCase();
    DateTime? startDate = _selectedDateRange?.start;
    DateTime? endDate = _selectedDateRange?.end;

    setState(() {
      _filteredHistoryData = _historyData.where((record) {
        bool matchesAccountIdOrName = searchQuery.isEmpty ||
            record['account_id']!.toLowerCase().contains(searchQuery) ||
            (record['name']?.toLowerCase().contains(searchQuery) ?? false);

        bool matchesDateTime = true;

        if (startDate != null && endDate != null) {
          try {
            DateTime enterAtDateTime = DateFormat("dd/MM/yyyy HH:mm").parse(record['enter_at']!);
            matchesDateTime = enterAtDateTime.isAfter(startDate) &&
                enterAtDateTime.isBefore(endDate);
          } catch (e) {
            matchesDateTime = false;
          }
        }

        return matchesAccountIdOrName && matchesDateTime;
      }).toList();
    });
  }

  Future<void> _pickDateTimeRange() async {
    // Pick Start Date
    final DateTime? pickedStartDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
      helpText: 'Select Start Date', // Title for the date picker
    );

    if (pickedStartDate == null) return;

    // Pick Start Time
    final TimeOfDay? pickedStartTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select Start Time', // Title for the time picker
    );

    if (pickedStartTime == null) return;

    // Combine Start Date and Time
    final DateTime startDateTime = DateTime(
      pickedStartDate.year,
      pickedStartDate.month,
      pickedStartDate.day,
      pickedStartTime.hour,
      pickedStartTime.minute,
    );

    // Pick End Date
    final DateTime? pickedEndDate = await showDatePicker(
      context: context,
      firstDate: pickedStartDate,
      lastDate: DateTime.now(),
      initialDate: pickedStartDate.add(const Duration(days: 1)),
      helpText: 'Select End Date', // Title for the date picker
    );

    if (pickedEndDate == null) return;

    // Pick End Time
    final TimeOfDay? pickedEndTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select End Time', // Title for the time picker
    );

    if (pickedEndTime == null) return;

    // Combine End Date and Time
    final DateTime endDateTime = DateTime(
      pickedEndDate.year,
      pickedEndDate.month,
      pickedEndDate.day,
      pickedEndTime.hour,
      pickedEndTime.minute,
    );

    // Validate the selected date-time range
    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() {
      _selectedDateRange = DateTimeRange(start: startDateTime, end: endDateTime);
    });

    _applyFilters();
  }



  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: InteractiveViewer(
            panEnabled: true,
            child: Image.network(
              imageUrl,
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
  }

  @override
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
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Account ID or Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickDateTimeRange,
                  icon: const Icon(Icons.date_range),
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
                                  'ID: ${data['account_id']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Name: ${data['name']}',
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
                              _showFullImageDialog(data['url']!);
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
