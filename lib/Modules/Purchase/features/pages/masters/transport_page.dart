import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart'
    hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';
import 'package:purchase_app/core/utils/uuid_utils.dart';

class TransportPage extends StatefulWidget {
  const TransportPage({Key? key}) : super(key: key);

  @override
  _TransportPageState createState() => _TransportPageState();
}

class _TransportPageState extends State<TransportPage> {
  List<Map<String, dynamic>> transports = [];
  List<Map<String, dynamic>> filteredTransports = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadTransports();
    _searchController.addListener(_filterTransports);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // so it will correctly load the 'id' field if it exists in Hive.
  Future<void> _loadTransports() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveTransports = [];

      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      appDataBox = Hive.box('appData');

      final transportsData = appDataBox.get('transports');
      print('transportsData: $transportsData');
      if (transportsData != null) {
        // Handle different types of data
        if (transportsData is List) {
          hiveTransports = transportsData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }

      setState(() {
        transports = hiveTransports;
        filteredTransports = List.from(transports);
        _isLoading = false;
      });

      print('Loaded ${transports.length} transports from Hive');
    } catch (e) {
      print('Error loading transports: $e');
      setState(() {
        transports = [];
        filteredTransports = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTransportsToStorage() async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      List<Map<String, dynamic>> transportsToSave = transports.map((transport) {
        return {
          'id': transport['id']?.toString() ?? '',
          'name': transport['name']?.toString() ?? '',
          'address': transport['address']?.toString() ?? '',
          'gstNo': transport['gstNo']?.toString() ?? '',
          'mobileNumber': transport['mobileNumber']?.toString() ?? '',
          'contactPerson': transport['contactPerson']?.toString() ?? '',
          'status': transport['status']?.toString() ?? 'Active',
        };
      }).toList();

      await box.put('transports', transportsToSave);

      await box.flush();

      print('Saved transports: ${box.get('transports')}');
      print('Transports data saved successfully');
    } catch (e) {
      print('Error saving transports data: $e');
      Helpers.showErrorSnackBar(context, 'Error saving transports: $e');
    }
  }

  void _filterTransports() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredTransports = List.from(transports);
      } else {
        filteredTransports = transports.where((transport) {
          return transport['name'].toLowerCase().contains(query) ||
              transport['mobileNumber'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showAddNewTransportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return TransportDialog(
          title: 'Add Transport',
          transports: transports, // Pass the transports list
          onSave: (newTransport) {
            final transportWithId = Map<String, dynamic>.from(newTransport);
            // Generate a unique ID for the transport.
            transportWithId['id'] = UUID.generate();

            setState(() {
              transports.insert(0, transportWithId);
              _filterTransports();
            });
            _saveTransportsToStorage();
            Helpers.showSuccessSnackBar(
              context,
              'Transport added successfully',
            );
          },
        );
      },
    );
  }

  void _showEditTransportDialog(Map<String, dynamic> transport, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return TransportDialog(
          title: 'Edit Transport',
          initialTransport: transport,
          transports: transports, // Pass the transports list
          onSave: (updatedTransport) {
            // Preserve the existing ID from the original transport map.
            updatedTransport['id'] = transport['id'];

            setState(() {
              transports.removeAt(index);
              transports.insert(0, updatedTransport);
              _filterTransports();
            });
            _saveTransportsToStorage();
            Helpers.showSuccessSnackBar(
              context,
              'Transport updated successfully',
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Helpers.buildScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Transport',
      body: _isLoading
          ? Helpers.buildLoadingWidget()
          : Column(
              children: [
                Helpers.buildSearchField(
                  controller: _searchController,
                  hintText: 'Search Transport',
                ),
                Expanded(
                  child: filteredTransports.isEmpty
                      ? Helpers.buildEmptyState(
                          icon: Icons.local_shipping_outlined,
                          title: transports.isEmpty
                              ? 'No transport companies found'
                              : 'No matching transport companies',
                          subtitle: transports.isEmpty
                              ? 'Add transport companies using the + button'
                              : 'Try a different search term',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTransports,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredTransports.length,
                            itemBuilder: (context, index) {
                              final transport = filteredTransports[index];
                              // Use the unique ID to find the original index for more reliable lookups.
                              final originalIndex = transports.indexWhere(
                                (t) => t['id'] == transport['id'],
                              );
                              return Helpers.buildListItem(
                                title: transport['name'],
                                subtitle: transport['mobileNumber'],
                                icon: Icons.local_shipping,
                                onTap: () {
                                  if (originalIndex != -1) {
                                    _showEditTransportDialog(
                                      transport,
                                      originalIndex,
                                    );
                                  }
                                },
                                onDelete: () =>
                                    _showDeleteConfirmationDialog(transport),
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
            onPressed: _showAddNewTransportDialog,
          ),
        ),
      ],
    );
  }

  // Use the unique ID to find the transport to delete.
  void _showDeleteConfirmationDialog(Map<String, dynamic> transport) {
    // Check if transport is used in any orders
    bool isUsedInOrders = false;

    // Check if transport is mapped to any parties
    bool isMappedToParties = false;

    try {
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');

        // Check if transport is used in orders
        final ordersData = appDataBox.get('orders');

        if (ordersData != null && ordersData is List) {
          for (var order in ordersData) {
            if (order is Map && order['transport'] == transport['name']) {
              isUsedInOrders = true;
              break;
            }
          }
        }

        // Check if transport is mapped to parties
        final partiesData = appDataBox.get('parties');

        if (partiesData != null && partiesData is List) {
          for (var party in partiesData) {
            if (party is Map && party['transport'] == transport['name']) {
              isMappedToParties = true;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error checking if transport is used: $e');
    }

    if (isUsedInOrders || isMappedToParties) {
      String errorMessage = 'This transport is already ';
      if (isUsedInOrders) errorMessage += 'used in orders';
      if (isUsedInOrders && isMappedToParties) errorMessage += ' and ';
      if (isMappedToParties) errorMessage += 'mapped to parties';
      errorMessage += ' and cannot be deleted.';

      Helpers.showErrorSnackBar(context, errorMessage);
      return;
    }

    Helpers.showConfirmationDialog(
      context,
      'Confirm Delete',
      'Are you sure you want to delete "${transport['name']}"?',
      confirmText: 'Delete',
      onConfirm: () async {
        //Find the item to delete using its unique ID.
        final originalIndex = transports.indexWhere(
          (t) => t['id'] == transport['id'],
        );
        if (originalIndex != -1) {
          setState(() {
            transports.removeAt(originalIndex);
            _filterTransports();
          });
          await _saveTransportsToStorage();
          Helpers.showSuccessSnackBar(
            context,
            'Transport deleted successfully',
          );
        }
      },
    );
  }
}

class TransportDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialTransport;
  final List<Map<String, dynamic>> transports;
  final Function(Map<String, dynamic>) onSave;

  const TransportDialog({
    Key? key,
    required this.title,
    this.initialTransport,
    required this.transports,
    required this.onSave,
  }) : super(key: key);

  @override
  _TransportDialogState createState() => _TransportDialogState();
}

class _TransportDialogState extends State<TransportDialog> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _gstNoController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _contactPersonController;
  String _statusValue = 'Active';
  bool _isSaving = false;

  // Error states
  bool _nameError = false;
  bool _mobileNumberError = false;
  String _mobileNumberErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialTransport?['name'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialTransport?['address'] ?? '',
    );
    _gstNoController = TextEditingController(
      text: widget.initialTransport?['gstNo'] ?? '',
    );
    _mobileNumberController = TextEditingController(
      text: widget.initialTransport?['mobileNumber'] ?? '',
    );
    _contactPersonController = TextEditingController(
      text: widget.initialTransport?['contactPerson'] ?? '',
    );
    _statusValue = widget.initialTransport?['status'] ?? 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstNoController.dispose();
    _mobileNumberController.dispose();
    _contactPersonController.dispose();
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
                    _buildAddressField(),
                    const SizedBox(height: 16),
                    _buildGSTNoField(),
                    const SizedBox(height: 16),
                    _buildMobileNumberField(),
                    const SizedBox(height: 16),
                    _buildContactPersonField(),
                    const SizedBox(height: 16),
                    _buildStatusDropdown(),
                    const SizedBox(height: 16),
                    Helpers.buildInfoBox(
                      widget.initialTransport == null
                          ? 'This will be added to master and available for future orders.'
                          : 'This will update transport in master and all associated records.',
                      isEditing: widget.initialTransport != null,
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
      title: 'Transport Company Name: *',
      child: TextField(
        controller: _nameController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        decoration: InputDecoration(
          hintText: 'e.g. ABC Transport Services',
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _nameError ? Colors.red : Colors.grey,
            ),
          ),
          errorText: _nameError ? 'Transport company name is required' : null,
        ),
        onChanged: (value) {
          setState(() {
            _nameError =
                Validators.validateRequired(value, 'Transport Company Name') !=
                null;
          });
        },
      ),
    );
  }

  Widget _buildAddressField() {
    return Helpers.buildFormField(
      title: 'Address:',
      child: TextField(
        controller: _addressController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Company address',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildGSTNoField() {
    return Helpers.buildFormField(
      title: 'GST No:',
      child: TextField(
        controller: _gstNoController,
        inputFormatters: [
          NoLeadingOrMultipleSpacesFormatter(),
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          UpperCaseTextFormatter(),
        ],
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          hintText: 'e.g. 27AAPFU0939F1ZV',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildMobileNumberField() {
    return Helpers.buildFormField(
      title: 'Mobile Number: *',
      child: TextField(
        controller: _mobileNumberController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          hintText: 'e.g. 9876543210',
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _mobileNumberError ? Colors.red : Colors.grey,
            ),
          ),
          errorText: _mobileNumberError ? _mobileNumberErrorMessage : null,
        ),
        onChanged: (value) {
          setState(() {
            _mobileNumberError = false;
            _mobileNumberErrorMessage = '';
          });
        },
      ),
    );
  }

  Widget _buildContactPersonField() {
    return Helpers.buildFormField(
      title: 'Contact Person Name:',
      child: TextField(
        controller: _contactPersonController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        decoration: const InputDecoration(
          hintText: 'Name of the contact person',
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
      widget.initialTransport != null,
      () async {
        // Validate form
        setState(() {
          _nameError =
              Validators.validateRequired(
                _nameController.text,
                'Transport Company Name',
              ) !=
              null;

          if (_mobileNumberController.text.trim().isEmpty) {
            _mobileNumberError = true;
            _mobileNumberErrorMessage = 'Mobile number is required';
          } else if (!Validators.validateMobileNumber(
            _mobileNumberController.text.trim(),
          )) {
            _mobileNumberError = true;
            _mobileNumberErrorMessage =
                'Please enter a valid 10-digit mobile number starting with 6-9';
          } else if (Validators.mobileNumberExists(
            _mobileNumberController.text.trim(),
            widget.transports, // Use the passed transports list
            excludeItemName: widget.initialTransport?['name'],
          )) {
            _mobileNumberError = true;
            _mobileNumberErrorMessage = 'This mobile number is already in use';
          }
        });

        if (_nameError || _mobileNumberError) {
          return;
        }

        setState(() {
          _isSaving = true;
        });

        Map<String, dynamic> newTransport = {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'gstNo': _gstNoController.text.trim(),
          'mobileNumber': _mobileNumberController.text.trim(),
          'contactPerson': _contactPersonController.text.trim(),
          'status': _statusValue,
        };

        await widget.onSave(newTransport);

        setState(() {
          _isSaving = false;
        });

        Navigator.pop(context);
      },
      saveText: widget.initialTransport == null
          ? 'Save to Master'
          : 'Update to Master',
    );
  }
}
