import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/Modules/Purchase/features/services/party_service.dart';
import 'package:purchase_app/Modules/Purchase/features/widgets/add_party_dialog.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';

class PartiesPage extends StatefulWidget {
  const PartiesPage({Key? key}) : super(key: key);

  @override
  _PartiesPageState createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  List<Map<String, dynamic>> parties = [];
  List<Map<String, dynamic>> filteredParties = [];
  List<String> agents = [];
  List<String> transports = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadParties();
    _searchController.addListener(_filterParties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParties() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Load parties
      parties = await PartyService().getParties();

      // Load agents
      final agentsData = box.get('agents');
      if (agentsData != null && agentsData is List) {
        for (var agent in agentsData) {
          if (agent is Map) {
            agents.add(agent['name']?.toString() ?? '');
          } else if (agent is String) {
            agents.add(agent);
          }
        }
      }

      // Load transports
      final transportsData = box.get('transports');
      if (transportsData != null && transportsData is List) {
        for (var transport in transportsData) {
          if (transport is Map) {
            transports.add(transport['name']?.toString() ?? '');
          } else if (transport is String) {
            transports.add(transport);
          }
        }
      }

      setState(() {
        filteredParties = List.from(parties);
        _isLoading = false;
      });

      print(
        'Loaded ${parties.length} parties, ${agents.length} agents, and ${transports.length} transports',
      );
    } catch (e) {
      print('Error loading parties: $e');
      setState(() {
        parties = [];
        filteredParties = [];
        agents = [];
        transports = [];
        _isLoading = false;
      });
    }
  }

  void _filterParties() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredParties = parties.where((party) {
        // Ensure name and code are strings before calling toLowerCase
        String name = party['name'] is String
            ? party['name']
            : party['name']?.toString() ?? '';

        String code = party['code'] is String
            ? party['code']
            : party['code']?.toString() ?? '';

        return name.toLowerCase().contains(query) ||
            code.toLowerCase().contains(query);
      }).toList();
    });
  }

  // Check if a party is mapped to any order
  bool _isPartyMapped(String partyName) {
    try {
      if (!Hive.isBoxOpen('orders')) {
        Hive.openBox('orders');
      }

      final box = Hive.box('orders');
      final ordersData = box.values.toList();

      for (var order in ordersData) {
        if (order is Map && order['party'] == partyName) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking if party is mapped: $e');
      return false;
    }
  }

  void _showAddNewPartyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddPartyDialog(
          isEditMode: false,
          agents: agents,
          transports: transports,
        );
      },
    ).then((result) {
      if (result != null) {
        // Add party using service
        PartyService()
            .addParty(
              result['name'],
              result['code'],
              partyType: result['partyType'],
              agent: result['agent'],
              mobileNumbers: result['mobileNumbers'],
              email: result['email'],
              address: result['address'],
              state: result['state'],
              district: result['district'],
              gstNo: result['gstNo'],
              bankName: result['bankName'],
              accountNo: result['accountNo'],
              ifscCode: result['ifscCode'],
              branchName: result['branchName'],
              accountHolderName: result['accountHolderName'],
              transport: result['transport'],
              status: result['status'],
            )
            .then((_) {
              // Reload parties
              _loadParties();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.party} ${AppStrings.addedSuccessfully}',
                  ),
                  backgroundColor: AppColors.complete,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.errorAdding} ${AppStrings.party.toLowerCase()}: $error',
                  ),
                  backgroundColor: AppColors.pending,
                ),
              );
            });
      }
    });
  }

  void _showEditPartyDialog(Map<String, dynamic> party, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AddPartyDialog(
          isEditMode: true,
          initialName: party['name'],
          initialCode: party['code'],
          initialPartyType: party['partyType'],
          initialAgent: party['agent'],
          initialMobileNumbers: party['mobileNumbers'],
          initialEmail: party['email'],
          initialAddress: party['address'],
          initialState: party['state'],
          initialDistrict: party['district'],
          initialGstNo: party['gstNo'],
          initialBankName: party['bankName'],
          initialAccountNo: party['accountNo'],
          initialIfscCode: party['ifscCode'],
          initialBranchName: party['branchName'],
          initialAccountHolderName: party['accountHolderName'],
          initialTransport: party['transport'],
          initialStatus: party['status'],
          agents: agents,
          transports: transports,
        );
      },
    ).then((result) {
      if (result != null) {
        // Update party using service
        PartyService()
            .updateParty(
              party['name'],
              party['code'],
              result['name'],
              result['code'],
              partyType: result['partyType'],
              agent: result['agent'],
              mobileNumbers: result['mobileNumbers'],
              email: result['email'],
              address: result['address'],
              state: result['state'],
              district: result['district'],
              gstNo: result['gstNo'],
              bankName: result['bankName'],
              accountNo: result['accountNo'],
              ifscCode: result['ifscCode'],
              branchName: result['branchName'],
              accountHolderName: result['accountHolderName'],
              transport: result['transport'],
              status: result['status'],
              isMapped: party['isMapped'],
            )
            .then((_) {
              // Reload parties
              _loadParties();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.party} ${AppStrings.updatedSuccessfully}',
                  ),
                  backgroundColor: AppColors.complete,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.errorUpdating} ${AppStrings.party.toLowerCase()}: $error',
                  ),
                  backgroundColor: AppColors.pending,
                ),
              );
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Parties'),
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
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
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
              icon: const Icon(
                Icons.add,
                color: Color(0xFF2563EB), // Blue color for the + icon
                size: 24,
              ),
              onPressed: _showAddNewPartyDialog,
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(
        scaffoldKey: _scaffoldKey,
        primaryColor: const Color(0xFF2563EB),
        appTitle: 'Hyatt Purchase',
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Parties',
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
                ),

                // Parties list
                Expanded(
                  child: filteredParties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                parties.isEmpty
                                    ? 'No parties found'
                                    : 'No matching parties',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                parties.isEmpty
                                    ? 'Add parties using + button'
                                    : 'Try a different search term',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadParties,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredParties.length,
                            itemBuilder: (context, index) {
                              final party = filteredParties[index];
                              final isMapped = party['isMapped'] ?? false;

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
                                      Icons.business,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    party['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                        party,
                                        isMapped,
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    _showEditPartyDialog(party, index);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showDeleteConfirmationDialog(
    Map<String, dynamic> party,
    bool isMapped,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: isMapped
              ? const Text(
                  'This party is already mapped with orders and cannot be deleted.',
                )
              : Text(
                  'Are you sure you want to delete "${party['name']} (${party['code']})"?',
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
            if (!isMapped)
              TextButton(
                onPressed: () async {
                  // Delete's party using the service
                  PartyService()
                      .deleteParty(party['name'], party['code'])
                      .then((_) {
                        // Reload the parties
                        _loadParties();

                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Party deleted successfully'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      })
                      .catchError((error) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting party: $error'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      });
                },
                child: const Text('Delete'),
              ),
          ],
        );
      },
    );
  }
}
