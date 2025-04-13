import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/services/shared_pref.dart';
import 'package:intern_side/utils/constants.dart';
import 'package:intl/intl.dart';

// Enum to represent the type of assignee
enum AssigneeType { intern, advocate }

class ReAssignTaskPage extends StatefulWidget {
  final String task_id;
  final String intern_id; // ID of the user initiating the reassignment

  const ReAssignTaskPage(
      {super.key, required this.task_id, required this.intern_id});

  @override
  _ReAssignTaskPageState createState() => _ReAssignTaskPageState();
}

class _ReAssignTaskPageState extends State<ReAssignTaskPage> {
  final TextEditingController _remarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _responseMessage;
  String? _loggedInUserId; // Renamed for clarity

  // --- New/Modified State Variables ---
  AssigneeType _selectedType = AssigneeType.intern; // Default to Intern
  List<Map<String, String>> _internList = [];
  List<Map<String, String>> _advocateList = [];
  List<Map<String, String>> _displayList =
      []; // List currently shown in dropdown
  String? _selectedAssigneeId; // ID of the selected intern OR advocate
  bool _isLoadingInterns = false;
  bool _isLoadingAdvocates = false;
  // --- End New/Modified State Variables ---

  @override
  void initState() {
    super.initState();
    // Fetch the logged-in user ID first
    _fetchLoggedInUserId().then((_) {
      // Then fetch both lists concurrently
      fetchInternList();
      fetchAdvocateList();
    });
  }

  // Renamed function for clarity
  Future<void> _fetchLoggedInUserId() async {
    final userData = await SharedPrefService.getUser();
    if (mounted && userData != null && userData.id.isNotEmpty) {
      setState(() {
        _loggedInUserId = userData.id;
      });
    }
  }

