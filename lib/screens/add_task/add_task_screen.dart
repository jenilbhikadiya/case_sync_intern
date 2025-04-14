import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Assuming these paths are correct relative to AddTaskScreen.dart
import '../../../services/shared_pref.dart';
import '../../../utils/validator.dart'; // Make sure validateTaskInstruction exists here
import '../../components/basicUIcomponent.dart';
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
  String? _assignedToId; // Changed to store ID
  String? _assignDateDisplay = DateFormat('dd/MM/yyyy').format(DateTime.now());
  late String? _expectedEndDateDisplay =
      DateFormat('dd/MM/yyyy').format(DateTime.now());
  String? _assignDateApi = DateFormat('yyyy/MM/dd').format(DateTime.now());
  String? _expectedEndDateApi = DateFormat('yyyy/MM/dd').format(DateTime.now());
  final _taskInstructionController = TextEditingController();
  bool isAssigned = false;
  bool isExpected = false;
  // bool isSelected = false; // isSelected wasn't used, removed for clarity
  bool isLoading = false;

  List<Map<String, String>> _internList = [];
  List<Map<String, String>> _advocateList = [];

  String selectedRole = 'Intern'; // Default role
  // List<dynamic> dropdownItems = []; // Not used, removed for clarity

  @override
  void initState() {
    super.initState();
    // Print received values on init for debugging
    print("--- AddTaskScreen initState ---");
    print("Received Case ID: ${widget.caseId}");
    print("Received Case Number: ${widget.caseNumber}");
    print("Received Case Type: ${widget.caseType}");
    print("-----------------------------");

    _fetchInternList(); // Fetch initial list based on default role
    _fetchAdvocateList(); // Fetch advocates too, in case user switches
    _loadUserData(); // Load user data
  }

  // Renamed from getUsername for clarity
  Future<void> _loadUserData() async {
    try {
      Intern? user = await SharedPrefService.getUser();
      if (user != null && user.id.isNotEmpty && user.name.isNotEmpty) {
        if (mounted) {
          // Check if widget is still in the tree
          setState(() {
            _advocateName = user.name;
            _advocateId = user.id;
          });
        }
      } else {
        // Handle case where user data is missing or incomplete
        print('User data not found or incomplete in SharedPreferences.');
        if (mounted) {
          _showErrorSnackBar('User data not found. Please log in again.');
          // Optionally navigate back or show a login prompt
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        _showErrorSnackBar('Error loading user data: $e');
      }
    }
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
      if (!mounted) return; // Check if widget is still mounted

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          setState(() {
            _internList = (data['data'] as List)
                .map((intern) => {
                      'id': intern['id']?.toString() ?? '', // Safe access
                      'name': intern['name']?.toString() ??
                          'Unnamed Intern', // Safe access
                    })
                .where((item) =>
                    item['id']!.isNotEmpty &&
                    item['name']!.isNotEmpty) // Filter out invalid entries
                .toList();
          });
        } else {
          _showErrorSnackBar(
              'Failed to load intern list: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        _showErrorSnackBar(
            'Server error fetching interns: ${response.statusCode}');
      }
    } catch (error) {
      print("Error fetching interns: $error");
      if (mounted) _showErrorSnackBar('Error fetching intern list.');
    }
  }

  Future<void> _fetchAdvocateList() async {
    final url = '$baseUrl/get_advocate_list';
    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return; // Check if widget is still mounted

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          setState(() {
            _advocateList = (data['data'] as List)
                .map((advocate) => {
                      'id': advocate['id']?.toString() ?? '', // Safe access
                      'name': advocate['name']?.toString() ??
                          'Unnamed Advocate', // Safe access
                    })
                .where((item) =>
                    item['id']!.isNotEmpty &&
                    item['name']!.isNotEmpty) // Filter out invalid entries
                .toList();
          });
        } else {
          _showErrorSnackBar(
              'Failed to load advocate list: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        _showErrorSnackBar(
            'Server error fetching advocates: ${response.statusCode}');
      }
    } catch (error) {
      print("Error fetching advocates: $error");
      if (mounted) _showErrorSnackBar('Error fetching advocate list.');
    }
  }

  void _showErrorSnackBar(String message) {
    // Ensure context is valid before showing snackbar
    if (mounted && context.findRenderObject() != null) {
      SnackBarUtils.showErrorSnackBar(context, message);
    } else {
      print("SnackBar Error: Context not available. Message: $message");
    }
  }

  Future<void> _selectDate(BuildContext context, bool isEndDate) async {
    final DateTime initial = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000), // Adjust range as needed
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      // Check mounted after await
      setState(() {
        final dateDisplay = DateFormat('dd/MM/yyyy').format(picked);
        final apiDate = DateFormat('yyyy/MM/dd').format(picked);
        if (isEndDate) {
          isExpected = true;
          _expectedEndDateDisplay = dateDisplay;
          _expectedEndDateApi = apiDate;
        } else {
          isAssigned = true;
          _assignDateDisplay = dateDisplay;
          _assignDateApi = apiDate;
        }
      });
      // Consider removing this, date picker usually handles focus.
      // FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _confirmTask() async {
    // --- Input Validation ---
    final instruction = _taskInstructionController.text.trim();
    String? instructionError =
        validateTaskInstruction(instruction); // Assuming this validator exists

    if (_advocateId == null || _advocateId!.isEmpty) {
      _showErrorSnackBar("Your user ID is missing. Please re-login.");
      return;
    }
    if (_assignedToId == null || _assignedToId!.isEmpty) {
      _showErrorSnackBar("Please select who to assign the task to.");
      return;
    }
    if (instructionError != null) {
      _showErrorSnackBar(instructionError); // Show specific instruction error
      return;
    }
    if (_assignDateApi == null || _expectedEndDateApi == null) {
      _showErrorSnackBar("Please select both assign and expected end dates.");
      return;
    }
    // Potentially add date validation (e.g., end date must be after assign date)

    // --- Prepare Request ---
    setState(() {
      isLoading = true;
    });

    final url = '$baseUrl/add_task';
    final requestBody = {
      "case_id": widget.caseId, // Already required in constructor
      "alloted_to": _assignedToId, // Use the selected ID
      "instructions": instruction, // Use trimmed instruction
      "alloted_by": _advocateId, // Current user's ID
      "alloted_date": _assignDateApi,
      "expected_end_date": _expectedEndDateApi,
      "remark": "", // Assuming remark is optional on creation
    };

    print("--- Sending Add Task Request ---");
    print("URL: $url");
    print("Payload: ${jsonEncode(requestBody)}");
    print("------------------------------");

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      // Send data as fields, not nested under 'data' unless API requires it
      request.fields['data'] = jsonEncode(requestBody);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (!mounted) return; // Check if mounted after await

      print("API Raw Response: $responseBody");
      final decodedResponse = jsonDecode(responseBody);
      print("API Decoded Response: $decodedResponse");

      if (response.statusCode == 200 && decodedResponse['success'] == true) {
        SnackBarUtils.showSuccessSnackBar(
            context, decodedResponse['message'] ?? "Task added successfully!");
        Navigator.pop(context, true); // Pass true to indicate success
      } else {
        _showErrorSnackBar(
            "Failed to add task: ${decodedResponse['message'] ?? 'Server error ${response.statusCode}'}");
      }
    } catch (error) {
      print("Error adding task: $error");
      if (mounted) _showErrorSnackBar("An error occurred: $error");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug print inside build to see values on every rebuild
    // print("--- AddTaskScreen build ---");
    // print("Widget Case Number: ${widget.caseNumber}");
    // print("Widget Case Type: ${widget.caseType}");
    // print("-------------------------");

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: AppBar(
          surfaceTintColor: Colors.transparent, // Or Colors.white
          backgroundColor: const Color(0xFFF3F3F3),
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/back_arrow.svg',
              width: 24, // Adjust size if needed
              height: 24,
              colorFilter: ColorFilter.mode(
                  Colors.black, BlendMode.srcIn), // Ensure visibility
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
          ),
          // Optional: Add Title back if desired
          // title: const Text(
          //   'Add Task',
          //   style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          // ),
          // centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title moved here for better spacing control
                const Center(
                  child: Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: 32, // Adjusted size
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      height: 1.2,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                _buildGeneralInfoCard(), // Uses widget.caseNumber and widget.caseType
                const SizedBox(height: 24),
                const Text(
                  // Use const for static text
                  'Assign To',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  // Removed MainAxisAlignment.spaceBetween to let Expanded work
                  children: [
                    _buildRoleButton('Intern'), // First button
                    const SizedBox(width: 12), // Spacing
                    _buildRoleButton('Advocate'), // Second button
                  ],
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                    // No label needed here as 'Assign To' is above
                    hint: 'Select $selectedRole',
                    value: _assignedToId, // Bind to the ID
                    items:
                        selectedRole == 'Intern' ? _internList : _advocateList,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _assignedToId = value);
                      }
                    },
                    isLabeled: false // Label is handled above
                    ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Task Instruction',
                  hint:
                      'Enter instructions for the task', // More descriptive hint
                  controller: _taskInstructionController,
                  maxLines: 5, // Allow more lines for instruction
                  isLabeled: true, // Keep label for this field
                ),
                const SizedBox(height: 24),
                _buildDateField(
                  label: 'Assign Date',
                  child: Text(
                    _assignDateDisplay ?? 'Select Date',
                    style: TextStyle(
                      // Use black if date is assigned (isAssigned=true), grey otherwise
                      color: isAssigned ? Colors.black : Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _selectDate(context, false), // isEndDate = false
                ),
                const SizedBox(height: 24),
                _buildDateField(
                  label: 'Expected End Date',
                  child: Text(
                    _expectedEndDateDisplay ?? 'Select Date',
                    style: TextStyle(
                      // Use black if date is expected (isExpected=true), grey otherwise
                      color: isExpected ? Colors.black : Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _selectDate(context, true), // isEndDate = true
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : _confirmTask, // Disable while loading
                    style:
                        AppTheme.elevatedButtonStyle, // Use shared theme style
                    // ElevatedButton.styleFrom(
                    //   backgroundColor: Colors.black,
                    //   disabledBackgroundColor: Colors.grey[400], // Visual feedback when disabled
                    //   elevation: 4,
                    //   shape: RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    // ),
                    child: isLoading
                        ? const SizedBox(
                            // Constrain size of indicator
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            'Confirm Task', // More specific text
                            style: AppTheme
                                .buttonTextStyle, // Use shared theme style
                            // style: TextStyle(
                            //   fontSize: 18,
                            //   fontWeight: FontWeight.w600,
                            //   color: Colors.white,
                            // ),
                          ),
                  ),
                ),
                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Reusable Widgets ---

  Widget _buildRoleButton(String role) {
    bool isActive = selectedRole == role;
    return Expanded(
      // Make buttons fill available space equally
      child: ElevatedButton(
        onPressed: () {
          if (selectedRole != role) {
            // Only update state if role changes
            setState(() {
              selectedRole = role;
              _assignedToId = null; // Reset selection when role changes
              // Fetching lists is done in initState now, no need here unless lazy loading
              // role == 'Intern' ? _fetchInternList() : _fetchAdvocateList();
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.black : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.black,
          elevation: isActive ? 4 : 1, // More emphasis on active
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isActive
                    ? Colors.black
                    : Colors.grey[400]!, // Border color change
                width: 1.5, // Slightly thicker border
              )),
          padding: const EdgeInsets.symmetric(vertical: 14), // Adjusted padding
        ),
        child: Text(
          role,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    // Handle potential null or empty values gracefully
    String caseNoDisplay =
        widget.caseNumber.isNotEmpty ? widget.caseNumber : 'N/A';
    String caseTypeDisplay =
        widget.caseType.isNotEmpty ? widget.caseType : 'N/A';
    String advocateNameDisplay =
        _advocateName?.isNotEmpty ?? false ? _advocateName! : 'Loading...';

    final List<MapEntry<String, String>> generalInfo = [
      MapEntry('Case Type', caseTypeDisplay),
      MapEntry('Allotted By', advocateNameDisplay), // Changed label for clarity
    ];

    return Container(
      width: double.infinity, // Ensure card takes full width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15), // Softer shadow
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
            'Case No.: $caseNoDisplay', // Display case number here
            style: const TextStyle(
              fontSize: 18, // Slightly smaller
              fontWeight: FontWeight.bold, // Bold instead of w700
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(
              thickness: 1,
              color: Colors.black26,
              height: 24), // Adjusted divider style
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
                      fontWeight: FontWeight.w600, // Bolder key
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10), // Add space
                  Expanded(
                    // Allow value to wrap if needed
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.end, // Align value to the right
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54, // Slightly dimmer value text
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

  Widget _buildDropdownField({
    required String hint,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    bool isLabeled = true, // Keep parameter for flexibility
    String? label, // Optional label parameter
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLabeled && label != null) // Show label if provided and enabled
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              // Consistent shadow style
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border:
                Border.all(color: Colors.grey[300]!, width: 1), // Subtle border
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true, // Ensure dropdown takes full width
            decoration: InputDecoration(
              filled: true, // Important for background color
              fillColor: Colors.white, // Explicit background
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                // Use outline border
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide.none, // Hide the default outline border side
              ),
              enabledBorder: OutlineInputBorder(
                // Border when enabled
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                // Border when focused
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.black, width: 1.5), // Highlight focus
              ),
              hintText: hint, // Use hintText property
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
            // hint: Text(hint, style: TextStyle(color: Colors.grey[600])), // Original hint placement
            items: items.isEmpty
                ? [
                    DropdownMenuItem(
                        value: null, child: Text("No ${selectedRole}s found"))
                  ] // Handle empty list
                : items
                    .map((item) => DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(
                            item['name'] ??
                                'Unknown', // Handle potential null name
                            overflow: TextOverflow
                                .ellipsis, // Prevent long names overflowing
                          ),
                        ))
                    .toList(),
            onChanged:
                items.isEmpty ? null : onChanged, // Disable if list is empty
            style: const TextStyle(color: Colors.black, fontSize: 16),
            dropdownColor:
                Colors.white, // Background color of the dropdown menu
            icon: const Icon(Icons.arrow_drop_down,
                color: Colors.black54), // Standard dropdown icon
          ),
        ),
      ],
    );
  }

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
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              // Consistent shadow style
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border:
                Border.all(color: Colors.grey[300]!, width: 1), // Subtle border
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: maxLines == 1
                ? TextInputType.text
                : TextInputType.multiline, // Adjust keyboard type
            textInputAction: maxLines == 1
                ? TextInputAction.next
                : TextInputAction.newline, // Improve keyboard actions
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none, // Hide default border side
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.black, width: 1.5), // Highlight focus
              ),
              contentPadding: const EdgeInsets.all(16), // Consistent padding
            ),
            style: const TextStyle(
                fontSize: 16, color: Colors.black87), // Ensure text color
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required VoidCallback onTap,
    required Widget child, // Child is expected to be a Text widget here
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        InkWell(
          // Use InkWell for better tap feedback
          onTap: onTap,
          borderRadius: BorderRadius.circular(12), // Match container radius
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.grey[400]!, width: 1), // Slightly darker border
              boxShadow: [
                // Consistent shadow style
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Push icon to end
              children: [
                child, // The Text widget showing the date
                // const Spacer(), // Not needed with MainAxisAlignment.spaceBetween
                Icon(Icons.calendar_today_outlined,
                    color: Colors.black54, size: 20), // Use outlined icon
              ],
            ),
          ),
        ),
      ],
    );
  }
}
