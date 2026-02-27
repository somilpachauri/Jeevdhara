import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

class NgoRequestDrive extends StatefulWidget {
  const NgoRequestDrive({super.key});

  @override
  State<NgoRequestDrive> createState() => _NgoRequestDriveState();
}

class _NgoRequestDriveState extends State<NgoRequestDrive> {
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController =
      TextEditingController(); // NEW: Controller for the date display

  DateTime? _selectedDate; // NEW: Variable to hold the actual date object
  bool _isLoading = false;

  // NEW: Function to open the calendar
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(
        const Duration(days: 1),
      ), // Default to tomorrow
      firstDate: DateTime.now(), // Prevent selecting past dates
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: darkGreen, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: darkBrown, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Format the date simply as DD/MM/YYYY
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _submitRequest() async {
    // UPDATED: Added a check to ensure a date is selected
    if (_cityController.text.isEmpty ||
        _regionController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in City, Region, and select a Date'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('plantation_requests').add({
        'ngoId': user?.uid,
        'ngoEmail': user?.email,
        'city': _cityController.text.trim(),
        'region': _regionController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'driveDate': Timestamp.fromDate(
          _selectedDate!,
        ), // NEW: Save date to Firestore
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantation drive request submitted!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _regionController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        title: const Text('Request Plantation Drive'),
        backgroundColor: darkGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.park, size: 50, color: darkGreen),
                const SizedBox(height: 16),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City (e.g., Dehradun)',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _regionController,
                  decoration: const InputDecoration(
                    labelText: 'Region/Area (e.g., Rajpur Road)',
                  ),
                ),
                const SizedBox(height: 16),

                // NEW: Read-only TextField that triggers the date picker
                TextField(
                  controller: _dateController,
                  readOnly: true, // Prevents keyboard from popping up
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Select Drive Date',
                    suffixIcon: Icon(Icons.calendar_today, color: darkGreen),
                  ),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Drive Description (Optional)',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Submit Request',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
