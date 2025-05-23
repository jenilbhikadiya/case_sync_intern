import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/utils/constants.dart';
import '../../components/basicUIcomponent.dart';
import '../../components/show_remark_card.dart';
import '../../models/task_item_list.dart';

class ShowRemarkPage extends StatefulWidget {
  final TaskItem taskItem;

  const ShowRemarkPage(
      {Key? key, required this.taskItem, String? highlightedTaskId})
      : super(key: key);

  @override
  RemarkPageState createState() => RemarkPageState();
}

class RemarkPageState extends State<ShowRemarkPage> {
  final List<Map<String, dynamic>> _remarks = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
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
      print("fetchRemarkData called for task ID: ${widget.taskItem.task_id}");
    });

    try {
      if (widget.taskItem.task_id.isEmpty) {
        setState(() {
          _errorMessage = 'Task ID is missing or invalid.';
          _isLoading = false;
          print("Error: Task ID is empty.");
        });
        return;
      }

      final uri = Uri.parse('$baseUrl/task_remark_list');
      final request = http.MultipartRequest('POST', uri);
      print("Task ID being sent in request: ${widget.taskItem.task_id}");
      request.fields['task_id'] = widget.taskItem.task_id;
      print("Full HTTP Request: $request");

      final streamedResponse = await request.send();
      print("Streamed Response: $streamedResponse");
      final response = await http.Response.fromStream(streamedResponse);
      print("HTTP Response Status Code: ${response.statusCode}");
      print("HTTP Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Decoded JSON Data: $data");
        print("Task ID after decoding response: ${widget.taskItem.task_id}");
        if (data['success'] == true &&
            data['data'] != null &&
            data['data'].isNotEmpty) {
          final remarks = List<Map<String, dynamic>>.from(data['data']);
          print("Fetched Remarks Data: $remarks");
          setState(() {
            _remarks.clear();
            _isLoading = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              for (int i = 0; i < remarks.length; i++) {
                _remarks.add(remarks[i]);
                _listKey.currentState!.insertItem(i);
              }
            });
            print("Remarks added to _remarks list. Count: ${_remarks.length}");
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'No remarks found.';
            _isLoading = false;
            print(
                "Error: No remarks found or API returned failure. Message: $_errorMessage");
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch remarks. Status code: ${response.statusCode}';
          _isLoading = false;
          print(
              "Error: Failed to fetch remarks. Status code: ${response.statusCode}");
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
        print("Error during API call: $e");
      });
    }
    print("Task ID at the end of fetchRemarkData: ${widget.taskItem.task_id}");
  }

  Widget buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1, 0),
        end: Offset(0, 0),
      ).animate(animation),
      child: RemarkCard(
        index: index,
        remark: _remarks[index],
      ),
    );
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
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: _remarks.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index, animation) {
                      if (index < _remarks.length) {
                        return buildItem(context, index, animation);
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
      ),
    );
  }
}
