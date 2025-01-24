import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting

import '../../components/case_card.dart';
import '../../components/list_app_bar.dart';
import '../../models/case_list.dart';
import '../../services/case_services.dart';
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
  int _currentResultIndex = 0;
  List<String> _resultTabs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _internId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: months.length, vsync: this);
    _fetchInternId();

    final currentMonthIndex = DateTime.now().month - 1; // Index starts at 0
    int initialTabIndex = currentMonthIndex;

    _tabController.animateTo(initialTabIndex);
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
            'https://pragmanxt.com/case_sync/services/intern/v1/index.php/intern_case_history'),
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

            // Ensure dateString is valid and non-empty
            if (dateString.isNotEmpty) {
              try {
                DateTime date = DateFormat('dd-MM-yyyy').parse(dateString);
                String month = months[date.month - 1]; // Convert to month name

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

  void _updateFilteredCases() {
    setState(() {
      _filteredCases.clear();
      _resultTabs.clear();

      _casesByMonth.forEach((month, cases) {
        final results = cases.where((caseItem) {
          return caseItem.caseNo.toLowerCase().contains(_searchQuery) ||
              caseItem.courtName.toLowerCase().contains(_searchQuery) ||
              caseItem.cityName.toLowerCase().contains(_searchQuery) ||
              caseItem.companyName.toLowerCase().contains(_searchQuery) ||
              caseItem.caseTypeName.toLowerCase().contains(_searchQuery) ||
              caseItem.status.toLowerCase().contains(_searchQuery);
        }).toList();

        if (results.isNotEmpty) {
          _filteredCases.addAll(results);
          _resultTabs.addAll(List.filled(results.length, month));
        }
      });

      _currentResultIndex = 0; // Reset to the first result
      if (_filteredCases.isNotEmpty) {
        _switchTabToResult();
      }
    });
  }

  void _navigateToPreviousResult() {
    setState(() {
      if (_currentResultIndex > 0) {
        _currentResultIndex--;
        _switchTabToResult();
      }
    });
  }

  void _navigateToNextResult() {
    setState(() {
      if (_currentResultIndex < _filteredCases.length - 1) {
        _currentResultIndex++;
        _switchTabToResult();
      }
    });
  }

  void _switchTabToResult() {
    String resultMonth = _resultTabs[_currentResultIndex];
    int monthIndex = months.indexOf(resultMonth);
    _tabController.animateTo(monthIndex);
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
        title: "History",
        onSearchPressed: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchController.clear();
              _searchQuery = '';
              _filteredCases = [];
              _resultTabs = [];
            }
          });
        },
        isSearching: _isSearching,
        onFilterPressed: null,
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _searchQuery = value.toLowerCase();
                        _updateFilteredCases();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search cases...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _currentResultIndex > 0
                            ? _navigateToPreviousResult
                            : null,
                      ),
                      Text(
                          '${_filteredCases.isEmpty ? 0 : _currentResultIndex + 1} / ${_filteredCases.length}'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed:
                            _currentResultIndex < _filteredCases.length - 1
                                ? _navigateToNextResult
                                : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Container(
            color: const Color(0xFFF3F3F3),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Case History',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                DropdownButton<String>(
                  value: selectedYear,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedYear = newValue!;
                      _fetchCaseHistory(); // Fetch data for the selected year if needed
                    });
                  },
                  dropdownColor: Colors.white,
                  items: years.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFF3F3F3),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 2.0,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              tabs: months.map((month) => Tab(text: month)).toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage))
                      : TabBarView(
                          controller: _tabController,
                          children: months.map((month) {
                            var allCases = _casesByMonth[month] ?? [];
                            return RefreshIndicator(
                              onRefresh: () async {
                                await _fetchCaseHistory();
                              },
                              child: allCases.isEmpty
                                  ? const Center(
                                      child: Text('No cases for this month.'),
                                    )
                                  : ListView.builder(
                                      itemCount: allCases.length,
                                      itemBuilder: (context, index) {
                                        var caseItem = allCases[index];
                                        bool isHighlighted = _isSearching &&
                                            _filteredCases.isNotEmpty &&
                                            _resultTabs[_currentResultIndex] ==
                                                month &&
                                            _filteredCases[_currentResultIndex]
                                                    .caseNo ==
                                                caseItem.caseNo;
                                        return CaseCard(
                                          srNo: index + 1, // Pass Sr No
                                          caseItem: caseItem,
                                          isHighlighted: isHighlighted,
                                        );
                                      },
                                    ),
                            );
                          }).toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
