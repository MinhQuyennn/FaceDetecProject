import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

class FetchFaceImagesPage extends StatefulWidget {
  final String memberId;

  const FetchFaceImagesPage({Key? key, required this.memberId}) : super(key: key);

  @override
  _FetchFaceImagesPageState createState() => _FetchFaceImagesPageState();
}

class _FetchFaceImagesPageState extends State<FetchFaceImagesPage> {
  List<Map<String, String>> _faceImageData = []; // Store both id and image URL
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchFaceData(widget.memberId);

    // Set up periodic refresh every 10 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchFaceData(widget.memberId);
    });
  }

  String _getUpdatedImageUrl(String imageUrl) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return imageUrl.replaceAll('localhost', '10.0.2.2');
    }
    return imageUrl;
  }

  Future<void> _fetchFaceData(String memberId) async {
    final url = Uri.parse('http://10.0.2.2:8081/getImageByID/$memberId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          List<Map<String, String>> faceImageData = [];
          for (var item in data) {
            final String? faceImageUrl = item['face_image_url'];
            final String? imageId = item['id'].toString();
            if (faceImageUrl != null && imageId != null) {
              faceImageData.add({
                'id': imageId,
                'url': _getUpdatedImageUrl(faceImageUrl),
              });
            }
          }

          setState(() {
            _faceImageData = faceImageData;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No valid data found for this member.';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'No face data found for this account.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch face data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching face data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Face Images',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            )
                : _faceImageData.isNotEmpty
                ? Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _faceImageData.map((data) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FullImagePage(
                                        imageUrl: data['url']!,
                                        imageId: data['id']!),
                              ),
                            );
                          },
                          child: Image.network(
                            data['url']!,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (context, child, loadingProgress) {
                              if (loadingProgress == null)
                                return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress
                                      .expectedTotalBytes !=
                                      null
                                      ? loadingProgress
                                      .cumulativeBytesLoaded /
                                      loadingProgress
                                          .expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) {
                              return Text(
                                'Error loading image: $error',
                                style: TextStyle(color: Colors.red),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 10.0),
                      ],
                    );
                  }).toList(),
                ),
              ),
            )
                : Text(
              'No face images available.',
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
  final String imageId;

  const FullImagePage({Key? key, required this.imageUrl, required this.imageId})
      : super(key: key);

  Future<void> _deleteImage(BuildContext context, String imageId) async {
    try {
      final url = Uri.parse('http://10.0.2.2:8081/delete-face/$imageId');

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image deleted successfully')),
        );
        Navigator.pop(context); // Go back to the previous page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete the image')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Image'),
        content: Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteImage(context, imageId);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Print the imageId for debugging
    print("Image ID: $imageId");

    return Scaffold(
      appBar: AppBar(
        title: Text('Full Image'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _confirmDelete(context),
              child: Text('Delete Image'),
            ),
          ),
        ],
      ),
    );
  }
}


