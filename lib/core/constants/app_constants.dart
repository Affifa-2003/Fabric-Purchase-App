// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFEBF5FF);
  
  // Status Colors
  static const Color pending = Color(0xFFEF4444);
  static const Color pendingLight = Color(0xFFFEF2F2);
  static const Color mixed = Color(0xFFF97316);
  static const Color mixedLight = Color(0xFFFFF7ED);
  static const Color complete = Color(0xFF10B981);
  static const Color completeLight = Color(0xFFF0FDF4);
  
  // Additional Status Colors
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  
  // Background Colors
  static const Color scaffoldBackground = Color(0xFFF9FAFB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  
  // Icon Colors
  static const Color iconLight = Color(0xFFD1D5DB);

  // Dialog Colors
  static const Color dialogBackground = Color(0xFFFFFFFF);
  static const Color dialogTitle = Color(0xFF111827);

  // Input Field Colors
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFD1D5DB);
  static const Color inputBorderFocused = Color(0xFF2563EB);

  // Shadow Colors
  static const Color shadow = Color(0x0F000000); // 6% opacity black
  static const Color shadowLight = Color(0x05000000); // 2% opacity black
}

class AppTextStyles {
  // AppBar Styles
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.cardBackground,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  
  static const TextStyle appBarTitleLarge = TextStyle(
    color: AppColors.cardBackground,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  
  // Card Styles
  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
  );
  
  // Button Styles
  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    color: AppColors.cardBackground,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.cardBackground,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryColor,
  );
  
  // List Item Styles
  static const TextStyle listItemTitle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle listItemSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
  );
  
  // Status Styles
  static TextStyle statusText(Color color) => TextStyle(
    color: color,
    fontWeight: FontWeight.bold,
  );
  
  // Empty State Styles
  static const TextStyle emptyStateTitle = TextStyle(
    fontSize: 18,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle emptyStateSubtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  );

  // Dialog Styles
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.dialogTitle,
  );

  static const TextStyle dialogContent = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  // Input Field Styles
  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  );

  // Error/Success Message Styles
  static const TextStyle errorMessage = TextStyle(
    fontSize: 14,
    color: AppColors.pending,
  );

  static const TextStyle successMessage = TextStyle(
    fontSize: 14,
    color: AppColors.complete,
  );
}

class AppSizes {
  // AppBar
  static const double appBarHeight = 55.0;
  
  // Button
  static const double buttonWidth = 36.0;
  static const double buttonHeight = 36.0;
  static const double buttonIconSize = 24.0;
  
  // Card
  static const double cardRadius = 8.0;
  static const double cardElevation = 0.0;
  static const double cardPadding = 16.0;
  static const double cardMargin = 8.0;
  
  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // Icon
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 64.0;
  
  // Status Dot
  static const double statusDotSize = 12.0;
  
  // Filter Chip
  static const double filterChipHeight = 50.0;
  static const double filterChipDotSize = 8.0;

  // Dialog
  static const double dialogRadius = 12.0;
  static const double dialogPadding = 16.0;
  static const double dialogElevation = 8.0;

  // List Item
  static const double listItemHeight = 72.0;
  static const double listItemSpacing = 8.0;

  // Input Field
  static const double inputHeight = 48.0;
  static const double inputPadding = 12.0;
  static const double inputRadius = 8.0;

  // Floating Action Button
  static const double fabSize = 56.0;
  static const double fabElevation = 6.0;

  // Divider
  static const double dividerThickness = 1.0;

  // Avatar
  static const double avatarSize = 40.0;
}

class AppStrings {
  // Common
  static const String appTitle = 'Hyatt Purchase';
  static const String search = 'Search';
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String ok = 'OK';
  static const String done = 'Done';
  static const String close = 'Close';
  
  // Pages
  static const String quality = 'Quality';
  static const String product = 'Product';
  static const String party = 'Party';
  static const String parties = 'Parties';
  static const String agent = 'Agent';
  static const String agents = 'Agents';
  static const String width = 'Width';
  static const String weaveType = 'Weave Type';
  static const String orderFormType = 'Order Form Type';
  static const String variety = 'Variety';
  static const String colorGroup = 'Color Group';
  static const String sampleMeter = 'Sample Meter';
  static const String financialYear = 'Financial Year';
  static const String season = 'Season';
  static const String purchaseOrderGroup = 'Purchase Order Group';
  static const String grade = 'Grade';
  static const String transport = 'Transport';
  
  // Messages
  static const String success = 'Success';
  static const String error = 'Error';
  static const String warning = 'Warning';
  static const String info = 'Information';
  
  // Empty States
  static const String noDataFound = 'No data found';
  static const String noMatchingData = 'No matching data';
  static const String tapToAddData = 'Tap + icon to add data';
  static const String tryDifferentSearch = 'Try a different search term';
  
