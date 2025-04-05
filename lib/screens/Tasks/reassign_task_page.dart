import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/services/shared_pref.dart';
import 'package:intern_side/utils/constants.dart';
import 'package:intl/intl.dart';

class ReAssignTaskPage extends StatefulWidget {
  final String task_id;
  final String intern_id;

  const ReAssignTaskPage(
      {super.key, required this.task_id, required this.intern_id});

  @override
  _ReAssignTaskPageState createState() => _ReAssignTaskPageState();
}

class _ReAssignTaskPageState extends State<ReAssignTaskPage> {
  final TextEditingController _remarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedIntern;
  String? _responseMessage;
  String? _internId;
  List<Map<String, String>> _internList = [];

  @override
  void initState() {
    super.initState();
    fetchInternList();
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

  Future<void> fetchInternList() async {
    const String apiUrl = '$baseUrl/get_interns_list';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _internList = (responseData['data'] as List<dynamic>)
                .where((item) =>
                    item['id'].toString() !=
                    _internId) // Exclude logged-in user
                .map((item) => {
                      'id': item['id'].toString(),
                      'name': item['name'].toString(),
                    })
                .toList();
          });
        }
      } else {
        setState(() {
          _responseMessage =
              'Failed to fetch interns. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'An error occurred while fetching interns: $e';
      });
    }
  }

  Future<void> reassignTask() async {
    final url = Uri.parse('$baseUrl/task_reassign');
    var request = http.MultipartRequest('POST', url);

    request.fields['data'] = jsonEncode({
      "task_id": widget.task_id,
      "intern_id": widget.intern_id,
      "reassign_id": _selectedIntern,
      "remark": _remarkController.text,
      "remark_date": DateFormat('yyyy/MM/dd').format(_selectedDate),
    });

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        if (responseData['success'] == true) {
          setState(() {
            _responseMessage = responseData['message'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task reassigned successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true); // Pass 'true' to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Reassignment failed.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reassign task.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1800),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  static InputDecoration textFieldDecoration({
    required String labelText,
    required String hintText,
    Color? fillColor,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        title: null,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Task Assign',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Interns',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedIntern,
                            hint: const Text('Select an Intern'),
                            items: _internList
                                .map((intern) => DropdownMenuItem<String>(
                                      value: intern['id'],
                                      child: Text(intern['name']!),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedIntern = value;
                              });
                            },
                            dropdownColor:
                                Colors.white, // Sets dropdown background color
                            menuMaxHeight:
                                200, // Adjusts the maximum height of the dropdown
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Remark',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _remarkController,
                        decoration: textFieldDecoration(
                          labelText: '',
                          hintText: 'Enter your remark',
                          fillColor: const Color(0xFFF3F3F3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Remark Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color.fromARGB(255, 0, 0, 0)),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('dd-MM-yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _selectDate(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: reassignTask,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30), // Adjusted to 30
                            ),
                          ),
                          child: const Text(
                            'Reassign',
                            style: TextStyle(
                              fontSize: 20, // Adjusted font size to 20
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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