  // Fetch Interns List
  Future<void> fetchInternList() async {
    if (_loggedInUserId == null) return; // Don't fetch if user ID unknown
    setState(() {
      _isLoadingInterns = true;
      _responseMessage = null; // Clear previous messages
    });
    const String apiUrl = '$baseUrl/get_interns_list';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (!mounted) return; // Check if widget is still mounted

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _internList = (responseData['data'] as List<dynamic>)
                .where((item) =>
                    item['id']?.toString() !=
                    _loggedInUserId) // Exclude logged-in user
                .map((item) => {
                      'id': item['id']?.toString() ??
                          '', // Ensure ID is string and non-null
                      'name': item['name']?.toString() ??
                          'Unnamed Intern', // Ensure name is string
                    })
                .where((item) =>
                    item['id']!.isNotEmpty) // Filter out items with empty IDs
                .toList();
            _updateDisplayList(); // Update dropdown content
          });
        } else {
          setState(() => _responseMessage =
              responseData['message'] ?? 'Failed to parse intern data.');
        }
      } else {
        setState(() => _responseMessage =
            'Failed to fetch interns. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted)
        setState(() => _responseMessage = 'Error fetching interns: $e');
    } finally {
      if (mounted) setState(() => _isLoadingInterns = false);
    }
  }

  // Fetch Advocates List
  Future<void> fetchAdvocateList() async {
    // Advocates might not need filtering based on logged-in user, adjust if needed
    setState(() {
      _isLoadingAdvocates = true;
      _responseMessage = null; // Clear previous messages
    });
    const String apiUrl = '$baseUrl/get_advocate_list';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (!mounted) return; // Check if widget is still mounted

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _advocateList = (responseData['data'] as List<dynamic>)
                // Add filtering here if advocates should also exclude the logged-in user
                // .where((item) => item['id']?.toString() != _loggedInUserId)
                .map((item) => {
                      'id': item['id']?.toString() ??
                          '', // Ensure ID is string and non-null
                      'name': item['name']?.toString() ??
                          'Unnamed Advocate', // Ensure name is string
                    })
                .where((item) =>
                    item['id']!.isNotEmpty) // Filter out items with empty IDs
                .toList();
            _updateDisplayList(); // Update dropdown content
          });
        } else {
          setState(() => _responseMessage =
              responseData['message'] ?? 'Failed to parse advocate data.');
        }
      } else {
        setState(() => _responseMessage =
            'Failed to fetch advocates. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted)
        setState(() => _responseMessage = 'Error fetching advocates: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAdvocates = false);
    }
  }

  // --- Helper to update the list shown in the dropdown ---
  void _updateDisplayList() {
    if (!mounted) return;
    setState(() {
      if (_selectedType == AssigneeType.intern) {
        _displayList = _internList;
      } else {
        _displayList = _advocateList;
      }
      // Reset selection when list type changes to avoid mismatches
      // _selectedAssigneeId = null; // Optional: Uncomment to force re-selection on toggle
    });
  }
  // --- End Helper ---

  // Reassign Task Function (Updated)
  Future<void> reassignTask() async {
    // --- Validation ---
    if (_selectedAssigneeId == null || _selectedAssigneeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an assignee first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_remarkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a remark.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // --- End Validation ---

    final url = Uri.parse('$baseUrl/task_reassign');
    var request = http.MultipartRequest('POST', url);

    // Use the correct fields: widget.intern_id for the initiator, _selectedAssigneeId for the target
    request.fields['data'] = jsonEncode({
      "task_id": widget.task_id,
      "intern_id": widget.intern_id, // ID of person doing the reassigning
      "reassign_id": _selectedAssigneeId, // ID of person being reassigned TO
      "remark": _remarkController.text.trim(),
      "remark_date": DateFormat('yyyy/MM/dd')
          .format(_selectedDate), // Ensure API expects this format
      "reassign_type": _selectedType == AssigneeType.intern
          ? 'intern'
          : 'advocate' // Send the type
    });

    print('Reassign Payload: ${request.fields['data']}'); // For debugging

    try {
      // Consider adding a loading indicator here
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Reassign Response Status: ${response.statusCode}');
      print('Reassign Response Body: $responseBody');

      if (!mounted) return;

      final responseData =
          json.decode(responseBody); // Decode after checking mount status

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                responseData['message'] ?? 'Task reassigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                'Reassignment failed. Server error.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Reassign Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred during reassignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Hide loading indicator here if added
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), // Sensible first date
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- Static Helpers (Keep as they are) ---
  static InputDecoration textFieldDecoration({
    required String labelText,
    required String hintText,
    Color? fillColor,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: fillColor ?? Colors.grey.shade100, // Default fill color
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0), // Slightly less rounded
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.black, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
          vertical: 14, horizontal: 16), // Adjusted padding
    );
  }

  static TextStyle titleStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle buttonTextStyle = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  // --- End Static Helpers ---

  @override
  Widget build(BuildContext context) {
    // Determine if the current selection is loading
    bool isLoadingCurrentList =
        (_selectedType == AssigneeType.intern && _isLoadingInterns) ||
            (_selectedType == AssigneeType.advocate && _isLoadingAdvocates);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0, // Remove shadow
        title: const Text('Reassign Task',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color(0xFFF3F3F3), // Match AppBar background
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(20.0), // Increased padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Toggle Buttons ---
                      const Text(
                        'Assign To',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ToggleButtons(
                          isSelected: [
                            _selectedType == AssigneeType.intern,
                            _selectedType == AssigneeType.advocate,
                          ],
                          onPressed: (int index) {
                            if (!mounted) return;
                            setState(() {
                              _selectedType = (index == 0)
                                  ? AssigneeType.intern
                                  : AssigneeType.advocate;
                              _selectedAssigneeId =
                                  null; // Reset selection on toggle
                              _updateDisplayList();
                            });
                          },
                          borderRadius: BorderRadius.circular(10.0),
                          selectedBorderColor: Theme.of(context).primaryColor,
                          selectedColor:
                              Colors.white, // Text color when selected
                          fillColor: Theme.of(context)
                              .primaryColor, // Background when selected
                          color: Theme.of(context)
                              .primaryColor, // Text color when not selected
                          constraints: BoxConstraints(
                            minHeight: 45.0, // Increased height
                            minWidth: (constraints.maxWidth - 48) /
                                2, // Divide width (approx)
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('INTERN',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('ADVOCATE',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Dynamic Dropdown ---
                      Row(
                        children: [
                          Text(
                            _selectedType == AssigneeType.intern
                                ? 'Select Intern'
                                : 'Select Advocate',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87),
                          ),
                          const Spacer(),
                          // Show loading indicator next to the label
                          if (isLoadingCurrentList)
                            const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5))
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4), // Adjust vertical padding
                        decoration: BoxDecoration(
                          color: Colors.white, // White background for dropdown
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedAssigneeId,
                            // Hint text updates based on loading and selection type
                            hint: isLoadingCurrentList
                                ? Text(
                                    'Loading ${_selectedType == AssigneeType.intern ? 'Interns' : 'Advocates'}...')
                                : Text(
                                    'Select an ${_selectedType == AssigneeType.intern ? 'Intern' : 'Advocate'}'),
                            // Disable dropdown while loading the current list
                            onChanged: isLoadingCurrentList
                                ? null
                                : (value) {
                                    if (value != null && mounted) {
                                      setState(() {
                                        _selectedAssigneeId = value;
                                      });
                                    }
                                  },
                            items: _displayList
                                .map((assignee) => DropdownMenuItem<String>(
                                      value: assignee['id'],
                                      child: Text(assignee['name']!,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            dropdownColor: Colors.white,
                            icon: Icon(Icons.arrow_drop_down_rounded,
                                color: Colors.grey.shade700),
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16), // Text style for items
                            menuMaxHeight: 300,
                          ),
                        ),
                      ),
                      // Display API error message if any
                      if (_responseMessage != null && !isLoadingCurrentList)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_responseMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ),
                      const SizedBox(height: 20),

                      // --- Remark Field ---
                      const Text(
                        'Remark',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _remarkController,
                        maxLines: 3, // Allow multi-line remarks
                        minLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: textFieldDecoration(
                          labelText: '',
                          hintText: 'Enter reason for reassignment...',
                          fillColor: Colors.white, // White background
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Date Picker ---
                      const Text(
                        'Remark Date',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        // Make the whole row tappable
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white, // White background
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // Space out text and icon
                            children: [
                              Text(
                                DateFormat('dd MMMM yyyy').format(
                                    _selectedDate), // Clearer date format
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                              Icon(Icons.calendar_today_outlined,
                                  color: Colors.grey.shade700),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30), // More space before button

                      // --- Submit Button ---
                      Center(
                        child: ElevatedButton(
                          onPressed: reassignTask, // Calls the updated function
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15), // Adjusted padding
                            backgroundColor: Colors.black, // Keep black button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 3, // Add slight elevation
                          ),
                          child: const Text(
                            'Submit Reassignment',
                            style: TextStyle(
                              fontSize: 18, // Adjusted font size
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(), // Push content up if screen is tall
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
