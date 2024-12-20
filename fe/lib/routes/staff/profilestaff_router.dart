import 'package:flutter/widgets.dart';
import '../../components/bottom_navigator/bottom_navigator_wrapper_staff.dart';
final Map<String, WidgetBuilder> profileRoutesstaff = {
  '/profile_staff': (context) => BottomNavigationBarWrapper(selectedIndex: 2, onItemTapped: (index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home_staff');
        break;
      case 1:
        Navigator.pushNamed(context, '/history_staff');
        break;
      case 2:
        Navigator.pushNamed(context, '/profile_staff');
        break;
    }
  }),
};