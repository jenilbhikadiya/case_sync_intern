import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
    final url = Uri.parse(
        'https://pragmanxt.com/case_sync/services/intern/v1/index.php/task_reassign');
    var request = http.MultipartRequest('POST', url);

    request.fields['data'] = jsonEncode({
      "task_id": widget.task_id,
      "intern_id": widget.intern_id,
      "reassign_id": _selectedIntern, // Use the updated _selectedIntern
      "remark": _remarkController.text,
      "remark_date": DateFormat('yyyy/MM/dd').format(_selectedDate),
    });

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        setState(() {
          _responseMessage = responseData['message'];
        });
      } else {
        setState(() {
          _responseMessage =
              'Failed to reassign task. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'An error occurred: $e';
      });
    }

    print(request.fields['data']);
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
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 32,
            height: 32,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Task Assign',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
                hint: const Text('Select an Intern'),
                items: _internList
                    .map((intern) => DropdownMenuItem<String>(
                          value: intern['id'], // The ID of the intern
                          child:
                              Text(intern['name']!), // The name of the intern
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIntern = value;
                  });
                  print('Selected Intern ID: $_selectedIntern'); // Debugging
                }),
            const SizedBox(height: 16),
            const Text(
              'Remark',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _remarkController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
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
