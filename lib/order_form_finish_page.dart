import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  
  // Add image picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _orderFormPhoto;

  @override
  void dispose() {
    _commentsController.dispose();
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
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 32,
                            color: Color(0xFFC5CAD1),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to Capture',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
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

          // Show success dialog
          _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF10B981),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Order Created Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order Form: ${orderFormFromNo} to ${orderFormToNo}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to previous page
                      Navigator.pop(context); // Go back to home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}