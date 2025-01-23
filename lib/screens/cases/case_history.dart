import 'package:flutter/material.dart';

import '../../components/case_card.dart';
import '../../components/list_app_bar.dart';
import '../../models/case_list.dart';
import '../../services/case_services.dart';
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
  List<CaseListData> _filteredCases = [];
  int _currentResultIndex = 0;
  List<String> _resultTabs = [];

  // @override
  // void initState() {
  //   super.initState();
  //
  //   // Initialize the TabController and set it to the current month
  //   _tabController = TabController(length: months.length, vsync: this);
  //   final currentMonthIndex = DateTime.now().month - 1; // Index starts at 0
  //   _tabController.animateTo(currentMonthIndex);
  //
  //   _tabController.addListener(() {
  //     if (!_tabController.indexIsChanging) {
  //       setState(() {});
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();

    // Initialize the TabController
    _tabController = TabController(length: months.length, vsync: this);

    final currentMonthIndex = DateTime.now().month - 1; // Index starts at 0
    final availableMonths = caseData[selectedYear]
        ?.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => months.indexOf(entry.key))
        .toList();

    // Determine the initial tab
    int initialTabIndex = currentMonthIndex;
    if (availableMonths != null && availableMonths.isNotEmpty) {
      if (!availableMonths.contains(currentMonthIndex)) {
        initialTabIndex = availableMonths.last;
      }
    } else {
      initialTabIndex = 0; // Default to the first month if no data exists
    }

    _tabController.animateTo(initialTabIndex);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Update filtered cases across all months
  void _updateFilteredCases() {
    setState(() {
      _filteredCases.clear();
      _resultTabs.clear();

      // Filter cases based on the search query
      caseData[selectedYear]?.forEach((month, cases) {
        final results = cases.where((caseItem) {
          return caseItem.caseNo.toLowerCase().contains(_searchQuery) ||
              caseItem.courtName.toLowerCase().contains(_searchQuery) ||
              caseItem.cityName.toLowerCase().contains(_searchQuery) ||
              caseItem.handleBy.toLowerCase().contains(_searchQuery) ||
              caseItem.applicant.toLowerCase().contains(_searchQuery) ||
              caseItem.opponent.toLowerCase().contains(_searchQuery);
        }).toList();

        if (results.isNotEmpty) {
          _filteredCases.addAll(results);
          _resultTabs.addAll(List.filled(results.length, month));
        }
      });

      _currentResultIndex = 0; // Reset to the first result

      // Automatically switch to the first result's tab if any result is found
      if (_filteredCases.isNotEmpty) {
        _switchTabToResult();
      }
    });
  }

  // Navigate to previous search result
  void _navigateToPreviousResult() {
    setState(() {
      if (_currentResultIndex > 0) {
        _currentResultIndex--;
        _switchTabToResult();
      }
    });
  }

  // Navigate to next search result
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
        onFilterPressed: null, // Removed filter functionality
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
                        setState(() {
                          _searchQuery = value.toLowerCase();
                          _updateFilteredCases();
                        });
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
              child: TabBarView(
                controller: _tabController,
                children: months.map((month) {
                  var allCases = getCaseDataForMonth(selectedYear, month);

                  // Wrap ListView with RefreshIndicator
                  return RefreshIndicator(
                    onRefresh: () async {
                      // Reload or update case data here
                      setState(() {
                        // You can modify this to fetch updated data from your API or service
                        populateCaseData();
                        allCases = getCaseDataForMonth(selectedYear, month);
                      });
                    },
                    child: ListView.builder(
                      itemCount: allCases.length,
                      itemBuilder: (context, index) {
                        var caseItem = allCases[index];

                        // Highlight only the current result
                        bool isHighlighted = _isSearching &&
                            _filteredCases.isNotEmpty &&
                            _resultTabs[_currentResultIndex] == month &&
                            _filteredCases[_currentResultIndex].caseNo ==
                                caseItem.caseNo;

                        return CaseCard(
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
