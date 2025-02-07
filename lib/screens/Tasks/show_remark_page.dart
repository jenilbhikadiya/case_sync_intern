import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/utils/constants.dart';
import '../../components/basicUIcomponent.dart';
import '../../components/remark_card.dart';
import '../../models/task_item_list.dart';

class ShowRemarkPage extends StatefulWidget {
  final TaskItem taskItem;

  const ShowRemarkPage({Key? key, required this.taskItem}) : super(key: key);

  @override
  RemarkPageState createState() => RemarkPageState();
}

class RemarkPageState extends State<ShowRemarkPage> {
  final List<Map<String, dynamic>> _remarks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRemarkData();
  }

  Future<void> fetchRemarkData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.taskItem.task_id.isEmpty) {
        setState(() {
          _errorMessage = 'Task ID is missing or invalid.';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse('$baseUrl/task_remark_list');
      final request = http.MultipartRequest('POST', uri);
      request.fields['task_id'] = widget.taskItem.task_id;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        onRefresh: fetchRemarkData,
        color: AppTheme.getRefreshIndicatorColor(Theme.of(context).brightness),
        backgroundColor: AppTheme.getRefreshIndicatorBackgroundColor(),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black))
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: _remarks.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> remark = entry.value;

                        return RemarkCard(
                          index: index,
                          remark: remark,
                        );
                      }).toList(),
                    ),
                  ),
      ),
    );
  }
}
