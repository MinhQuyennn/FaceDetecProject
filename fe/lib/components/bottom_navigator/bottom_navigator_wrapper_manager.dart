import 'package:flutter/material.dart';
import 'package:fe/pages/manager/manageaccountmanager.dart';
import '../../pages/manager/homemanager.dart';
import '../../pages/manager/historymanager.dart';
import 'package:fe/constants/colors.dart';
import '../../pages/manager/profilemanager.dart';
class BottomNavigationBarWrapper extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemTapped; // Explicitly specify the type

  const BottomNavigationBarWrapper({
    Key? key, // Add Key? here
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key); // Use super(key: key) here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: CustomColor.bluePrimary,
        unselectedItemColor: Theme.of(context).iconTheme.color, // Use default color of device
        onTap: onItemTapped,
        items: const [
          BottomNavigationBarItem(
            label: 'Home',
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            label: 'Histories',
            icon: Icon(Icons.list_alt),
          ),
          BottomNavigationBarItem(
            label: 'Accounts',
            icon: Icon(Icons.supervised_user_circle),
          ),
          BottomNavigationBarItem(
            label: 'Profile',
            icon: Icon(Icons.person),
          ),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const HomepageManager();
      case 1:
        return const Historymanager();
      case 2:
        return const ManageAccmanager();
      case 3:
        return const viewProfileManager();
      default:
        return Container();
    }
  }
}