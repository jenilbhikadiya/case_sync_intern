import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../components/basicUIcomponent.dart';
import '../../components/case_card.dart';
import '../../components/list_app_bar.dart';
import '../../models/case_list.dart';
import '../../services/case_services.dart';
import '../constants/date_constants.dart';

class CaseHistoryScreen extends StatefulWidget {
  final String internId;

  const CaseHistoryScreen({super.key, required this.internId});

  @override
  CaseHistoryScreenState createState() => CaseHistoryScreenState();
}

class CaseHistoryScreenState extends State<CaseHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late String selectedYear;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<CaseListData> _filteredCases = [];
  int _currentResultIndex = 0;
  List<String> _resultTabs = [];
  late List<String> monthsWithCases;
  late Future<void> _caseDataFuture;
  final ScrollController _scrollController = ScrollController();

  FocusNode fn = FocusNode();

  @override
  void initState() {
    super.initState();
    _caseDataFuture = _initializeCaseData();
  }

  Future<void> _initializeCaseData() async {
    // Wait until `caseData` is populated
    while (caseData.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (years.isNotEmpty) {
      setState(() {
        selectedYear = years.last;
        monthsWithCases = _getMonthsForYear(selectedYear);

        if (monthsWithCases.isNotEmpty) {
          _tabController = TabController(
            length: monthsWithCases.length,
            vsync: this,
          );

          // Set default tab to current month, or first valid tab
          final currentMonthIndex = DateTime.now().month - 1;
          final availableMonths =
              monthsWithCases.map((month) => months.indexOf(month)).toList();

          int initialTabIndex = availableMonths.contains(currentMonthIndex)
              ? availableMonths.indexOf(currentMonthIndex)
              : 0;

          _tabController.animateTo(initialTabIndex);

          _tabController.addListener(() {
            if (!_tabController.indexIsChanging) {
              setState(() {});
            }
          });
        }
      });
    }
  }

  List<String> _getMonthsForYear(String year) {
    if (!caseData.containsKey(year)) return [];

    return caseData[year]!
        .keys
        .where((month) => caseData[year]![month]!.isNotEmpty)
        .toList()
      ..sort((a, b) => months.indexOf(a).compareTo(months.indexOf(b)));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Update filtered cases across all months
  void _updateFilteredCases() {
    setState(() {
      _filteredCases.clear();
      _resultTabs.clear();

      // Search within the selected year first
      if (caseData.containsKey(selectedYear)) {
        caseData[selectedYear]?.forEach((month, cases) {
          final results = _filterCases(cases);
          if (results.isNotEmpty) {
            _filteredCases.addAll(results);
            _resultTabs
                .addAll(List.filled(results.length, '$selectedYear-$month'));
          }
        });
      }

      // If no results, search other years
      if (_filteredCases.isEmpty) {
        caseData.forEach((year, monthlyCases) {
          if (year != selectedYear) {
            monthlyCases.forEach((month, cases) {
              final results = _filterCases(cases);
              if (results.isNotEmpty) {
                _filteredCases.addAll(results);
                _resultTabs.addAll(List.filled(results.length, '$year-$month'));
              }
            });
          }
        });
      }

      // Navigate to the first result if available
      if (_filteredCases.isNotEmpty) {
        _currentResultIndex = 0;
        _switchTabToResult();
      }
    });
  }

  List<CaseListData> _filterCases(List<CaseListData> cases) {
    return cases.where((caseItem) {
      return caseItem.caseNo.toLowerCase().contains(_searchQuery) ||
          caseItem.courtName.toLowerCase().contains(_searchQuery) ||
          caseItem.cityName.toLowerCase().contains(_searchQuery) ||
          caseItem.handleBy.toLowerCase().contains(_searchQuery) ||
          caseItem.applicant.toLowerCase().contains(_searchQuery) ||
          caseItem.opponent.toLowerCase().contains(_searchQuery);
    }).toList();
  }

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
    if (_filteredCases.isEmpty) return;

    // Extract year and month from the search result
    final yearMonth = _resultTabs[_currentResultIndex].split('-');
    final targetYear = (yearMonth[0] == '') ? '-1' : yearMonth[0];
    // print(targetYear);
    final targetMonth = yearMonth[1];

    // Ensure a state update occurs for any valid year
    if (caseData.containsKey(targetYear)) {
      setState(() {
        // Update the year and months
        selectedYear = targetYear;
        // print(selectedYear);
        monthsWithCases = _getMonthsForYear(selectedYear);

        // Recreate the TabController for the new year
        _tabController.dispose();
        _tabController =
            TabController(length: monthsWithCases.length, vsync: this);

        // Navigate to the correct month tab
        final monthIndex = months.indexOf(targetMonth);
        if (monthIndex >= 0) {
          _tabController.animateTo(monthIndex);
        }
      });

      // Scroll to the highlighted case
      Future.microtask(() {
        final allCases = getCaseDataForMonth(selectedYear, targetMonth);
        final highlightedIndex = allCases.indexWhere((caseItem) =>
            caseItem.caseNo == _filteredCases[_currentResultIndex].caseNo);

        if (highlightedIndex >= 0) {
          _scrollController.animateTo(
            highlightedIndex * 200.0, // Approximate height per case card
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    } else {
      // print("Target year $targetYear not found in caseData");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _caseDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (monthsWithCases.isEmpty && _filteredCases.isEmpty) {
          return Scaffold(
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
              title: const Text("Case History"),
            ),
            body: const Center(
              child: Text("No case data available for the selected year."),
            ),
          );
        }

        void disposalFunc() {
          _searchController.clear();
          _searchQuery = '';
          _filteredCases = [];
          _resultTabs = [];
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF3F3F3),
          appBar: ListAppBar(
            title: "Case History",
            onSearchPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                (_isSearching) ? fn.requestFocus() : disposalFunc();
              });
            },
            isSearching: _isSearching,
            onFilterPressed: null,
          ),
          body: _buildBodyContent(),
        );
      },
    );
  }

  Widget _buildBodyContent() {
    var screenWidth = MediaQuery.sizeOf(context).width;

    // Check if monthsWithCases is empty and handle the scenario
    if (monthsWithCases.isEmpty) {
      return Center(
        child: Text(
          'No months available for the selected year.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return Column(
      children: [
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: fn,
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
                      onPressed: _currentResultIndex < _filteredCases.length - 1
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                color: const Color(0xFFF3F3F3),
                width: screenWidth * 0.7,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  indicatorWeight: 2.0,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                  tabs:
                      monthsWithCases.map((month) => Tab(text: month)).toList(),
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              DropdownButton<String>(
                value: selectedYear,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedYear = newValue;
                      monthsWithCases = _getMonthsForYear(selectedYear);

                      // Refresh the TabController
                      _tabController.dispose();
                      _tabController = TabController(
                          length: monthsWithCases.length, vsync: this);

                      if (monthsWithCases.isNotEmpty) {
                        _tabController.animateTo(0);
                      }
                    });
                  }
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
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: monthsWithCases.map((month) {
              var allCases = getCaseDataForMonth(selectedYear, month);

              // Scroll to the highlighted case
              Future.microtask(() {
                if (_isSearching &&
                    _filteredCases.isNotEmpty &&
                    _resultTabs[_currentResultIndex].endsWith(month)) {
                  final index = allCases.indexWhere((caseItem) =>
                      caseItem.caseNo ==
                      _filteredCases[_currentResultIndex].caseNo);

                  if (index >= 0) {
                    _scrollController.animateTo(
                      index * 200.0, // Approximate item height
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              });

              return Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: RefreshIndicator(
                  color: AppTheme.getRefreshIndicatorColor(
                      Theme.of(context).brightness),
                  backgroundColor:
                      AppTheme.getRefreshIndicatorBackgroundColor(),
                  onRefresh: () async {
                    // print("Before refresh: ${caseData[selectedYear]}");
                    await populateCaseData(widget.internId);
                    // print("After refresh: ${caseData[selectedYear]}");
                    setState(() {
                      monthsWithCases = _getMonthsForYear(selectedYear);
                    });
                  },
                  child: allCases.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'No cases available for this month.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black54),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height -
                                  (AppBar().preferredSize.height +
                                      kToolbarHeight), // Adjust based on the layout
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: allCases.length,
                              itemBuilder: (context, index) {
                                var caseItem = allCases[index];

                                bool isHighlighted = _isSearching &&
                                    _filteredCases.isNotEmpty &&
                                    _resultTabs[_currentResultIndex]
                                        .endsWith(month) &&
                                    _filteredCases[_currentResultIndex]
                                            .caseNo ==
                                        caseItem.caseNo;

                                return CaseCard(
                                  caseItem: caseItem,
                                  isHighlighted: isHighlighted,
                                );
                              },
                            ),
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
