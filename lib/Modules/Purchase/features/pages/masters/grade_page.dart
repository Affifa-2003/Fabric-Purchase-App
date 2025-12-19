import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart'
    hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';
// NEW: Import the UUID utility
import 'package:purchase_app/core/utils/uuid_utils.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({Key? key}) : super(key: key);

  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  List<Map<String, dynamic>> grades = [];
  List<Map<String, dynamic>> filteredGrades = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadGrades();
    _searchController.addListener(_filterGrades);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // NOTE: No changes needed in _loadGrades. It dynamically loads whatever is in the map,
  // so it will correctly load the 'id' field if it exists in Hive.
  Future<void> _loadGrades() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveGrades = [];

      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      appDataBox = Hive.box('appData');

      final gradesData = appDataBox.get('grades');
      print('gradesData: $gradesData');
      if (gradesData != null) {
        // Handle different types of data
        if (gradesData is List) {
          hiveGrades = gradesData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }

      setState(() {
        grades = hiveGrades;
        filteredGrades = List.from(grades);
        _isLoading = false;
      });

      print('Loaded ${grades.length} grades from Hive');
    } catch (e) {
      print('Error loading grades: $e');
      setState(() {
        grades = [];
        filteredGrades = [];
        _isLoading = false;
      });
    }
  }

  // MODIFIED: Updated to include the 'id' field when saving.
  Future<void> _saveGradesToStorage() async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Ensure we're saving a list of maps with proper types, including the ID.
      List<Map<String, dynamic>> gradesToSave = grades.map((grade) {
        return {
          'id':
              grade['id']?.toString() ??
              '', // Save the ID, ensure it's a string.
          'name': grade['name']?.toString() ?? '',
          'description': grade['description']?.toString() ?? '',
        };
      }).toList();

      // Save data with explicit await to ensure it's written to disk
      await box.put('grades', gradesToSave);

      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved grades: ${box.get('grades')}');
      print('Grades data saved successfully');
    } catch (e) {
      print('Error saving grades data: $e');
      // Show error to user
      Helpers.showErrorSnackBar(context, 'Error saving grades: $e');
    }
  }

  void _filterGrades() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredGrades = List.from(grades);
      } else {
        filteredGrades = grades.where((grade) {
          // Filter by name, as that's what the user searches for.
          return grade['name'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // MODIFIED: Generates a UUID for the new grade before saving.
  void _showAddNewGradeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return GradeDialog(
          title: 'Add Grade',
          onSave: (newGrade) {
            // Create a new map to avoid modifying the dialog's state map directly.
            final gradeWithId = Map<String, dynamic>.from(newGrade);
            // NEW: Generate a unique ID for the new grade.
            gradeWithId['id'] = UUID.generate();

            setState(() {
              grades.insert(0, gradeWithId);
              _filterGrades();
            });
            _saveGradesToStorage();
            Helpers.showSuccessSnackBar(context, 'Grade added successfully');
          },
        );
      },
    );
  }

  // MODIFIED: Preserves the existing ID when updating a grade.
  void _showEditGradeDialog(Map<String, dynamic> grade, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return GradeDialog(
          title: 'Edit Grade',
          initialGrade: grade,
          onSave: (updatedGrade) async {
            // Check if name is being changed
            bool nameChanged = updatedGrade['name'] != grade['name'];

            // NEW: Preserve the existing ID from the original grade map.
            updatedGrade['id'] = grade['id'];

            setState(() {
              grades.removeAt(index);
              grades.insert(0, updatedGrade);
              _filterGrades();
            });

            await _saveGradesToStorage();

            // If name changed, update all related records
            if (nameChanged) {
              await _updateGradeNameInAllRecords(
                grade['name'],
                updatedGrade['name'],
              );
            }

            Helpers.showSuccessSnackBar(context, 'Grade updated successfully');
          },
        );
      },
    );
  }

  // NOTE: This function is left as is. It updates references by name because
  // that's what is stored in the 'orders' box. A better long-term solution
  // would be to store the grade_id in orders, but that is outside the scope of this request.
  Future<void> _updateGradeNameInAllRecords(
    String oldName,
    String newName,
  ) async {
    try {
      // Update grade name in orders box
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');
        final ordersData = appDataBox.get('orders');

        if (ordersData != null && ordersData is List) {
          List<Map<String, dynamic>> updatedOrdersData = [];

          for (var order in ordersData) {
            Map<String, dynamic> orderMap = Map<String, dynamic>.from(order);
            if (orderMap['grade'] == oldName) {
              orderMap['grade'] = newName;
            }
            updatedOrdersData.add(orderMap);
          }

          await appDataBox.put('orders', updatedOrdersData);
          await appDataBox.flush();
          print('Updated grade name in orders box');
        }
      }
    } catch (e) {
      print('Error updating grade name in all records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Helpers.buildScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Grades',
      body: _isLoading
          ? Helpers.buildLoadingWidget()
          : Column(
              children: [
                Helpers.buildSearchField(
                  controller: _searchController,
                  hintText: 'Search Grades',
                ),
                Expanded(
                  child: filteredGrades.isEmpty
                      ? Helpers.buildEmptyState(
                          icon: Icons.grade_outlined,
                          title: grades.isEmpty
                              ? 'No grades found'
                              : 'No matching grades',
                          subtitle: grades.isEmpty
                              ? 'Add grades using the + button'
                              : 'Try a different search term',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadGrades,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredGrades.length,
                            itemBuilder: (context, index) {
                              final grade = filteredGrades[index];
                              // MODIFIED: Use the unique ID to find the original index for more reliable lookups.
                              final originalIndex = grades.indexWhere(
                                (g) => g['id'] == grade['id'],
                              );
                              return Helpers.buildListItem(
                                title: grade['name'],
                                icon: Icons.grade,
                                onTap: () {
                                  if (originalIndex != -1) {
                                    _showEditGradeDialog(grade, originalIndex);
                                  }
                                },
                                onDelete: () =>
                                    _showDeleteConfirmationDialog(grade),
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
            onPressed: _showAddNewGradeDialog,
          ),
        ),
      ],
    );
  }

  // MODIFIED: Use the unique ID to find the grade to delete.
  void _showDeleteConfirmationDialog(Map<String, dynamic> grade) {
    // Check if grade is used in any orders
    bool isUsedInOrders = false;

    // Check if grade is mapped to any agents
    bool isMappedToAgents = false;

    try {
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');

        // Check if grade is used in orders
        final ordersData = appDataBox.get('orders');

        if (ordersData != null && ordersData is List) {
          for (var order in ordersData) {
            if (order is Map && order['grade'] == grade['name']) {
              isUsedInOrders = true;
              break;
            }
          }
        }

        // Check if grade is mapped to agents
        final agentsData = appDataBox.get('agents');

        if (agentsData != null && agentsData is List) {
          for (var agent in agentsData) {
            if (agent is Map && agent['grade'] == grade['name']) {
              isMappedToAgents = true;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error checking if grade is used: $e');
    }

    if (isUsedInOrders || isMappedToAgents) {
      String errorMessage = 'This grade is already ';
      if (isUsedInOrders) errorMessage += 'used in orders';
      if (isUsedInOrders && isMappedToAgents) errorMessage += ' and ';
      if (isMappedToAgents) errorMessage += 'mapped to agents';
      errorMessage += ' and cannot be deleted.';

      Helpers.showErrorSnackBar(context, errorMessage);
      return;
    }

    Helpers.showConfirmationDialog(
      context,
      'Confirm Delete',
      'Are you sure you want to delete "${grade['name']}"?',
      confirmText: 'Delete',
      onConfirm: () async {
        // MODIFIED: Find the item to delete using its unique ID.
        final originalIndex = grades.indexWhere((g) => g['id'] == grade['id']);
        if (originalIndex != -1) {
          setState(() {
            grades.removeAt(originalIndex);
            _filterGrades();
          });
          await _saveGradesToStorage();
          Helpers.showSuccessSnackBar(context, 'Grade deleted successfully');
        }
      },
    );
  }
}

// No changes are needed in the GradeDialog widget itself.
// It remains focused on UI and user input for name and description.
class GradeDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialGrade;
  final Function(Map<String, dynamic>) onSave;

  const GradeDialog({
    Key? key,
    required this.title,
    this.initialGrade,
    required this.onSave,
  }) : super(key: key);

  @override
  _GradeDialogState createState() => _GradeDialogState();
}

class _GradeDialogState extends State<GradeDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isSaving = false;

  // Error states
  bool _nameError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialGrade?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialGrade?['description'] ?? '',
    );
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
                    Helpers.buildInfoBox(
                      widget.initialGrade == null
                          ? 'This will be added to master and available for future orders.'
                          : 'This will update grade in master and all associated records.',
                      isEditing: widget.initialGrade != null,
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
      title: 'Grade Name: *',
      child: TextField(
        controller: _nameController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        decoration: InputDecoration(
          hintText: 'e.g. A, B, Premium',
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _nameError ? Colors.red : Colors.grey,
            ),
          ),
          errorText: _nameError ? 'Grade name is required' : null,
        ),
        onChanged: (value) {
          setState(() {
            _nameError =
                Validators.validateRequired(value, 'Grade Name') != null;
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
          hintText: 'Optional grade description',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDialogButtons() {
    return Helpers.buildDialogActions(
      context,
      widget.initialGrade != null,
      () async {
        // Validate form
        setState(() {
          _nameError =
              Validators.validateRequired(_nameController.text, 'Grade Name') !=
              null;
        });

        if (_nameError) {
          return;
        }

        setState(() {
          _isSaving = true;
        });

        Map<String, dynamic> newGrade = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
        };

        await widget.onSave(newGrade);

        setState(() {
          _isSaving = false;
        });

        Navigator.pop(context);
      },
      saveText: widget.initialGrade == null
          ? 'Save to Master'
          : 'Update to Master',
    );
  }
}
