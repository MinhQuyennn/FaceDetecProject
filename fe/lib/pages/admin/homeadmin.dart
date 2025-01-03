import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';

class HomepageAd extends StatefulWidget {
  const HomepageAd({Key? key}) : super(key: key);
  static String routeName = "/home_admin";

  @override
  _HomepageAdState createState() => _HomepageAdState();
}

class _HomepageAdState extends State<HomepageAd> {
  final _storage = const FlutterSecureStorage();
  String _memberName = ''; // Default name
  String _username = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      // Retrieve the username from secure storage using the correct key
      final username = await _storage.read(key: "KEY_USERNAME") ?? '';  // Use 'username' as the key

      // Debug: Print the retrieved username
      debugPrint('Retrieved username: $username');

      setState(() {
        _username = username;
      });

      // Proceed only if username exists
      if (username.isNotEmpty) {
        final response = await http.get(
          Uri.parse('http://10.0.2.2:8081/getAccountById/$username'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Debug: Print the API response
          debugPrint('API response: $data');

          // Update member name if available
          setState(() {
            _memberName = data['accountInfo']['member_name'] ?? 'Admin';
          });
        } else {
          // Handle non-200 status codes
          setState(() {
            _memberName = 'Admin';
          });
          debugPrint('Failed to fetch user details: ${response.body}');
        }
      }
    } catch (error) {
      // Handle exceptions during the API call or JSON decoding
      setState(() {
        _memberName = 'Admin';
      });
      debugPrint('Error fetching user details: $error');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            FadeInUp(duration: Duration(milliseconds: 1000), child: Container(
              height: 280,
              width: double.infinity,
              padding: EdgeInsets.only(left: 25, right: 25, top: 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(50.0),
                    bottomLeft: Radius.circular(50.0)
                ),
                gradient: LinearGradient(
                    begin: Alignment.topRight,
                    colors: [
                      Color.fromRGBO(182, 233, 255, 1.0),
                      Color.fromRGBO(78, 128, 255, 1.0)
                    ]
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: FadeInUp(duration: Duration(milliseconds: 1200),
                          child: Text('Hello, \nAdmin $_memberName', style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(250, 250, 250, 1)
                        )),),
                      ),
                      Expanded(
                        flex: 3,
                        child: FadeInUp(duration: Duration(milliseconds: 1300), child: Image.asset('assets/images/home.png')),
                      ),
                    ],
                  )
                ],
              ),
            )),
            Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      FadeInUp(duration: Duration(milliseconds: 1200), child: Text('Your Dashboard', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color.fromRGBO(97, 90, 90, 1)
                      )),),
                    ],
                  )
                ],
              ),
            ),
            Container(
              height: 280,
              width: double.infinity,
              child: ListView(
                padding: EdgeInsets.only(bottom: 20, left: 20),
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  FadeInUp(duration: Duration(milliseconds: 1300), child: makeCard(
                      context: context,
                      startColor: Color.fromRGBO(251, 121, 155, 1),
                      endColor: Color.fromRGBO(251, 53, 105, 1),
                      image: 'assets/socks-two.png'
                  )),
                  FadeInUp(duration: Duration(milliseconds: 1400), child: makeCard(
                      context: context,
                      startColor: Color.fromRGBO(203, 251, 255, 1),
                      endColor: Color.fromRGBO(81, 223, 234, 1),
                      image: 'assets/socks-two.png'
                  )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget makeCard({context, startColor, endColor, image}) {
    return GestureDetector(
      // onTap: () {
      //   Navigator.push(context, PageTransition(type: PageTransitionType.fade, child: ViewSocks()));
      // },
      child: AspectRatio(
        aspectRatio: 4/5,
        child: Container(
          margin: EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                colors: [
                  startColor,
                  endColor
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    offset: Offset(5, 10)
                )
              ]
          ),
          child: Padding(
            padding: EdgeInsets.all(50),
            child: Center(
              child: Image.asset(image),
            ),
          ),
        ),
      ),
    );
  }
}