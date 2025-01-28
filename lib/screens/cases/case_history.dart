import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/screens/cases/view_case_history.dart';
import 'package:intl/intl.dart';
import '../../components/list_app_bar.dart';
import '../../models/case_list.dart';
import '../../services/shared_pref.dart';
import '../constants/date_constants.dart';

class CaseHistoryScreen extends StatefulWidget {
  const CaseHistoryScreen({super.key});

  @override
  CaseHistoryScreenState createState() => CaseHistoryScreenState();
}

class CaseHistoryScreenState extends State<CaseHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedYear = '2024';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<CaseListData> _caseList = [];
  Map<String, List<CaseListData>> _casesByMonth = {};
  List<CaseListData> _filteredCases = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _internId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: months.length, vsync: this);
    _fetchInternId();

    final currentMonthIndex = DateTime.now().month - 1; // Index starts at 0
    _tabController.animateTo(currentMonthIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  Future<void> _fetchInternId() async {
    try {
      final userData = await SharedPrefService.getUser();
      if (userData != null && userData.id.isNotEmpty) {
        setState(() {
          _internId = userData.id;
        });
        await _fetchCaseHistory();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Intern ID not found in shared preferences.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching intern ID: $e';
      });
    }
  }

  Future<void> _fetchCaseHistory() async {
    if (_internId == null) return;

    try {
      final response = await http.post(
        Uri.parse(
            'https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php/intern_case_history'),
        headers: {
          'User-Agent': 'Apidog/1.0.0 (https://apidog.com)',
          'Accept': '*/*',
          'Host': 'pragmanxt.com',
        },
        body: {'intern_id': _internId!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> casesData = data['data'];
          List<CaseListData> fetchedCases = casesData
              .map((caseJson) => CaseListData.fromJson(caseJson))
              .toList();

          // Group cases by month
          Map<String, List<CaseListData>> groupedCases = {};
          for (var caseItem in fetchedCases) {
            String dateString = caseItem.summonDate;

            if (dateString.isNotEmpty) {
              try {
                DateTime date = DateFormat('dd-MM-yyyy').parse(dateString);
                String month = months[date.month - 1];

                if (!groupedCases.containsKey(month)) {
                  groupedCases[month] = [];
                }
                groupedCases[month]?.add(caseItem);
              } catch (e) {
                print(
                    'Error parsing summon_date "$dateString" for case: ${caseItem.caseNo}');
              }
            } else {
              print(
                  'Empty or invalid summon_date for case: ${caseItem.caseNo}');
            }
          }

          setState(() {
            _caseList = fetchedCases;
            _casesByMonth = groupedCases;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'No case history found.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch case history. Please try again later.';
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

  void _filterCases(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredCases = _caseList
          .where((caseItem) =>
              caseItem.caseNo.toLowerCase().contains(_searchQuery) ||
              caseItem.companyName.toLowerCase().contains(_searchQuery) ||
              caseItem.courtName.toLowerCase().contains(_searchQuery))
          .toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: ListAppBar(
        title: 'Case History',
        isSearching: _isSearching,
        onSearchPressed: () {
          setState(() {
            if (_isSearching) {
              _searchController.clear();
              _filterCases('');
            }
            _isSearching = !_isSearching;
          });
        },
        onFilterPressed: () {
          showMenu(
            context: context,
            position: const RelativeRect.fromLTRB(100, 100, 0, 0),
            items: ['2023', '2024', '2025']
                .map((year) => PopupMenuItem<String>(
                      value: year,
                      child: Text(year),
                    ))
                .toList(),
          ).then((year) {
            if (year != null) {
              setState(() {
                selectedYear = year;
                _fetchCaseHistory();
              });
            }
          });
        },
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFF3F3F3),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: months.map((month) => Tab(text: month)).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : TabBarView(
                        controller: _tabController,
                        children: months.map((month) {
                          var allCases = _searchQuery.isEmpty
                              ? (_casesByMonth[month] ?? [])
                              : _filteredCases.where((caseItem) {
                                  DateTime date = DateFormat('dd-MM-yyyy')
                                      .parse(caseItem.summonDate);
                                  return months[date.month - 1] == month;
                                }).toList();

                          return allCases.isEmpty
                              ? const Center(
                                  child: Text('No cases for this month.'),
                                )
                              : ListView.builder(
                                  itemCount: allCases.length,
                                  itemBuilder: (context, index) {
                                    var caseItem = allCases[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ViewCaseHistoryScreen(
                                              caseId: caseItem.id,
                                              caseNo: caseItem.caseNo,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 10.0),
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          side: const BorderSide(
                                              color: Colors.black,
                                              style: BorderStyle.solid),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Sr No: ${index + 1}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                  'Case No: ${caseItem.caseNo}'),
                                              Text(
                                                  'Company: ${caseItem.companyName}'),
                                              Text(
                                                  'Court Name: ${caseItem.courtName}, ${caseItem.cityName}'),
                                              Text(
                                                  'Summon Date: ${caseItem.summonDate}'),
                                              Text(
                                                  'Status: ${caseItem.status}'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}
