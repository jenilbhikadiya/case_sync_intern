import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'task_item.dart';

class ShowRemarkPage extends StatefulWidget {
  final TaskItem taskItem;

  const ShowRemarkPage({Key? key, required this.taskItem}) : super(key: key);

  @override
  _RemarkPageState createState() => _RemarkPageState();
}

class _RemarkPageState extends State<ShowRemarkPage> {
  final List<Map<String, dynamic>> _remarks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRemarkData();
  }

  Future<void> _fetchRemarkData() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://pragmanxt.com/case_sync/services/intern/v1/index.php/task_remark_list'),
        headers: {
          'User-Agent': 'Apidog/1.0.0 (https://apidog.com)',
          'Accept': '*/*',
          'Host': 'pragmanxt.com',
        },
        body: {'task_id': widget.taskItem.id.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data'].isNotEmpty) {
          setState(() {
            _remarks.clear();
            _remarks.addAll(List<Map<String, dynamic>>.from(data['data']));
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'No remarks found.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch remarks. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text('Show Remark'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _remarks.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> remark = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildField('SR. No.', (index + 1).toString()),
                              const SizedBox(height: 16),
                              _buildField('Stage', remark['stage'] ?? 'N/A'),
                              const SizedBox(height: 16),
                              _buildField('Remark', remark['remarks'] ?? 'N/A'),
                              const SizedBox(height: 16),
                              _buildField(
                                'Remark Date',
                                '${DateTime.parse(remark['dos'] ?? DateTime.now().toString()).day.toString().padLeft(2, '0')}/${DateTime.parse(remark['dos'] ?? DateTime.now().toString()).month.toString().padLeft(2, '0')}/${DateTime.parse(remark['dos'] ?? DateTime.now().toString()).year}',
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                'Next Date',
                                '${DateTime.parse(remark['nextdate'] ?? DateTime.now().toString()).day.toString().padLeft(2, '0')}/${DateTime.parse(remark['nextdate'] ?? DateTime.now().toString()).month.toString().padLeft(2, '0')}/${DateTime.parse(remark['nextdate'] ?? DateTime.now().toString()).year}',
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                  'Status', remark['status'] ?? 'Pending'),
                              const Divider(thickness: 1),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
      ],
    );
  }
}
