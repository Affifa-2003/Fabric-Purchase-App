import 'package:flutter/material.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/routes/router.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/transactions/purchase_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color primaryColor = const Color(0xFF2563EB);
  final Color backgroundColor = const Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          backgroundColor, // Added background color to match other pages
      appBar: AppBar(
        toolbarHeight: 55,
        title: const Text(
          'Hyatt Purchase',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: primaryColor,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      drawer: CustomDrawer(
        scaffoldKey: _scaffoldKey,
        primaryColor: primaryColor,
        appTitle: 'Hyatt Purchase',
      ),
      body: _buildWelcomeContent(),
    );
  }

  Widget _buildWelcomeContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo or icon with background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(Icons.business_center, size: 60, color: primaryColor),
          ),
          const SizedBox(height: 30),

          // Welcome message
          const Text(
            'Welcome to',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),

          const Text(
            'Hyatt Purchase App',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(height: 30),

          // Subtitle
          const Text(
            'Your complete fabric purchase management solution',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Button to navigate to purchase list with better styling
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, const Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                AppRoutes.navigateTo(context, AppRoutes.purchase);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
