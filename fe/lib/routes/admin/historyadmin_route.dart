import 'package:flutter/widgets.dart';
import '../../components/bottom_navigator/bottom_navigator_wrapper.dart';
final Map<String, WidgetBuilder> historyRoutesAdmin = {
  '/history_admin': (context) => BottomNavigationBarWrapper(selectedIndex: 1, onItemTapped: (index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home_admin');
        break;
      case 1:
        Navigator.pushNamed(context, '/history_admin');
        break;
      case 2:
        Navigator.pushNamed(context, '/account_admin');
        break;
      case 3:
        Navigator.pushNamed(context, '/viewprofile_admin');
        break;
    }
  }),
};