import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';

class FinancialYearPage extends StatefulWidget {
  const FinancialYearPage({Key? key}) : super(key: key);

  @override
  _FinancialYearPageState createState() => _FinancialYearPageState();
}

class _FinancialYearPageState extends State<FinancialYearPage> {
  List<Map<String, dynamic>> financialYears = [];
  List<Map<String, dynamic>> filteredFinancialYears = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadFinancialYears();
    _searchController.addListener(_filterFinancialYears);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialYears() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveFinancialYears = [];

      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      appDataBox = Hive.box('appData');

      final financialYearsData = appDataBox.get('financialYears');
      if (financialYearsData != null) {
        // Handle different types of data
        if (financialYearsData is List) {
          hiveFinancialYears = financialYearsData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }

      setState(() {
        financialYears = hiveFinancialYears;
        filteredFinancialYears = List.from(financialYears);
        _isLoading = false;
      });

      print('Loaded ${financialYears.length} financial years from Hive');
    } catch (e) {
      print('Error loading financial years: $e');
      setState(() {
        financialYears = [];
        filteredFinancialYears = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFinancialYearsToStorage() async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Ensure we're saving a list of maps with proper types
      List<Map<String, dynamic>> financialYearsToSave = financialYears.map((
        financialYear,
      ) {
        return {
          'name': financialYear['name']?.toString() ?? '',
          'description': financialYear['description']?.toString() ?? '',
          'status': financialYear['status']?.toString() ?? 'Active',
        };
      }).toList();

      // Save data with explicit await to ensure it's written to disk
      await box.put('financialYears', financialYearsToSave);

      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved financial years: ${box.get('financialYears')}');
      print('Financial years data saved successfully');
    } catch (e) {
      print('Error saving financial years data: $e');
      // Show error to user
      Helpers.showErrorSnackBar(context, 'Error saving financial years: $e');
    }
  }

  void _filterFinancialYears() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredFinancialYears = List.from(financialYears);
      } else {
        filteredFinancialYears = financialYears.where((financialYear) {
          return financialYear['name'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showAddNewFinancialYearDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FinancialYearDialog(
          title: 'Add Financial Year',
          onSave: (newFinancialYear) {
            setState(() {
              financialYears.insert(0, newFinancialYear);
              _filterFinancialYears();
            });
            _saveFinancialYearsToStorage();
            Helpers.showSuccessSnackBar(context, 'Financial year added successfully');
          },
        );
      },
    );
  }

  void _showEditFinancialYearDialog(
    Map<String, dynamic> financialYear,
    int index,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FinancialYearDialog(
          title: 'Edit Financial Year',
          initialFinancialYear: financialYear,
          onSave: (updatedFinancialYear) {
            setState(() {
              financialYears.removeAt(index);
              financialYears.insert(0, updatedFinancialYear);
              _filterFinancialYears();
            });
            _saveFinancialYearsToStorage();
            Helpers.showSuccessSnackBar(context, 'Financial year updated successfully');
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Helpers.buildScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Financial Year',
      body: _isLoading
          ? Helpers.buildLoadingWidget()
          : Column(
              children: [
                Helpers.buildSearchField(
                  controller: _searchController,
                  hintText: 'Search Financial Year',
                ),
                Expanded(
                  child: filteredFinancialYears.isEmpty
                      ? Helpers.buildEmptyState(
                          icon: Icons.calendar_today_outlined,
                          title: financialYears.isEmpty
                              ? 'No financial years found'
                              : 'No matching financial years',
                          subtitle: financialYears.isEmpty
                              ? 'Add financial years using the + button'
                              : 'Try a different search term',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFinancialYears,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredFinancialYears.length,
                            itemBuilder: (context, index) {
                              final financialYear =
                                  filteredFinancialYears[index];
                              return Helpers.buildListItem(
                                title: financialYear['name'],
                                icon: Icons.calendar_today,
                                onTap: () {
                                  // Find the original index in the financialYears list
                                  int originalIndex = financialYears.indexWhere(
                                    (fy) => fy['name'] == financialYear['name'],
                                  );
                                  if (originalIndex != -1) {
                                    _showEditFinancialYearDialog(
                                      financialYear,
                                      originalIndex,
                                    );
                                  }
                                },
                                onDelete: () => _showDeleteConfirmationDialog(financialYear),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 24),
            onPressed: _showAddNewFinancialYearDialog,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> financialYear) {
    // Check if financial year is used in any purchase order groups
    bool isUsedInPurchaseOrderGroups = false;

    try {
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');
        final purchaseOrderGroupsData = appDataBox.get('purchaseOrderGroups');

        if (purchaseOrderGroupsData != null &&
            purchaseOrderGroupsData is List) {
          for (var group in purchaseOrderGroupsData) {
            if (group is Map &&
                group['financialYear'] == financialYear['name']) {
              isUsedInPurchaseOrderGroups = true;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error checking if financial year is used: $e');
    }

    if (isUsedInPurchaseOrderGroups) {
      Helpers.showErrorSnackBar(
        context,
        'This financial year is already mapped with purchase order groups and cannot be deleted.',
      );
      return;
    }

    Helpers.showConfirmationDialog(
      context,
      'Confirm Delete',
      'Are you sure you want to delete "${financialYear['name']}"?',
      confirmText: 'Delete',
      onConfirm: () async {
        // Find the original index in the financialYears list
        int originalIndex = financialYears.indexWhere(
          (fy) => fy['name'] == financialYear['name'],
        );
        if (originalIndex != -1) {
          // Update local state immediately
          setState(() {
            financialYears.removeAt(originalIndex);
            _filterFinancialYears(); // Update filtered list
          });

          // Save to Hive
          await _saveFinancialYearsToStorage();

          // Show success message
          Helpers.showSuccessSnackBar(context, 'Financial year deleted successfully');
        }
      },
    );
  }
}

// Separate StatefulWidget for the dialog
class FinancialYearDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialFinancialYear;
  final Function(Map<String, dynamic>) onSave;

  const FinancialYearDialog({
    Key? key,
    required this.title,
    this.initialFinancialYear,
    required this.onSave,
  }) : super(key: key);

  @override
  _FinancialYearDialogState createState() => _FinancialYearDialogState();
}

class _FinancialYearDialogState extends State<FinancialYearDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _statusValue = 'Active';
  bool _isSaving = false;
  
  // Error states
  bool _nameError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialFinancialYear?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialFinancialYear?['description'] ?? '',
    );
    _statusValue = widget.initialFinancialYear?['status'] ?? 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Helpers.buildDialogHeader(widget.title, context),
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildStatusDropdown(),
                    const SizedBox(height: 16),
                    Helpers.buildInfoBox(
                      widget.initialFinancialYear == null
                          ? 'This will be added to master and available for future use.'
                          : 'This will update the financial year in master and all associated records.',
                      isEditing: widget.initialFinancialYear != null,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),
            _buildDialogButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Helpers.buildFormField(
      title: 'Financial Year Name: *',
      child: TextField(
        controller: _nameController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        decoration: InputDecoration(
          hintText: 'e.g. 2024-25',
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _nameError ? Colors.red : Colors.grey,
            ),
          ),
          errorText: _nameError ? 'Financial year name is required' : null,
        ),
        onChanged: (value) {
          setState(() {
            _nameError = Validators.validateRequired(value, 'Financial Year Name') != null;
          });
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Helpers.buildFormField(
      title: 'Description:',
      child: TextField(
        controller: _descriptionController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Optional description',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Helpers.buildFormField(
      title: 'Status: *',
      child: DropdownButtonFormField<String>(
        value: _statusValue,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: ['Active', 'Inactive']
            .map(
              (status) =>
                  DropdownMenuItem<String>(value: status, child: Text(status)),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _statusValue = value!;
          });
        },
      ),
    );
  }

  Widget _buildDialogButtons() {
    return Helpers.buildDialogActions(
      context,
      widget.initialFinancialYear != null,
      () async {
        // Validate form
        setState(() {
          _nameError = Validators.validateRequired(_nameController.text, 'Financial Year Name') != null;
        });

        if (_nameError) {
          return;
        }

        setState(() {
          _isSaving = true;
        });

        Map<String, dynamic> newFinancialYear = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': _statusValue,
        };

        await widget.onSave(newFinancialYear);

        setState(() {
          _isSaving = false;
        });

        Navigator.pop(context);
      },
      saveText: widget.initialFinancialYear == null ? 'Save to Master' : 'Update to Master',
    );
  }
}