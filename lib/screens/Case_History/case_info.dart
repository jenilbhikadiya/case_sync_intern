import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../models/case_info_list.dart';
import '../../utils/constants.dart';

class CaseInfoPage extends StatefulWidget {
  final String caseId;
  final String caseNo;

  const CaseInfoPage({super.key, required this.caseId, required this.caseNo});

  @override
  CaseInfoPageState createState() => CaseInfoPageState();
}

class CaseInfoPageState extends State<CaseInfoPage> {
  bool _isLoading = true;
  Map<String, dynamic> _caseDetails = {};
  String? selectedStage;
  List<Map<String, dynamic>> stageList = [];

  @override
  void initState() {
    super.initState();
    fetchCaseInfo();
  }

  Future<void> fetchCaseInfo() async {
    try {
      final url = Uri.parse('$baseUrl/get_case_info');
      final response = await http.post(url, body: {'case_id': widget.caseId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'].isNotEmpty) {
          final caseData = data['data'][0];

          if (mounted) {
            setState(() {
              final caseDetail = CaseInfoDetail.fromJson(caseData);
              _caseDetails = caseDetail.toMap();
              _isLoading = false;
            });
          }
        } else {
          _showError("No data found for the given case.");
        }
      } else {
        _showError("Failed to fetch case details.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildDetailsCard({
    required Map<String, dynamic> details,
  }) {
    final Map<String, List<MapEntry<String, dynamic>>> groupedDetails = {
      'General Info': details.entries
          .where(
              (e) => ['Case Year', 'Case Type', 'Case Counter'].contains(e.key))
          .toList(),
      'Legal Details': details.entries
          .where((e) =>
              ['Current Stage', 'Next Stage', 'Court', 'City'].contains(e.key))
          .toList(),
      'Advocates': details.entries
          .where((e) => [
                'Complainant Advocate',
                'Respondent Advocate',
              ].contains(e.key))
          .toList(),
      'Dates': details.entries
          .where((e) =>
              ['Summon Date', 'Next Date', 'Date Of Filing'].contains(e.key))
          .toList(),
    };

    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Colors.black,
            width: 1,
          )),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...groupedDetails.entries.map((section) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Text(
                      section.key,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(
                      thickness: 2,
                      color: Colors.black,
                    ),
                    // Key-Value Rows
                    ...section.value.map((entry) {
                      String displayValue;
                      displayValue = entry.value?.toString() ?? '-';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  displayValue,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          if (section.value.last != entry)
                            Divider(
                              thickness: 1,
                              color: Colors.black38,
                            )
                        ],
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0.0),
          child: Divider(
            thickness: 2,
            height: 0,
          ),
        ),
        backgroundColor: const Color(0xFFF3F3F3),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/back_arrow.svg'),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.caseNo,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 27,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.black,
            ))
          : _caseDetails.isEmpty || _caseDetails['case_no'] == 'No data found'
              ? const Center(
                  child: Text(
                    'No data found',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : RefreshIndicator(
                  color: Colors.black,
                  onRefresh: () async {
                    setState(() {
                      fetchCaseInfo();
                    });
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailsCard(details: _caseDetails),
                      ],
                    ),
                  ),
                ),
    );
  }
}
