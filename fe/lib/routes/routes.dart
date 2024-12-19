import 'package:flutter/widgets.dart';
import 'package:fe/pages/login.dart';
import 'package:fe/pages/admin/homeadmin.dart';  // Import the Homepage widget
import 'package:fe/pages/employee/homeemployee.dart';  // Import the HomepageAd widget
import 'package:fe/pages/admin/historyadmin.dart';
import 'package:fe/pages/admin/manageaccountadmin.dart';
import 'package:fe/pages/admin/newaccountadmin.dart';
import 'package:fe/routes/accountadmin_route.dart';
import 'package:fe/routes/historyadmin_route.dart';
import 'package:fe/routes/homeadmin_route.dart';
import 'package:fe/routes/profileadmin_router.dart';




// All our routes will be available here
final Map<String, WidgetBuilder> routes = {
  ...homeRoutesAdmin,
  ...historyRoutesAdmin,
  ...accountRoutesAdmin,
  ...profileRoutesAdmin,
  Login.routeName: (context) =>   const Login(),
};
