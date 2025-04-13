import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../services/shared_pref.dart';
import '../../../utils/validator.dart';
import '../../models/intern.dart';
import '../../utils/constants.dart';
import '../../utils/snackbar_utils.dart';

class AddTaskScreen extends StatefulWidget {
  final String caseNumber;
  final String caseType;
  final String caseId;

  const AddTaskScreen({
    super.key,
    required this.caseNumber,
    required this.caseType,
    required this.caseId,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  String? _advocateName;
  String? _advocateId;
  String? _assignedTo;
  String? _assignDateDisplay = DateFormat('dd/MM/yyyy').format(DateTime.now());
  late String? _expectedEndDateDisplay =
      DateFormat('dd/MM/yyyy').format(DateTime.now());
  String? _assignDateApi = DateFormat('yyyy/MM/dd').format(DateTime.now());
  String? _expectedEndDateApi = DateFormat('yyyy/MM/dd').format(DateTime.now());
  final _taskInstructionController = TextEditingController();
  bool isAssigned = false;
  bool isExpected = false;
  bool isSelected = false;
  bool isLoading = false;

  List<Map<String, String>> _internList = [];
  List<Map<String, String>> _advocateList = [];

  String selectedRole = 'Intern';
  List<dynamic> dropdownItems = [];

  @override
  void initState() {
    super.initState();
    _fetchInternList();
    getUsername();
  }

  Future<void> getUsername() async {
    Intern? user = await SharedPrefService.getUser();
    if (user == null) {
      throw Exception('User not found. Please log in again.');
    }
    setState(() {
      _advocateName = user.name;
      _advocateId = user.id;
    });
  }

  @override
  void dispose() {
    _taskInstructionController.dispose();
    super.dispose();
  }

  Future<void> _fetchInternList() async {
    final url = '$baseUrl/get_interns_list';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _internList = (data['data'] as List)
                .map((intern) => {
                      'id': intern['id'].toString(),
                      'name': intern['name'].toString(),
                    })
                .toList();
          });
        } else {
          _showErrorSnackBar('Failed to load intern list.');
        }
      } else {
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorSnackBar('Failed to fetch data: $error');
    }
  }

  Future<void> _fetchAdvocateList() async {
    final url = '$baseUrl/get_advocate_list';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _advocateList = (data['data'] as List)
                .map((intern) => {
                      'id': intern['id'].toString(),
                      'name': intern['name'].toString(),
                    })
                .toList();
          });
        } else {
          _showErrorSnackBar('Failed to load intern list.');
        }
      } else {
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorSnackBar('Failed to fetch data: $error');
    }
  }

  void _showErrorSnackBar(String message) {
    SnackBarUtils.showErrorSnackBar(context, message);
  }

  Future<void> _selectDate(BuildContext context, bool isEndDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      setState(() {
        final date = DateFormat('dd/MM/yyyy').format(picked);
        final apiDate = DateFormat('yyyy/MM/dd').format(picked);
        if (isEndDate) {
          isExpected = true;
          _expectedEndDateDisplay = date;
          _expectedEndDateApi = apiDate;
        } else {
          isAssigned = true;
          _assignDateDisplay = date;
          _assignDateApi = apiDate;
        }
      });
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _confirmTask() async {
    setState(() {
      isLoading = true;
    });
    if (_advocateName == null ||
        _assignedTo == null ||
        validateTaskInstruction(_taskInstructionController.text) != null) {
      SnackBarUtils.showErrorSnackBar(context, "Please fill out all fields");

      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = '$baseUrl/add_task';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['data'] = jsonEncode({
        "case_id": widget.caseId,
        "alloted_to": _assignedTo,
        "instructions": _taskInstructionController.text
            .trim(), // Trim here before submitting
        "alloted_by": _advocateId,
        "alloted_date": _assignDateApi,
        "expected_end_date": _expectedEndDateApi,
        "remark": "",
      });

      // Debugging logs
      print("Request Payload: ${request.fields['data']}");

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseBody);

      print("API Response: $decodedResponse");

      if (response.statusCode == 200 && decodedResponse['success'] == true) {
        SnackBarUtils.showSuccessSnackBar(context, "Task added successfully!");
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar(
            "Failed to add task: ${decodedResponse['message'] ?? response.statusCode}");
      }
    } catch (error) {
      _showErrorSnackBar("Error adding task: $error");
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.caseNumber);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: const Color(0xFFF3F3F3),
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset('assets/icons/back_arrow.svg'),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: 36, // Slightly smaller for balance
                      fontWeight: FontWeight.w900, // Bolder for emphasis
                      letterSpacing: 1.2, // Add spacing for elegance
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                _buildGeneralInfoCard(),
                const SizedBox(height: 24),
                Text(
                  'Assign To',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // Center buttons
                  children: [
                    _buildRoleButton('Intern'),
                    const SizedBox(width: 12),
                    _buildRoleButton('Advocate'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                    label: 'Assign to',
                    hint: 'Select $selectedRole',
                    value: _assignedTo,
                    items:
                        selectedRole == 'Intern' ? _internList : _advocateList,
                    onChanged: (value) => setState(() => _assignedTo = value),
                    isLabeled: false),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Task Instruction',
                  hint: 'Enter instructions',
                  controller: _taskInstructionController,
                  maxLines: null, // Allow more visible lines
                ),
                const SizedBox(height: 24),
                _buildDateField(
                  label: 'Assign Date',
                  child: Text(
                    _assignDateDisplay ?? 'Select Date',
                    style: TextStyle(
                      color: isAssigned ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _selectDate(context, false),
                ),
                const SizedBox(height: 24),
                _buildDateField(
                  label: 'Expected End Date',
                  child: Text(
                    _expectedEndDateDisplay ?? 'Select Date',
                    style: TextStyle(
                      color: isExpected ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _selectDate(context, true),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _confirmTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      elevation: 4, // Add shadow for depth
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Softer corners
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Enhanced Role Button
  Widget _buildRoleButton(String role) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedRole = role;
            _assignedTo = null;
            role == 'Intern' ? _fetchInternList() : _fetchAdvocateList();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedRole == role ? Colors.black : Colors.white,
          foregroundColor: selectedRole == role ? Colors.white : Colors.black,
          elevation: 2,
          // Subtle shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: Colors.black, width: 1),
        ),
        child: Text(
          role,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

// Enhanced General Info Card
  Widget _buildGeneralInfoCard() {
    final List<MapEntry<String, String>> generalInfo = [
      MapEntry('Case Type', widget.caseType),
      MapEntry('Intern Name', _advocateName ?? 'Loading...'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            'Case No.: ${widget.caseNumber}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Divider(thickness: 1, color: Colors.black54, height: 20),
          ...generalInfo.map((entry) {
            String displayValue = entry.value.isNotEmpty ? entry.value : '-';
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
                  Text(
                    displayValue,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
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

// Enhanced Dropdown Field
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    bool isLabeled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLabeled)
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        if (isLabeled) const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item['id'],
                      child: Text(item['name']!),
                    ))
                .toList(),
            onChanged: onChanged,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ],
    );
  }

// Enhanced Text Field
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool readOnly = false,
    int? maxLines = 1,
    bool isLabeled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLabeled)
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        if (isLabeled) const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              fillColor: Colors.white,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

// Enhanced Date Field
  Widget _buildDateField({
    required String label,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black54, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                child,
                const Spacer(),
                Icon(Icons.calendar_today, color: Colors.black54, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
