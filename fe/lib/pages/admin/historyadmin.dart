import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class HistoryAdmin extends StatefulWidget {
  const HistoryAdmin({Key? key}) : super(key: key);
  static String routeName = "/history_admin";

  @override
  _HistoryAdminState createState() => _HistoryAdminState();
}

class _HistoryAdminState extends State<HistoryAdmin> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

  List<Map<String, String>> _historyData = [];
  bool _isLoading = true;
  String? _errorMessage;

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

  Future<void> _fetchHistoryData() async {
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
              });
            }
          }

          setState(() {
            _historyData = historyData;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No valid history data found.';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'No history records found.';
          _isLoading = false;
        });
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

  void _showDeleteConfirmationDialog(String historyId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Do you want to delete this history record?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteHistory(historyId); // Call the delete method
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Histories'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'History Records',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            )
                : _historyData.isNotEmpty
                ? Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _historyData.map((data) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left-hand side: Account ID, ID, and Enter At
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account ID: ${data['account_id']}',
                                style: const TextStyle(
                                    fontSize: 14.0, fontWeight: FontWeight.bold),
                              ),
                              Text('ID: ${data['id']}'),
                              Text('Enter At: ${data['enter_at']}'),
                              const SizedBox(height: 5.0),
                              ElevatedButton(
                                onPressed: () {
                                  _showDeleteConfirmationDialog(data['id']!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white, // Make the background transparent
                                  side: BorderSide(color: Colors.blue), // Blue border
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0), // Optional: rounded corners
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Slimmer padding
                                ),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.blue, // Blue text color
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20.0),

                            ],
                          ),
                        ),
                        const SizedBox(width: 20.0),
                        // Right-hand side: Image
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullImagePage(
                                  imageUrl: data['url']!,
                                  historyId: data['id']!,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              data['url']!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            )
                : const Text(
              'No history records available.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class FullImagePage extends StatelessWidget {
  final String imageUrl;
  final String historyId;

  const FullImagePage({Key? key, required this.imageUrl, required this.historyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Image - ID: $historyId'),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 100);
          },
        ),
      ),
    );
  }
}
