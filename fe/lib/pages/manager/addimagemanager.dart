import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fe/pages/manager/manageaccountmanager.dart';

class AddImage extends StatefulWidget {
  final String memberId;

  AddImage({required this.memberId});

  @override
  _AddImageAdminState createState() => _AddImageAdminState();
}

class _AddImageAdminState extends State<AddImage> {
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final ImagePicker _picker = ImagePicker();
  String _base64Image = '';
  bool _isLoading = false;
  bool _isUploaded = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
        _isUploaded = false; // Reset to allow re-uploading
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_base64Image.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse('$apiBaseUrl/register-face'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'base64Image': _base64Image,
        'member_id': widget.memberId,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Image uploaded successfully!')),
      );
      setState(() {
        _isUploaded = true;
        _base64Image = '';
      });
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['message'] ?? 'Failed to upload image')),
      );
    }
  }

  void _finishProcess() {
    if (!_isUploaded) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Warning'),
          content: Text(
              'You have not registered a face for this account yet. Do you want to return to the account management page?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageAccmanager()));
              },
              child: Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmation'),
          content: Text('Do you want to finish the face posting process?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageAccmanager(),
                  ),
                );
              },

              child: Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _base64Image = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Image')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, color: Colors.white, size: 17),
                    label: Text(
                      'Add face from gallery',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, color: Colors.white, size: 17),
                    label: Text(
                      'Add face from camera',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_base64Image.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          base64Decode(_base64Image),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _removeImage,
                        icon: Icon(Icons.delete, color: Colors.red),
                        label: Text(
                          'Remove Image',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              if (_base64Image.isNotEmpty && !_isUploaded)
                ElevatedButton(
                  onPressed: _isLoading ? null : _uploadImage,
                  child: _isLoading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 10),
                      Text('Uploading...'),
                    ],
                  )
                      : Text('Upload Face', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(400, 50),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              SizedBox(height: 20),

              if (!_isLoading)
                ElevatedButton(
                  onPressed: _finishProcess,
                  child: Text('Finish', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(400, 50),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

