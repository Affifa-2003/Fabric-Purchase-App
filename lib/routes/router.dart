// app.routes.dart
import 'package:flutter/material.dart';
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
import 'package:purchase_app/Modules/Purchase/features/pages/transactions/purchase_list_page.dart';
import 'package:purchase_app/core/auth/login_page.dart';
import 'package:purchase_app/Modules/Purchase/features/pages/masters/home_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String purchase = '/purchase';
  static const String parties = '/parties';
  static const String agents = '/agents';
  static const String products = '/products';
  static const String width = '/width';
  static const String weaveType = '/weave-type';
  static const String quality = '/quality';
  static const String orderFormType = '/order-form-type';
  static const String variety = '/variety';
  static const String colorGroup = '/color-group';
  static const String sampleMeter = '/sample-meter';
  static const String financialYear = '/financial-year';
  static const String season = '/season';
  static const String purchaseOrderGroup = '/purchase-order-group';
  static const String grade = '/grade';
  static const String transport = '/transport';
  static const String newOrderSetup = '/new-order-setup';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      home: (context) => const HomePage(),
      purchase: (context) => const PurchaseListPage(),
      parties: (context) => const PartiesPage(),
      agents: (context) => const AgentsPage(),
      products: (context) => const ProductsPage(),
      width: (context) => const WidthPage(),
      weaveType: (context) => const WeaveTypePage(),
      quality: (context) => const QualityPage(),
      orderFormType: (context) => const OrderFormTypePage(),
      variety: (context) => const VarietyPage(),
      colorGroup: (context) => const ColorGroupPage(),
      sampleMeter: (context) => const SampleMeterPage(),
      financialYear: (context) => const FinancialYearPage(),
      season: (context) => const SeasonPage(),
      purchaseOrderGroup: (context) => const PurchaseOrderGroupPage(),
      grade: (context) => const GradesPage(),
      transport: (context) => const TransportPage(),
      newOrderSetup: (context) => const NewOrderSetupPage(),
    };
  }

  // Method to navigate with route name
  static void navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  // Method to replace current route with new route
  static void navigateAndReplace(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }
}
