import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  static String routeName = "/history_employee";

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<History> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final scrollController = ScrollController();
  final List<GlobalKey> navbarKeys = List.generate(4, (index) => GlobalKey());

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: Center(
        child: Text(
          "Hello Employee",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
