import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  List<Map<String, String>> _internList = [];

  @override
  void initState() {
    super.initState();
    fetchInternList();
  }

  Future<void> fetchInternList() async {
    const String apiUrl =
        'https://pragmanxt.com/case_sync/services/intern/v1/index.php/get_interns_list';

    print(_internList);
    print(widget.intern_id);
    print(widget.task_id);

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _internList = (responseData['data'] as List<dynamic>)
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
    final String apiUrl =
        'https://pragmanxt.com/case_sync/services/intern/v1/index.php/task_reassign';

    final Map<String, dynamic> data = {
      "task_id": "3",
      "intern_id": _selectedIntern,
      "reassign_id": "2",
      "remark": _remarkController.text,
      "remark_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: json.encode({"data": data}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _responseMessage = responseData['message'];
        });
      } else {
        setState(() {
          _responseMessage =
              'Failed to reassign task. Status code: ${response.statusCode}';
          print(data);
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'An error occurred: $e';
        print("$e");
      });
    }
    print(data);
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        title: Text('Task Assign', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black, // Black back arrow icon
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back when clicked
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interns',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              dropdownColor: Colors.white,
              isExpanded: true,
              value: _selectedIntern,
              hint: Text('Select an Intern'),
              items: _internList
                  .map((intern) => DropdownMenuItem<String>(
                        value: intern['id'],
                        child: Text(intern['name']!),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIntern = value;
                  // Fetch and assign the selected intern's id as reassign_id
                  final selectedInternData =
                      _internList.firstWhere((intern) => intern['id'] == value);
                  print("Selected Intern ID: ${selectedInternData['id']}");
                  print("Selected Intern Name: ${selectedInternData['name']}");
                });
              },
            ),
            SizedBox(height: 16),
            Text(
              'Remark',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _remarkController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Remark Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd-MM-yyyy').format(_selectedDate),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: reassignTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Save'),
              ),
            ),
            if (_responseMessage != null) ...[
              SizedBox(height: 20),
              Text(
                _responseMessage!,
                style: TextStyle(color: Colors.green),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
