// custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:purchase_app/routes/router.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/agent_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/color_group_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/financial_year_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/grade_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/order_form_type_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/parties_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/transactions/new_order_setup_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/products_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/purchase_order_group_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/quality_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/sample_meter_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/season_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/transport_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/variety_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/weave_type_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/width_page.dart';

class CustomDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Color primaryColor;
  final String appTitle;

  const CustomDrawer({
    Key? key,
    required this.scaffoldKey,
    required this.primaryColor,
    this.appTitle = 'Hyatt Purchase',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTabletOrWeb = constraints.maxWidth > 600;
        double drawerWidth = isTabletOrWeb
            ? (constraints.maxWidth * 0.4).clamp(250, 400)
            : constraints.maxWidth * 0.8;
        double titleFontSize = isTabletOrWeb ? 28.0 : 24.0;
        double emailFontSize = isTabletOrWeb ? 18.0 : 16.0;
        double menuItemFontSize = isTabletOrWeb ? 18.0 : 16.0;
        double submenuFontSize = isTabletOrWeb ? 16.0 : 14.0;
        double avatarRadius = isTabletOrWeb ? 40.0 : 30.0;
        double iconSize = isTabletOrWeb ? 28.0 : 24.0;
        double personIconSize = isTabletOrWeb ? 50.0 : 40.0;
        double headerPadding = isTabletOrWeb ? 24.0 : 16.0;
        double verticalSpacing = isTabletOrWeb ? 20.0 : 16.0;

        return SizedBox(
          width: drawerWidth,
          child: Drawer(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: primaryColor,
                  padding: EdgeInsets.fromLTRB(
                    headerPadding,
                    headerPadding + 8,
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
                        appTitle,
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Transaction Menu
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Icon(
                              Icons.receipt_long,
                              color: primaryColor,
                              size: iconSize,
                            ),
                            title: Text(
                              'Transaction',
                              style: TextStyle(
                                fontSize: menuItemFontSize,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.shopping_cart,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Purchase',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(context, AppRoutes.purchase);
                                },
                              ),
                            ],
                          ),
                        ),

                        // Masters Menu
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Icon(
                              Icons.settings,
                              color: primaryColor,
                              size: iconSize,
                            ),
                            title: Text(
                              'Masters',
                              style: TextStyle(
                                fontSize: menuItemFontSize,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.business,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Parties',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.parties,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.people,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Agents',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.agents,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.inventory_2,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Products',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.products,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.straighten,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Width',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.width,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.texture,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Weave Type',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.weaveType,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.style,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Quality',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.quality,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.description,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Order Form Type',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.orderFormType,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.category,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Variety',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.variety,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.color_lens,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Color Group',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.colorGroup,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.speed,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Sample Meter',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.sampleMeter,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.calendar_today,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Financial Year',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.financialYear,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.eco,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Season',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.season,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.group_work,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Purchase Order Group',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.purchaseOrderGroup,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.grade,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Grade',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.grade,
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isTabletOrWeb ? 70 : 60,
                                ),
                                leading: Icon(
                                  Icons.local_shipping,
                                  color: primaryColor,
                                  size: iconSize - 4,
                                ),
                                title: Text(
                                  'Transport',
                                  style: TextStyle(
                                    fontSize: submenuFontSize,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  AppRoutes.navigateTo(
                                    context,
                                    AppRoutes.transport,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Logout
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
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showLogoutConfirmation(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppRoutes.navigateAndReplace(context, AppRoutes.login);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}