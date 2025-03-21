import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/utils/constants.dart';
import '../../components/basicUIcomponent.dart';
import '../../models/intern.dart';
import '../../services/shared_pref.dart';

class ProceedCaseAdd extends StatefulWidget {
  final String caseId;

  const ProceedCaseAdd({Key? key, required this.caseId}) : super(key: key);

  @override
  _ProceedCaseAddState createState() => _ProceedCaseAddState();
}

class _ProceedCaseAddState extends State<ProceedCaseAdd> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedStage;
  String? _remark;
  bool _isLoading = false;
  bool _isStagesLoading = true;
  List<Map<String, String>> stages = [];

  @override
  void initState() {
    super.initState();
    _fetchStages();
    _fetchNextDateStage();
  }

  Future<void> _fetchStages() async {
    const String apiUrl = "$baseUrl/stage_list";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['case_id'] = widget.caseId;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(responseBody);
        if (parsedResponse['success'] == true) {
          setState(() {
            stages = (parsedResponse['data'] as List)
                .where((stage) => stage['status'] == 'enable')
                .map((stage) => {
                      "id": stage['id'].toString(),
                      "name": stage['stage'].toString().trim(),
                    })
                .toList();
          });

          // Ensure initial value is valid
          final stageIds = stages.map((stage) => stage['id']).toSet();
          if (!stageIds.contains(_selectedStage)) {
            setState(() => _selectedStage = null);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching stages: $e')),
      );
    } finally {
      setState(() => _isStagesLoading = false);
    }
  }

  Future<void> _fetchNextDateStage() async {
    const String apiUrl = "$baseUrl/get_case_info";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['case_id'] = widget.caseId;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(responseBody);
        if (parsedResponse['success'] == true &&
            parsedResponse['data'] != null &&
            parsedResponse['data'].isNotEmpty) {
          String? nextDateStr = parsedResponse['data'][0]['next_date'];
          String? nextStageId = parsedResponse['data'][0]['next_stage'];

          if (nextDateStr != null && nextDateStr != '0000-00-00') {
            setState(() => _selectedDate = DateTime.parse(nextDateStr));
          }

          if (nextStageId != null && nextStageId.isNotEmpty) {
            setState(() => _selectedStage = nextStageId);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('There is no next date and next stage for this case')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedStage == null ||
        _remark == null ||
        _remark!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String formattedDate =
        "${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}";

    const String apiUrl = "$baseUrl/proceed_case_add";

    try {
      // Fetch intern ID from shared preferences
      Intern? user = await SharedPrefService.getUser();
      String insertedBy = user?.id.toString() ?? 'intern not found';

      // Prepare the data
      Map<String, dynamic> requestData = {
        "case_id": widget.caseId,
        "next_date": formattedDate,
        "next_stage": _selectedStage,
        "remark": _remark,
        "inserted_by": insertedBy,
      };

      // Print request data
      print("🟢 Request Data: ${jsonEncode(requestData)}");

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['data'] = jsonEncode(requestData);

      // Send request and print raw request
      print("📤 Sending request to: $apiUrl");
      print("📄 Request Fields: ${request.fields}");

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      // Print response status and body
      print("✅ Response Status: ${response.statusCode}");
      print("📥 Response Body: $responseBody");

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(responseBody);
        if (parsedResponse['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proceed Stage updated successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(parsedResponse['message'] ?? 'Failed to update')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update next date')),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(data: AppTheme.calendarTheme, child: child!);
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isStagesLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                // <-- Added
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldTitle("Select Next Date:"),
                      _buildDateBox(),
                      const SizedBox(height: 15),
                      _buildFieldTitle("Select Next Stage:"),
                      _buildDropdownField(),
                      const SizedBox(height: 15),
                      _buildFieldTitle("Add Remark:"),
                      _buildRemarkField(),
                      const SizedBox(height: 40),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: AppTheme.elevatedButtonStyle,
                                child: Text(
                                  "Update Next Date",
                                  style: AppTheme.buttonTextStyle,
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

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDateBox() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? "Pick a date"
                  : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}",
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const Icon(Icons.calendar_today, size: 20, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: stages.any((stage) => stage['id'] == _selectedStage)
          ? _selectedStage
          : null,
      decoration: AppTheme.textFieldDecoration(
        labelText: "Stage",
        hintText: "Select a stage",
      ),
      items: stages.map((stage) {
        return DropdownMenuItem<String>(
          value: stage['id'],
          child: Text(stage['name']!),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedStage = value),
    );
  }

  Widget _buildRemarkField() {
    return TextFormField(
      decoration: AppTheme.textFieldDecoration(
        labelText: "Remark",
        hintText: "Enter remark",
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please enter a remark' : null,
      onChanged: (value) => _remark = value,
      maxLines: null, // Allows multiple lines
      keyboardType: TextInputType.multiline, // Enables multiline input
    );
  }
}
