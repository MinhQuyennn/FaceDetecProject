import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Historystaff extends StatefulWidget {
  const Historystaff({Key? key}) : super(key: key);

  static String routeName = "/history_staff";

  @override
  _HistorystaffScreenState createState() => _HistorystaffScreenState();
}

class _HistorystaffScreenState extends State<Historystaff> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

  final _storage = const FlutterSecureStorage();
  List<Map<String, String>> _historyData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  String _getUpdatedImageUrl(String imageUrl) {
    if (imageUrl.contains('localhost')) {
      return imageUrl.replaceAll('localhost', '10.0.2.2');
    }
    return imageUrl;
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
        print("Error: Username is empty");
        return;
      }

      // Get Member ID using username
      final accountResponse = await http.get(Uri.parse('$getAccountApi$username'));
      print("Account API response status: ${accountResponse.statusCode}");
      print("Account API response body: ${accountResponse.body}");

      if (accountResponse.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to fetch account information.';
          _isLoading = false;
        });
        return;
      }

      final accountData = jsonDecode(accountResponse.body);
      final String memberId = accountData['accountInfo']['id'].toString();
      print("Fetched member ID: $memberId");

      // Get history by Member ID
      final historyResponse = await http.get(Uri.parse('$getHistoriesApi$memberId'));
      print("History API response status: ${historyResponse.statusCode}");
      print("History API response body: ${historyResponse.body}");

      if (historyResponse.statusCode != 200) {
        setState(() {
          _errorMessage = 'No history records.';
          _isLoading = false;
        });
        return;
      }

      final List<dynamic> data = jsonDecode(historyResponse.body)['data'];
      print("Fetched history data: $data");

      if (data.isNotEmpty) {
        List<Map<String, String>> historyData = [];
        for (var item in data) {
          final String? faceImageUrl = item['face_image'];
          final String? historyId = item['id']?.toString();
          final String? memberId = item['member_id']?.toString();
          final String? enterAt = item['enter_at'];

          if (faceImageUrl != null && historyId != null && memberId != null && enterAt != null) {
            historyData.add({
              'id': historyId,
              'account_id': memberId, // Use member_id for account_id
              'enter_at': enterAt,
              'url': _getUpdatedImageUrl(faceImageUrl),
            });
          }
        }

        setState(() {
          _historyData = historyData;
          _isLoading = false;
        });
        print("Successfully set history data.");
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 20.0),
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
                                print("Image loading error: $error");
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
            print("Full image loading error: $error");
            return const Icon(Icons.broken_image, size: 100);
          },
        ),
      ),
    );
  }
}
