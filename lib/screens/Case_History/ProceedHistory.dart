// lib/screens/Case_History/view_proceed_case_history_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../components/basicUIcomponent.dart';
import '../../components/list_app_bar.dart';
import '../../models/intern.dart';
import '../../models/proceed_case.dart';
import '../../services/shared_pref.dart';
import '../../utils/constants.dart';
import '../../utils/dismissible_card.dart';

class ViewProceedCaseHistoryScreen extends StatefulWidget {
  final String caseId;
  final String caseNo;

  const ViewProceedCaseHistoryScreen({
    super.key,
    this.isHighlighted = false,
    required this.caseId,
    required this.caseNo,
    String? highlightedTaskId,
  });

  final bool isHighlighted;

  @override
  State<ViewProceedCaseHistoryScreen> createState() =>
      _ViewProceedCaseHistoryScreenState();
}

class _ViewProceedCaseHistoryScreenState
    extends State<ViewProceedCaseHistoryScreen> {
  String? _selectedStage;
  bool _isLoading = true;
  String _errorMessage = '';
  List<ProceedCase> _proceedCaseHistory = [];
  List<Map<String, String>> stages = [];
  bool _isStagesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProceedCaseHistory();
    _fetchStages();
  }

  Future<void> _fetchProceedCaseHistory() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/proceed_history'),
        body: {'case_id': widget.caseId},
      );

      print("📤 Request: case_id=${widget.caseId}");
      print("✅ Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _proceedCaseHistory = (data['data'] as List)
                .map((item) => ProceedCase.fromJson(item))
                .toList();
          });
        } else {
          setState(() {
            _errorMessage =
                data['message'] ?? 'No proceeded case history found.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No proceeded case history found.';
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

  Future<void> _fetchStages() async {
    String apiUrl = "$baseUrl/stage_list";

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

  void _deleteProceedCase(String proceedId, int index) async {
    final url = Uri.parse('$baseUrl/proceed_case_delete');
    final request = http.MultipartRequest('POST', url)
      ..fields['data'] = jsonEncode({'proceed_id': proceedId});

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _proceedCaseHistory.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case deleted successfully.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to delete case.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting case: $e")),
      );
    }
  }

  void _editProceedCase(ProceedCase proceedCase, int index) {
    TextEditingController nextDateController =
        TextEditingController(text: proceedCase.nextDate);
    TextEditingController remarksController =
        TextEditingController(text: proceedCase.remarks);

    // Set default stage
    String? selectedStage = proceedCase.stage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        "Edit Proceed Case",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    Text("Next Date",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: nextDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "Select Date",
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            nextDateController.text =
                                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Next Stage Dropdown (with default selection)
                    Text("Next Stage",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: stages
                              .any((stage) => stage['id'] == proceedCase.stage)
                          ? proceedCase.stage
                          : null,
                      decoration: InputDecoration(
                        hintText: "Select a stage",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: stages.map((stage) {
                        return DropdownMenuItem<String>(
                          value: stage['id'],
                          child: Text(stage['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedStage = value);
                      },
                    ),

                    const SizedBox(height: 10),

                    // Remarks
                    Text("Remarks",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: remarksController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter remarks",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _updateProceedCase(
                            proceedCase.id,
                            nextDateController.text,
                            selectedStage ??
                                proceedCase
                                    .stage, // Default stage if not changed
                            remarksController.text,
                            index,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateProceedCase(
    String proceedId,
    String nextDate,
    String nextStage,
    String remarks,
    int index,
  ) async {
    if (_proceedCaseHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No Proceed History Present")),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/proceed_case_edit');
    Intern? user = await SharedPrefService.getUser();
    String insertedBy = user?.id.toString() ?? 'intern not found';
    final request = http.MultipartRequest('POST', url)
      ..fields['data'] = jsonEncode({
        'proceed_id': proceedId,
        'case_id': widget.caseId,
        'next_date': nextDate,
        'next_stage': nextStage,
        'remark': remarks,
        'inserted_by': insertedBy,
      });

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _proceedCaseHistory[index] = ProceedCase(
            id: proceedId,
            nextDate: nextDate,
            stage: nextStage,
            remarks: remarks,
            caseId: widget.caseId,
            nextStage: nextStage,
            insertedBy: insertedBy,
            dateOfCreation: '',
            inserted_by_name: '',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case updated successfully.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No Proceed History Present")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating case: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: ListAppBar(
        onSearchPressed: () {},
        showSearch: false,
        title: 'Proceed Case History',
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProceedCaseHistory,
        color: AppTheme.getRefreshIndicatorColor(Theme.of(context).brightness),
        backgroundColor: AppTheme.getRefreshIndicatorBackgroundColor(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.black))
                    : _errorMessage.isNotEmpty
                        ? Column(
                            children: [
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4),
                              Center(child: Text(_errorMessage)),
                            ],
                          )
                        : Column(
                            children: _proceedCaseHistory
                                .asMap()
                                .entries
                                .map((entry) {
                              int index = entry.key + 1;
                              ProceedCase proceedCase = entry.value;

                              return DismissibleCard(
                                  name: "Case #$index",
                                  onEdit: () {
                                    _editProceedCase(proceedCase, entry.key);
                                  },
                                  onDelete: () {
                                    _deleteProceedCase(
                                        proceedCase.id, entry.key);
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(
                                          color: Colors.black,
                                          style: BorderStyle.solid),
                                    ),
                                    child: Container(
                                      width: screenWidth * 0.9,
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Table(
                                            columnWidths: const {
                                              0: FlexColumnWidth(1),
                                              1: FlexColumnWidth(2),
                                            },
                                            children: [
                                              TableRow(children: [
                                                const Text('Sr No:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text('$index',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ]),
                                              const TableRow(children: [
                                                SizedBox(
                                                    height: 12), // Adds spacing
                                                SizedBox(height: 12),
                                              ]),
                                              TableRow(children: [
                                                const Text('Stage:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                  proceedCase.stage,
                                                ),
                                              ]),
                                              const TableRow(children: [
                                                SizedBox(height: 12),
                                                SizedBox(height: 12),
                                              ]),
                                              TableRow(children: [
                                                const Text('Next Date:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(proceedCase.nextDate),
                                              ]),
                                              const TableRow(children: [
                                                SizedBox(height: 12),
                                                SizedBox(height: 12),
                                              ]),
                                              TableRow(children: [
                                                const Text('Remarks:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(proceedCase.remarks),
                                              ]),
                                              const TableRow(children: [
                                                SizedBox(height: 12),
                                                SizedBox(height: 12),
                                              ]),
                                              TableRow(children: [
                                                const Text('Inserted By:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(proceedCase
                                                    .inserted_by_name),
                                              ]),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ));
                            }).toList(),
                          ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
