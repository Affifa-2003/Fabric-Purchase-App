import 'package:flutter/material.dart';
import 'package:purchase_app/agent_page.dart';
import 'package:purchase_app/parties_page.dart';
import 'package:purchase_app/new_order_setup_page.dart';
import 'package:purchase_app/products_page.dart';
import 'package:purchase_app/quality_page.dart';
import 'package:purchase_app/variety_page.dart';
import 'package:purchase_app/weave_type_page.dart';
import 'package:purchase_app/width_page.dart';
import 'purchase_list_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color primaryColor = const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 55, // Increased app bar height
        title: const Text(
          'Fabric Purchase',
          style: TextStyle(
            fontSize: 20, // Increased font size
            fontWeight: FontWeight.bold, // Added bold weight
            letterSpacing: 0.5, // Added letter spacing for better appearance
          ),
        ),
        backgroundColor: primaryColor,
        centerTitle: false, // Changed to false to align title to the left
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36, // Set fixed width for smaller circle
            height: 36, // Set fixed height for smaller circle
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero, // Remove default padding
              icon: Icon(
                Icons.add,
                color: primaryColor,
                size: 24,
              ), // Adjusted icon size
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewOrderSetupPage(),
                  ),
                );
              },
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22, // Match the title font size
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      drawer: _buildDrawer(),
      body: const PurchaseListPage(),
    );
  }

  // In home_page.dart, update the _buildDrawer method

  Widget _buildDrawer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if it's a tablet or web based on screen width
        bool isTabletOrWeb = constraints.maxWidth > 600;

        // Calculate responsive drawer width
        double drawerWidth = isTabletOrWeb
            ? (constraints.maxWidth * 0.4).clamp(250, 400)
            : constraints.maxWidth * 0.8;

        // Calculate responsive font sizes
        double titleFontSize = isTabletOrWeb ? 28.0 : 24.0;
        double emailFontSize = isTabletOrWeb ? 18.0 : 16.0;
        double menuItemFontSize = isTabletOrWeb ? 18.0 : 16.0;

        // Calculate responsive icon sizes
        double avatarRadius = isTabletOrWeb ? 40.0 : 30.0;
        double iconSize = isTabletOrWeb ? 28.0 : 24.0;
        double personIconSize = isTabletOrWeb ? 50.0 : 40.0;

        // Calculate responsive padding
        double headerPadding = isTabletOrWeb ? 24.0 : 16.0;
        double verticalSpacing = isTabletOrWeb ? 20.0 : 16.0;

        return SizedBox(
          width: drawerWidth,
          child: Drawer(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // This helps to remove empty space
              children: [
                // Fixed header section - blue background
                Container(
                  width: double.infinity,
                  color: primaryColor,
                  padding: EdgeInsets.fromLTRB(
                    headerPadding,
                    headerPadding + 8, // Extra top padding for status bar
                    headerPadding,
                    headerPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: personIconSize,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      Text(
                        'Fabric Purchase',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'user@gmail.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: emailFontSize,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu items without background color
                Column(
                  mainAxisSize:
                      MainAxisSize.min, // This helps to remove empty space
                  children: [
                    // Purchase menu item
                    ListTile(
                      leading: Icon(
                        Icons.shopping_cart,
                        color: primaryColor,
                        size: iconSize,
                      ),
                      title: Text(
                        'Purchase',
                        style: TextStyle(
                          fontSize: menuItemFontSize,
                          color: Colors.black, // Changed to black
                          // Removed fontWeight: FontWeight.bold
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        // Already on purchase page
                      },
                    ),
                    // Parties menu item
                    ListTile(
                      leading: Icon(
                        Icons.business,
                        color: primaryColor,
                        size: iconSize,
                      ),
                      title: Text(
                        'Parties',
                        style: TextStyle(
                          fontSize: menuItemFontSize,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PartiesPage(),
                          ),
                        );
                      },
                    ),
                    // Agents menu item
                    ListTile(
                      leading: Icon(
                        Icons.people,
                        color: primaryColor,
                        size: iconSize,
                      ),
                      title: Text(
                        'Agents',
                        style: TextStyle(
                          fontSize: menuItemFontSize,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AgentsPage(),
                          ),
                        );
                      },
                    ),

                    // Products menu item
                    ListTile(
                      leading: Icon(
                        Icons.inventory_2,
                        color: primaryColor,
                        size: iconSize,
                      ),
                      title: Text(
                        'Products',
                        style: TextStyle(
                          fontSize: menuItemFontSize,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductsPage(),
                          ),
                        );
                      },
                    ),
                    // Width menu item
                    ListTile(
                      leading: Icon(
                        Icons.straighten,
                        color: primaryColor,
                        size: iconSize,
                      ),
                      title: Text(
                        'Width',
                        style: TextStyle(
                          fontSize: menuItemFontSize,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WidthPage(),
                          ),
                        );
                      },
                    ),
                    // Weave Type menu item
                    ListTile(
                      leading: Icon(
                        Icons.texture,
                        color: primaryColor,
                        size: iconSize,
                      ),
                      title: Text(
                        'Weave Type',
                        style: TextStyle(
                          fontSize: menuItemFontSize,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WeaveTypePage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.style, // A suitable icon for quality
                        color: primaryColor,
                        size: iconSize,
                      ),
                      title: Text(
                        'Quality',
                        style: TextStyle(
                          fontSize: menuItemFontSize,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QualityPage(),
                          ),
                        );
                      },
                    ),
                    // Variety menu item - Added this section
                    ListTile(
                      leading: Icon(
                        Icons.category,
                        color: primaryColor,
                        size: iconSize,
                      ),
                      title: Text(
                        'Variety',
                        style: TextStyle(
                          fontSize: menuItemFontSize,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VarietyPage(),
                          ),
                        );
                      },
                    ),
                    // Removed the Divider
                    // Logout menu item
                    ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: primaryColor,
                        size: iconSize,
                      ),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: menuItemFontSize,
                          color: Colors.black, // Changed to black
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        _showLogoutConfirmation();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                ), // Red color for cancel button
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
