import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:intern_side/utils/constants.dart';
import 'package:intl/intl.dart';

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

  List<File> _selectedFiles = [];
  DateTime _remarkDate = DateTime.now();
  String _status = 'pending';
  bool _isSubmitting = false;
  String? _internId;

  @override
  void initState() {
    super.initState();
    _currentStageController.text = widget.taskItem.stage;
    _status = 'pending';
    _fetchInternId();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _currentStageController.dispose();
    super.dispose();
  }

  Future<void> _fetchInternId() async {
    final userData = await SharedPrefService.getUser();
    if (mounted) {
      if (userData != null && userData.id.isNotEmpty) {
        setState(() {
          _internId = userData.id;
        });
      } else {
        print("Error: Could not fetch intern ID.");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error fetching user data. Cannot submit.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_internId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User information not loaded. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final trimmedRemark = _remarkController.text.trim();

    final url = Uri.parse('$baseUrl/add_task_remark');

    try {
      var request = http.MultipartRequest('POST', url);

      final jsonData = jsonEncode({
        "task_id": widget.task_id,
        "remark": trimmedRemark,
        "remark_date": DateFormat('yyyy/MM/dd').format(_remarkDate),
        "stage_id": widget.stage_id,
        "case_id": widget.case_id,
        "intern_id": _internId,
        "status": _status
      });
      request.fields['data'] = jsonData;

      print("JSON Data Sent: $jsonData");

      if (_selectedFiles.isNotEmpty) {
        print("Uploading ${_selectedFiles.length} files...");
        for (int i = 0; i < _selectedFiles.length; i++) {
          File file = _selectedFiles[i];
          if (await file.exists()) {
            try {
              request.files.add(
                await http.MultipartFile.fromPath(
                  'task_image',
                  file.path,
                ),
              );
              print("Added file ${i + 1}: ${file.path}");
            } catch (e) {
              print("Error adding file ${file.path}: $e");

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Error preparing file ${file.path.split('/').last} for upload.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } else {
            print("File not found, skipping: ${file.path}");

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File not found: ${file.path.split('/').last}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      } else {
        print("No documents selected for upload.");
      }

      print("Sending multipart request to $url");
      var response = await request.send();

      var responseBody = await response.stream.bytesToString();
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: $responseBody");

      if (mounted) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task Remark Added Successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          String errorMessage = 'Failed to add task remark.';
          try {
            final decodedResponse = jsonDecode(responseBody);
            errorMessage =
                decodedResponse['message'] ?? 'Error: ${response.statusCode}';
          } catch (_) {
            errorMessage =
                'Failed to add task remark. Status: ${response.statusCode}. Response: $responseBody';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stacktrace) {
      print("Error submitting form: $e");
      print("Stacktrace: $stacktrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickDocuments() async {
    if (_isSubmitting) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.paths
              .where((path) => path != null)
              .map((path) => File(path!)));
        });
        print("Selected Files: ${_selectedFiles.length}");
      } else {
        print("File picking cancelled.");
      }
    } catch (e) {
      print("Error picking files: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file(s): $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text("Add Remark", style: TextStyle(color: Colors.black)),
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
              _buildGeneralInfoCard(),
              const SizedBox(height: 20),
              _buildFieldTitle('Remark *'),
              _buildTextField(
                controller: _remarkController,
                isMultiline: true,
                inputType: TextInputType.multiline,
                label: 'Enter remark',
                isRequired: true,
              ),
              _buildFieldTitle('Remark Date'),
              _buildRemarkDateField(),
              _buildFieldTitle('Attach Documents'),
              _buildDocumentSelectionArea(),
              _buildFieldTitle('Status *'),
              _buildStatusRadioButtons(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    String caseNoDisplay =
        widget.taskItem.caseNo.isNotEmpty ? widget.taskItem.caseNo : 'N/A';
    String allotedBy = widget.taskItem.allotedBy.isNotEmpty
        ? widget.taskItem.allotedBy
        : 'N/A';
    String stageName =
        widget.taskItem.stage.isNotEmpty ? widget.taskItem.stage : 'N/A';

    final List<MapEntry<String, String>> generalInfo = [
      MapEntry('Allotted By', allotedBy),
      MapEntry('Current Stage', stageName),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Case No.: $caseNoDisplay',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(thickness: 1, color: Colors.black26, height: 24),
          ...generalInfo.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType inputType,
    bool isMultiline = false,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(25),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          fillColor: Colors.white,
          filled: true,
        ),
        keyboardType: inputType,
        maxLines: isMultiline ? 4 : 1,
        minLines: isMultiline ? 2 : 1,
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
        textInputAction:
            isMultiline ? TextInputAction.newline : TextInputAction.next,
      ),
    );
  }

  Widget _buildRemarkDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildOutlinedBoxField(
        child: InkWell(
          onTap: _isSubmitting ? null : () => _selectDate(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(_remarkDate),
                style: const TextStyle(fontSize: 16),
              ),
              Icon(Icons.calendar_today,
                  color: _isSubmitting ? Colors.grey : Colors.black54),
            ],
          ),
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

  Widget _buildDocumentSelectionArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          // Increase icon size slightly
          icon: const Icon(Icons.attach_file,
              size: 20), // Changed size from 18 to 20
          // Increase label font size slightly
          label: const Text(
            "Select Documents",
            style: TextStyle(
                fontSize: 16), // Added explicit font size (adjust as needed)
          ),
          onPressed: _isSubmitting ? null : _pickDocuments,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            side: const BorderSide(
                color: Colors.black, width: 1), // Keep border consistent
            elevation: 0,
            // Increase vertical padding significantly to make the button taller
            padding: const EdgeInsets.symmetric(
              horizontal: 16, // Keep horizontal padding or adjust as needed
              vertical:
                  16, // Increased vertical padding from 10 to 16 (adjust as needed)
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Keep consistent shape
            ),
            minimumSize:
                const Size(150, 50), // Optional: Enforce a minimum width/height
          ),
        ),
        const SizedBox(height: 10),
        // Rest of the widget remains the same...
        if (_selectedFiles.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              // Keep the updated consistent style for the list container
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                final fileName = file.path.split('/').last;
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined,
                      size: 20, color: Colors.black54),
                  title: Text(
                    fileName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close,
                        size: 20,
                        color: _isSubmitting ? Colors.grey : Colors.redAccent),
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _selectedFiles.removeAt(index);
                            });
                          },
                    tooltip: "Remove",
                    splashRadius: 20,
                  ),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                );
              },
            ),
          )
        else if (!_isSubmitting)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              "No documents selected.",
              style: TextStyle(
                  color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStatusRadioButtons() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Pending'),
          activeColor: Colors.black,
          value: 'pending',
          groupValue: _status,
          onChanged: _isSubmitting
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Completed'),
          activeColor: Colors.black,
          value: 'completed',
          groupValue: _status,
          onChanged: _isSubmitting
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
          dense: true,
          contentPadding: EdgeInsets.zero,
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
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24.0,
                width: 24.0,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text('Submit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _remarkDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _remarkDate) {
      setState(() {
        _remarkDate = picked;
      });
    }
  }
}
