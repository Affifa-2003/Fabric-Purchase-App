import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/home_page.dart';
import 'utils/input_formatters.dart';
// Add this import at the top of your file if you're using the direct navigation option
import 'purchase_list_page.dart';

class OrderFormFinishPage extends StatefulWidget {
  final String partyName;
  final int totalDesigns;
  final int totalChoices;
  final int totalMeters;

  const OrderFormFinishPage({
    Key? key,
    required this.partyName,
    required this.totalDesigns,
    required this.totalChoices,
    required this.totalMeters,
  }) : super(key: key);

  @override
  _OrderFormFinishPageState createState() => _OrderFormFinishPageState();
}

class _OrderFormFinishPageState extends State<OrderFormFinishPage> {
  final Color primaryColor = const Color(0xFF2563EB);
  final Color successColor = const Color(0xFF10B981);
  String orderFormFromNo = '';
  String orderFormToNo = '';
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _fromNoController = TextEditingController();
  final TextEditingController _toNoController = TextEditingController();
  
  // Add image picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _orderFormPhoto;
  
  // Hive boxes
  late Box appDataBox;
  late Box orderFormsBox;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      // Get the boxes (they should already be open from main.dart)
      appDataBox = Hive.box('appData');
      
      // Check if orderForms box is open, if not open it
      if (!Hive.isBoxOpen('orderForms')) {
        orderFormsBox = await Hive.openBox('orderForms');
      } else {
        orderFormsBox = Hive.box('orderForms');
      }
      
      print('Hive boxes are open: ${Hive.isBoxOpen('appData')} and ${Hive.isBoxOpen('orderForms')}');
    } catch (e) {
      print('Error initializing Hive: $e');
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _fromNoController.dispose();
    _toNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Order Form & Finish',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Capture Order Form Photo Section
              _buildCapturePhotoSection(),
              const SizedBox(height: 20),

              // Order Form NO Section
              _buildOrderFormNoSection(),
              const SizedBox(height: 20),

              // Summary Section
              _buildSummarySection(),
              const SizedBox(height: 20),

              // Comments Section
              _buildCommentsSection(),
              const SizedBox(height: 20),

              // Finish Button
              _buildFinishButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Modified _buildCapturePhotoSection with camera functionality
  Widget _buildCapturePhotoSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.assignment,
                size: 48,
                color: Color(0xFFE97450),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Capture Order Form Photo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                // Open camera to capture photo
                final XFile? pickedFile = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.rear,
                );
                
                if (pickedFile != null) {
                  setState(() {
                    _orderFormPhoto = File(pickedFile.path);
                  });
                }
              },
              child: Container(
                width: double.infinity,
                height: 200, // Fixed height for the image container
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFFF9FAFB),
                ),
                child: _orderFormPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          _orderFormPhoto!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Modern camera icon with gradient background (same as textile_details.dart)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4F46E5),
                                  const Color(0xFF2563EB),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tap to Capture',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ready to capture',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderFormNoSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Form NO:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromNoController,
                    keyboardType: TextInputType.number, // Added numeric keyboard
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      NoLeadingOrMultipleSpacesFormatter(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        orderFormFromNo = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'From',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _toNoController,
                    keyboardType: TextInputType.number, // Added numeric keyboard
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      NoLeadingOrMultipleSpacesFormatter(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        orderFormToNo = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'To',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDBEAFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Designs', widget.totalDesigns.toString()),
                _buildSummaryItem('Choices', widget.totalChoices.toString()),
                _buildSummaryItem('Meters', widget.totalMeters.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment, size: 18, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                const Text(
                  'Comments for Office:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentsController,
              inputFormatters: [
                NoLeadingOrMultipleSpacesFormatter(),
              ],
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Add notes for office team...\ne.g., Party wants urgent delivery, Check design 5...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFD1D5DB),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This comment travels to backend and helps the office team process the order.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Validate form
          if (orderFormFromNo.isEmpty || orderFormToNo.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please fill in Order Form NO fields'),
              ),
            );
            return;
          }

          // Save data to Hive
          _saveOrderFormToHive();

          // Show success message and navigate
          _showSuccessMessageAndNavigate();
        },
        icon: const Icon(Icons.check_circle, size: 20),
        label: const Text('FINISH & Create Dummy PO'),
        style: ElevatedButton.styleFrom(
          backgroundColor: successColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Future<void> _saveOrderFormToHive() async {
    try {
      // Get the order form photo path if it exists
      String? photoPath;
      if (_orderFormPhoto != null) {
        photoPath = _orderFormPhoto!.path;
      }

      // Create a map with all the order form data
      final orderFormData = {
        'partyName': widget.partyName,
        'orderFormFromNo': orderFormFromNo,
        'orderFormToNo': orderFormToNo,
        'comments': _commentsController.text,
        'photoPath': photoPath,
        'totalDesigns': widget.totalDesigns,
        'totalChoices': widget.totalChoices,
        'totalMeters': widget.totalMeters,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Generate a unique key for this order form
      final orderFormKey = 'orderForm_${widget.partyName}_${DateTime.now().millisecondsSinceEpoch}';

      // Save the order form data to Hive
      await orderFormsBox.put(orderFormKey, orderFormData);
      await orderFormsBox.flush();

      print('Order form saved to Hive with key: $orderFormKey');
      print('Order form data: $orderFormData');
    } catch (e) {
      print('Error saving order form to Hive: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving order form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessMessageAndNavigate() {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dummy PO Created! Order sent to office for processing.'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    // Navigate to purchase_details_page.dart after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      // Try different navigation approaches
      try {
        // Option 1: Try using pushReplacementNamed
        Navigator.pushReplacementNamed(
          context,
          '/home_page',
        );
      } catch (e) {
        print('Error with pushReplacementNamed: $e');
        
        // Option 2: Try using pushAndRemoveUntil
        try {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home_page',
            (route) => false,
          );
        } catch (e2) {
          print('Error with pushNamedAndRemoveUntil: $e2');
          
          // Option 3: Try direct navigation using MaterialPageRoute
          try {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          } catch (e3) {
            print('Error with direct navigation: $e3');
          }
        }
      }
    });
  }
}

