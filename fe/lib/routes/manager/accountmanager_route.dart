import 'package:flutter/widgets.dart';
import '../../components/bottom_navigator/bottom_navigator_wrapper_manager.dart';
final Map<String, WidgetBuilder> accountRoutesmanager = {
  '/account_manager': (context) => BottomNavigationBarWrapper(selectedIndex: 2, onItemTapped: (index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home_manager');
        break;
      case 1:
        Navigator.pushNamed(context, '/history_manager');
        break;
      case 2:
        Navigator.pushNamed(context, '/account_manager');
        break;
      case 3:
        Navigator.pushNamed(context, '/viewprofile_manager');
        break;
    }
  }),
};