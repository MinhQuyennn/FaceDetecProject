import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// Define InsertImage as a StatefulWidget
class InsertImage extends StatefulWidget {
  final String memberId;

  // Constructor to pass memberId
  InsertImage({required this.memberId});

  @override
  _InsertImageAdminState createState() => _InsertImageAdminState();
}

// Define the corresponding state class for InsertImage
class _InsertImageAdminState extends State<InsertImage> {
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
      Uri.parse('http://10.0.2.2:8081/register-face'), // Adjust API URL
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
