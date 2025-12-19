import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/routes/router.dart';
import 'package:purchase_app/core/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with proper error handling
  try {
    await Hive.initFlutter();

    // Open the appData box with a try-catch block
    try {
      await Hive.openBox('appData');
      print('appData Hive box opened successfully');
    } catch (e) {
      print('Error opening appData Hive box: $e');
      // Try to delete and recreate the box if there's an error
      await Hive.deleteBoxFromDisk('appData');
      await Hive.openBox('appData');
      print('appData Hive box recreated after deletion');
    }

    // Open the orders box with a try-catch block
    try {
      await Hive.openBox('orders');
      print('orders Hive box opened successfully');
    } catch (e) {
      print('Error opening orders Hive box: $e');
      // Try to delete and recreate the box if there's an error
      await Hive.deleteBoxFromDisk('orders');
      await Hive.openBox('orders');
      print('orders Hive box recreated after deletion');
    }

    // Open the designs box with a try-catch block
    try {
      await Hive.openBox('designs');
      print('designs Hive box opened successfully');
    } catch (e) {
      print('Error opening designs Hive box: $e');
      // Try to delete and recreate the box if there's an error
      await Hive.deleteBoxFromDisk('designs');
      await Hive.openBox('designs');
      print('designs Hive box recreated after deletion');
    }
  } catch (e) {
    print('Error initializing Hive: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fabric Purchase App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Use AppRoutes for navigation
      initialRoute: AppRoutes.login, // Start with login page
      routes: AppRoutes.getRoutes(),
      onUnknownRoute: (settings) {
        // Handle unknown routes
        return MaterialPageRoute(builder: (context) => const LoginPage());
      },
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}