  // Confirmation Dialogs
  static const String confirmDelete = 'Confirm Delete';
  static const String confirmLogout = 'Confirm Logout';
  static const String areYouSureDelete = 'Are you sure you want to delete';
  static const String areYouSureLogout = 'Are you sure you want to logout?';
  
  // Status Messages
  static const String addedSuccessfully = 'added successfully';
  static const String updatedSuccessfully = 'updated successfully';
  static const String deletedSuccessfully = 'deleted successfully';
  static const String errorAdding = 'Error adding';
  static const String errorUpdating = 'Error updating';
  static const String errorDeleting = 'Error deleting';
  
  // Navigation
  static const String home = 'Home';
  static const String settings = 'Settings';
  static const String logout = 'Logout';
  static const String profile = 'Profile';
  static const String about = 'About';

  // Form Fields
  static const String name = 'Name';
  static const String code = 'Code';
  static const String description = 'Description';
  static const String status = 'Status';
  static const String email = 'Email';
  static const String phone = 'Phone';
  static const String address = 'Address';
  static const String city = 'City';
  static const String state = 'State';
  static const String country = 'Country';
  static const String zipCode = 'Zip Code';

  // Status Values
  static const String active = 'Active';
  static const String inactive = 'Inactive';
  static const String pending = 'Pending';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';

  // Validation Messages
  static const String fieldRequired = 'This field is required';
  static const String enterValidEmail = 'Please enter a valid email';
  static const String enterValidPhone = 'Please enter a valid phone number';
  static const String passwordMismatch = 'Passwords do not match';
  static const String selectOption = 'Please select an option';

  // Success Messages
  static const String dataSaved = 'Data saved successfully';
  static const String dataUpdated = 'Data updated successfully';
  static const String dataDeleted = 'Data deleted successfully';

  // Error Messages
  static const String somethingWentWrong = 'Something went wrong';
  static const String networkError = 'Network error. Please check your connection';
  static const String serverError = 'Server error. Please try again later';

  // Loading Messages
  static const String loading = 'Loading...';
  static const String saving = 'Saving...';
  static const String deleting = 'Deleting...';
  static const String updating = 'Updating...';
}

class AppDecorations {
  // Card Decoration
  static BoxDecoration cardDecoration({
    Color? color,
    double? radius,
    double? elevation,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardBackground,
      borderRadius: BorderRadius.circular(radius ?? AppSizes.cardRadius),
      boxShadow: elevation != null && elevation > 0
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: elevation,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              )
            ]
          : null,
      border: borderColor != null
          ? Border.all(color: borderColor)
          : Border.all(color: AppColors.border),
    );
  }
  
  // Button Decoration
  static BoxDecoration buttonDecoration({
    Color? color,
    double? radius,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.primaryColor,
      shape: BoxShape.circle,
    );
  }
  
  // Status Dot Decoration
  static BoxDecoration statusDotDecoration(Color color) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    );
  }
  
  // Filter Chip Decoration
  static BoxDecoration filterChipDecoration({
    required bool isSelected,
    required Color dotColor,
    Color? selectedBgColor,
  }) {
    return BoxDecoration(
      color: isSelected
          ? selectedBgColor ?? AppColors.primaryLight
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isSelected
            ? dotColor.withOpacity(0.5)
            : AppColors.border,
      ),
    );
  }

  // Input Field Decoration
  static InputDecoration inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.inputPadding,
        vertical: AppSizes.inputPadding,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: const BorderSide(color: AppColors.inputBorderFocused),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: const BorderSide(color: AppColors.pending),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: const BorderSide(color: AppColors.pending),
      ),
      filled: true,
      fillColor: AppColors.inputBackground,
    );
  }

  // Dialog Decoration
  static BoxDecoration dialogDecoration() {
    return BoxDecoration(
      color: AppColors.dialogBackground,
      borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: AppSizes.dialogElevation,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Floating Action Button Decoration
  static BoxDecoration fabDecoration({
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.primaryColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: AppSizes.fabElevation,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class AppConstants {
  // API
  static const String apiBaseUrl = 'https://api.example.com';
  static const String apiVersion = 'v1';
  static const int apiTimeout = 30; // seconds

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'app_settings';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Debounce Time
  static const int searchDebounceTime = 500; // milliseconds

  // Date Formats
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayDateTimeFormat = 'dd MMM yyyy, hh:mm a';

  // Image
  static const double imageQuality = 0.8;
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
}

class AppRoutes {
  // Define your app routes here
  static const String home = '/';
  static const String login = '/login';
  static const String purchase = '/purchase';
  static const String newOrderSetup = '/new-order-setup';
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
}