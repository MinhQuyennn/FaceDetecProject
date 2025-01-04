import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


// Define AddImage as a StatefulWidget
class AddImage extends StatefulWidget {
  final String memberId;

  // Constructor to pass memberId
  AddImage({required this.memberId});

  @override
  _AddImageAdminState createState() => _AddImageAdminState();
}

// Define the corresponding state class for AddImage
class _AddImageAdminState extends State<AddImage> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

  final ImagePicker _picker = ImagePicker();
  String _base64Image = ''; // Initialize as an empty string to avoid LateInitializationError
  bool _isLoading = false;

  // Pick an image from the gallery or camera
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes); // Convert image to Base64
      });
    }
  }

  // Upload the image to the server
  Future<void> _uploadImage() async {
    if (_base64Image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse('$apiBaseUrl/register-face'), // Adjust API URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'base64Image': _base64Image,
        'member_id': widget.memberId, // Access the memberId from widget
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Image uploaded successfully!')),
      );

      // Reset the image after a successful upload
      setState(() {
        _base64Image = ''; // Reset the image to allow new image selection
      });

      // Optionally, navigate back after success
      // Navigator.pop(context);
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['message'] ?? 'Failed to upload image')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Image')),
      body: SingleChildScrollView( // Wrap the entire Column with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              if (_base64Image.isNotEmpty)
                Image.memory(base64Decode(_base64Image), width: 200, height: 200),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _uploadImage,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Upload Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
