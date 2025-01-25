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
        title: const Text('Remark'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 30),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200], // Light grey background for read-only feel
          borderRadius: BorderRadius.circular(8),
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
        child: ListTile(
          title: Text(
            '${_remarkDate.day.toString().padLeft(2, '0')}/${_remarkDate.month.toString().padLeft(2, '0')}/${_remarkDate.year}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () => _selectDate(_remarkDate),
        ),
      ),
    );
  }

  Widget _buildDocumentBoxField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
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

  Widget _buildStatusRadioButtons() {
    return Column(
      children: [
        RadioListTile(
          title: const Text('Pending'),
          activeColor: Colors.black,
          value: 'Pending',
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
          value: 'Completed',
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

  Future<void> _uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _documentPath = result.files.single.path ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final submittedData = {
        "task_id": widget.task_id,
        "remark": _remarkController.text,
        "remark_date":
            "${_remarkDate.year}/${_remarkDate.month.toString().padLeft(2, '0')}/${_remarkDate.day.toString().padLeft(2, '0')}",
        "stage_id": widget.stage_id,
        "case_id": widget.case_id,
        "intern_id": _internId,
        "status": _status, // Add status field here
      };

      print("Submitted Data: $submittedData"); // Debugging log

      try {
        final uri = Uri.parse(
            'https://pragmanxt.com/case_sync/services/intern/v1/index.php/add_task_remark');
        final request = http.MultipartRequest('POST', uri);
        request.fields['data'] = json.encode(submittedData);

        // Attach the document if uploaded
        if (_documentPath.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath(
            'task_image',
            _documentPath,
          ));
        }

        // Send the request
        final response = await request.send();
        print("Response Status Code: ${response.statusCode}");
        print("Response Headers: ${response.headers}");

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final jsonResponse = json.decode(responseBody);
          print("Response Body: $responseBody");

          if (jsonResponse['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(jsonResponse['message']),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            throw Exception(jsonResponse['message']);
          }
        } else {
          throw Exception('Failed to submit remark');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        print("$e");
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
