import 'package:flutter/widgets.dart';
import 'package:fe/pages/login.dart';

import 'package:fe/routes/admin/accountadmin_route.dart';
import 'package:fe/routes/admin/historyadmin_route.dart';
import 'package:fe/routes/admin/homeadmin_route.dart';
import 'package:fe/routes/admin/profileadmin_router.dart';
import 'package:fe/routes/staff/historystaff_route.dart';
import 'package:fe/routes/staff/homestaff_route.dart';
import 'package:fe/routes/staff/profilestaff_router.dart';



// All our routes will be available here
final Map<String, WidgetBuilder> routes = {
  ...homeRoutesstaff,
  ...homeRoutesAdmin,
  ...historyRoutesAdmin,
  ...accountRoutesAdmin,
  ...profileRoutesAdmin,
  ...profileRoutesstaff,
  ...historyRoutesstaff,
  Login.routeName: (context) =>   const Login(),
};
