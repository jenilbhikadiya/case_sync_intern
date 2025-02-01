import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import '../../components/basicUIcomponent.dart';
import '../../models/task_item_list.dart';

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
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint('Task ID: ${widget.taskItem.task_id}');
      if (widget.taskItem.task_id.isEmpty) {
        setState(() {
          _errorMessage = 'Task ID is missing or invalid.';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse(
          'https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php/task_remark_list');
      final request = http.MultipartRequest('POST', uri);
      request.fields['task_id'] = widget.taskItem.task_id;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data'].isNotEmpty) {
          setState(() {
            _remarks.clear();
            _remarks.addAll(List<Map<String, dynamic>>.from(data['data']));
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'No remarks found.';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch remarks. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Error occurred: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    try {
      if (dateString == null ||
          dateString.isEmpty ||
          dateString == "0000-00-00" ||
          dateString.startsWith("0000")) {
        return 'N/A';
      }
      final parsedDate = DateTime.parse(dateString);
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
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
        title: const Text(
          'Show Remark',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRemarkData,
        color: AppTheme.getRefreshIndicatorColor(Theme.of(context).brightness),
        backgroundColor: AppTheme.getRefreshIndicatorBackgroundColor(),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: Colors.black,
              ))
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                _buildField(
                                    'Remark', remark['remarks'] ?? 'N/A'),
                                const SizedBox(height: 16),
                                _buildField(
                                  'Remark Date',
                                  _formatDate(remark['dos']),
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  'Next Date',
                                  _formatDate(remark['nextdate']),
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
