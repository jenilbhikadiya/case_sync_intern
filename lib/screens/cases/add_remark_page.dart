import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/task_item_list.dart';
import '../../services/shared_pref.dart';

class AddRemarkPage extends StatefulWidget {
  final TaskItem taskItem;
  final String task_id;
  final String stage_id;
  final String case_id;

  const AddRemarkPage(
      {super.key,
      required this.taskItem,
      required this.stage_id,
      required this.task_id,
      required this.case_id});

  @override
  AddRemarkPageState createState() => AddRemarkPageState();
}

class AddRemarkPageState extends State<AddRemarkPage> {
  final _formKey = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  final _currentStageController = TextEditingController();
  String _documentPath = '';
  DateTime _remarkDate = DateTime.now();
  String _status = 'Pending';
  bool _isSubmitting = false;
  String? _internId;

  @override
  void initState() {
    super.initState();
    _currentStageController.text = widget.taskItem.stage;
    _fetchInternId();
  }

  Future<void> _fetchInternId() async {
    final userData = await SharedPrefService.getUser();
    if (userData != null && userData.id.isNotEmpty) {
      setState(() {
        _internId = userData.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Remark',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              _buildFieldTitle('Current Stage'),
              _buildCurrentStageField(),
              _buildFieldTitle('Remark'),
              _buildTextField(
                controller: _remarkController,
                inputType: TextInputType.text,
                label: 'Enter remark',
              ),
              _buildFieldTitle('Remark Date'),
              _buildRemarkBoxField(),
              _buildFieldTitle('Document'),
              _buildDocumentBoxField(),
              _buildFieldTitle('Status'),
              _buildStatusRadioButtons(),
              const SizedBox(height: 10),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType inputType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: inputType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCurrentStageField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text(
          _currentStageController.text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildRemarkBoxField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildOutlinedBoxField(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_remarkDate.day.toString().padLeft(2, '0')}/${_remarkDate.month.toString().padLeft(2, '0')}/${_remarkDate.year}',
              style: const TextStyle(fontSize: 16),
            ),
            GestureDetector(
              onTap: () => _selectDate(_remarkDate),
              child: const Icon(Icons.calendar_today),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentBoxField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _buildOutlinedBoxField(
        child: Row(
          children: [
            Expanded(
              child: Text(
                _documentPath.isEmpty
                    ? 'Upload Document'
                    : 'Document: ${_documentPath.split('/').last}',
              ),
            ),
            GestureDetector(
              onTap: _uploadDocument,
              child: const Icon(Icons.upload_file),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedBoxField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }

  Widget _buildStatusRadioButtons() {
    return Column(
      children: [
        RadioListTile(
          title: const Text('Pending'),
          activeColor: Colors.black,
          value: 'pending',
          groupValue: _status,
          onChanged: (value) {
            setState(() {
              _status = value!;
            });
          },
        ),
        RadioListTile(
          title: const Text('Completed'),
          activeColor: Colors.black,
          value: 'completed',
          groupValue: _status,
          onChanged: (value) {
            setState(() {
              _status = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Submit'),
      ),
    );
  }

  Future<void> _selectDate(DateTime date) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2021),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != date) {
      setState(() {
        _remarkDate = picked;
      });
    }
  }

  Future<void> _uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _documentPath = result.files.single.path ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate an API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task Added Successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isSubmitting = false;
      });

      // Navigate back to the task page
      Navigator.pop(context, true);
    }
  }
}
