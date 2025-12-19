import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';

class Helpers {
  // Format date to dd-MM-yyyy
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  // Format date to yyyy-MM-dd
  static String formatDateToYYYYMMDD(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Format date to ISO 8601 string
  static String formatDateToISO(DateTime? date) {
    if (date == null) return '';
    return date.toIso8601String();
  }

  // Parse date from string
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Show snackbar with message
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.green,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  // Add this method to your Helpers class (core/utils/helpers.dart)

static Widget buildDropdownFieldWithMap({
  required String label,
  required String? value,
  required List<Map<String, dynamic>> items,
  required Function(String?) onChanged,
  String? Function(String?)? validator,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.withOpacity(0.3)),
    ),
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: const Text('Select...'),
          isDense: true,
          style: const TextStyle(color: Colors.black),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['id'], // Use ID as value
              child: Text(item['name']), // Display name
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF529FF3)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF767676)),
          iconSize: 24,
          isExpanded: true,
        ),
      ],
    ),
  );
}

  // In your helpers.dart file, update the showConfirmationDialog method

static Future<bool> showConfirmationDialog(
  BuildContext context,
  String title,
  String content, {
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color confirmColor = Colors.red,
  Future<void> Function()? onConfirm, // Changed from Null Function() to Future<void> Function()?
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () async {
            // Execute the onConfirm callback if provided
            if (onConfirm != null) {
              await onConfirm();
            }
            Navigator.pop(context, true);
          },
          child: Text(confirmText),
          style: TextButton.styleFrom(foregroundColor: confirmColor),
        ),
      ],
    ),
  );
  return result ?? false;
}
  // Build a form field with consistent styling
  static Widget buildFormField({
    required String title,
    required Widget child,
    Color borderColor = Colors.grey,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  // Build dialog header with title and close button
  static Widget buildDialogHeader(String title, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Color(0xFF767676)),
          ),
        ],
      ),
    );
  }

  // Build dialog actions with Cancel and Save/Update buttons
  static Widget buildDialogActions(
    BuildContext context,
    bool isEditing,
    VoidCallback onSave, {
    String saveText = 'Save to Master',
    Color saveColor = const Color(0xFF10B981),
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: buildDialogButton(
              'Cancel',
              const Color(0xFF2563EB),
              () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: buildDialogButton(
              isEditing ? 'Update to Master' : saveText,
              saveColor,
              onSave,
            ),
          ),
        ],
      ),
    );
  }

  // Build dialog button with consistent styling
  static Widget buildDialogButton(
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Build info box with icon and message
  static Widget buildInfoBox(String message, {bool isEditing = false}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3182CE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF3182CE)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF3182CE)),
            ),
          ),
        ],
      ),
    );
  }

  // Build date field with date picker
  static Widget buildDateField({
    required String title,
    DateTime? date,
    required VoidCallback onTap,
    DateTime? minDate,
  }) {
    return buildFormField(
      title: title,
      child: GestureDetector(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: 'Select Date',
            hintStyle: TextStyle(
              color: date == null ? Colors.grey : Colors.black,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          ),
          child: Text(
            date == null ? 'Select Date' : formatDate(date),
            style: TextStyle(color: date == null ? Colors.grey : Colors.black),
          ),
        ),
      ),
    );
  }

  // Build text field with consistent styling
  static Widget buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          enabled: enabled,
          onEditingComplete: () {
            // Trim trailing spaces when editing is complete
            controller.text = controller.text.trim();
          },
        ),
      ],
    );
  }

  // Build dropdown field with consistent styling
  static Widget buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    String hintText = 'Select...',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hintText),
          isDense: true,
          style: const TextStyle(color: Colors.black),
          items: items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF529FF3)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF767676)),
          iconSize: 24,
          isExpanded: true,
        ),
      ],
    );
  }

  // Build app bar with consistent styling
  static AppBar buildAppBar({
    required String title,
    required GlobalKey<ScaffoldState> scaffoldKey,
    List<Widget>? actions,
  }) {
    return AppBar(
      backgroundColor: const Color(0xFF2563EB),
      toolbarHeight: 55,
      title: Text(title),
      titleTextStyle: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
      ),
      iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      actions: actions,
    );
  }

  // Build scaffold with drawer and consistent styling
  static Widget buildScaffold({
    required GlobalKey<ScaffoldState> scaffoldKey,
    required String title,
    required Widget body,
    List<Widget>? actions,
    FloatingActionButton? floatingActionButton,
  }) {
    return Scaffold(
      key: scaffoldKey,
      appBar: buildAppBar(
        title: title,
        scaffoldKey: scaffoldKey,
        actions: actions,
      ),
      drawer: CustomDrawer(
        scaffoldKey: scaffoldKey,
        primaryColor: const Color(0xFF2563EB),
        appTitle: 'Hyatt Purchase',
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  // Build search field with consistent styling
  static Widget buildSearchField({
    required TextEditingController controller,
    String hintText = 'Search...',
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  // Build empty state widget
  static Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Build loading widget
  static Widget buildLoadingWidget() {
    return const Center(child: CircularProgressIndicator());
  }

  // Build list item with consistent styling
  static Widget buildListItem({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEBF5FF),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              )
            : null,
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Color(0xFFEF4444),
                ),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}