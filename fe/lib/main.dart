import 'package:flutter/material.dart';
import 'package:fe/routes/routes.dart';
import './pages/login.dart'; // Import your login screen here
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io'; // For debugging the file path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debugging: Print the current directory
  print('Current Directory: ${Directory.current.path}');

  try {
    await dotenv.load(fileName: '.env'); // Ensure this matches your file name
    print('Environment variables loaded successfully.');
  } catch (e) {
    print('Error loading .env file: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Corrected constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set this to false
      title: 'Your App',
      theme: ThemeData(
        primaryColor: const Color(0xFF2661FA),
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: Login.routeName,
      routes: routes,
    );
  }
}
