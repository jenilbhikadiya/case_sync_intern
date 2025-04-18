import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../components/basicUIcomponent.dart';
import '../../components/case_card.dart';
import '../../components/list_app_bar.dart';
import '../../models/case_list.dart';
import '../../services/case_services.dart';
import '../../utils/constants.dart';

class CaseHistoryScreen extends StatefulWidget {
  const CaseHistoryScreen({super.key});

  @override
  CaseHistoryScreenState createState() => CaseHistoryScreenState();
}

class CaseHistoryScreenState extends State<CaseHistoryScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  String? selectedYear;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<CaseListData> _filteredCases = [];
  int _currentResultIndex = 0;
  List<String> _resultTabs = [];
  List<String> monthsWithCases = [];

  late Future<bool> _caseDataInitializationFuture;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> caseCardKeys = {};

  FocusNode fn = FocusNode();

  bool _hasCaseData = false;

  @override
  void initState() {
    super.initState();

    _caseDataInitializationFuture = _initializeCaseData();
  }

  Future<bool> _initializeCaseData() async {
    try {
      await populateCaseData();

      if (caseData.isEmpty) {
        if (kDebugMode) {
          print("Initialization complete: No case data found.");
        }
        _hasCaseData = false;

        return false;
      }

      _hasCaseData = true;
      if (kDebugMode) {
        print("Initialization complete: Case data found.");
      }

      if (years.isNotEmpty) {
        if (mounted) {
          setState(() {
            selectedYear = years.last;
            monthsWithCases = _getMonthsForYear(selectedYear!);

            if (monthsWithCases.isNotEmpty) {
              _setupTabController();
            } else {
              String? yearWithData;
              for (int i = years.length - 1; i >= 0; i--) {
                monthsWithCases = _getMonthsForYear(years[i]);
                if (monthsWithCases.isNotEmpty) {
                  yearWithData = years[i];
                  break;
                }
              }
              if (yearWithData != null) {
                selectedYear = yearWithData;
                _setupTabController();
              } else {
                _hasCaseData = false;
                if (kDebugMode)
                  print("Data exists, but no months found for any year.");
              }
            }
          });
        } else {
          return _hasCaseData;
        }
      } else {
        _hasCaseData = false;
        if (kDebugMode)
          print(
              "Data inconsistency: caseData populated but years list is empty.");
      }
      return _hasCaseData;
    } catch (e) {
      print("Error during case data initialization: $e");
      _hasCaseData = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading case history: $e')),
        );
      }
      return false;
    }
  }

  void _setupTabController() {
    _tabController?.dispose();

    _tabController = TabController(
      length: monthsWithCases.length,
      vsync: this,
    );

    final currentMonthIndex = DateTime.now().month - 1;
    final availableMonthsIndexes =
        monthsWithCases.map((month) => months.indexOf(month)).toList();

    int initialTabIndex = 0;
    if (selectedYear == DateTime.now().year.toString() &&
        availableMonthsIndexes.contains(currentMonthIndex)) {
      initialTabIndex = availableMonthsIndexes.indexOf(currentMonthIndex);
    }

    if (initialTabIndex >= monthsWithCases.length) {
      initialTabIndex = 0;
    }

    _tabController!.index = initialTabIndex;

    _tabController!.addListener(() {
      if (mounted && !_tabController!.indexIsChanging) {
        setState(() {});
      }
    });
  }

  List<String> _getMonthsForYear(String year) {
    if (!caseData.containsKey(year)) return [];

    List<String> monthOrder = months;

    List<String> availableMonths = caseData[year]
            ?.entries
            .where((entry) => entry.value.isNotEmpty)
            .map((entry) => entry.key)
            .toList() ??
        [];

    availableMonths
        .sort((a, b) => monthOrder.indexOf(a).compareTo(monthOrder.indexOf(b)));

    return availableMonths;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    fn.dispose();
    super.dispose();
  }

  void _updateFilteredCases() {
    if (!mounted) return;
    setState(() {
      _filteredCases.clear();
      _resultTabs.clear();
      _currentResultIndex = 0;

      if (_searchQuery.isEmpty) return;

      caseData.forEach((year, monthlyCases) {
        monthlyCases.forEach((month, cases) {
          final results = _filterCases(cases);
          if (results.isNotEmpty) {
            _filteredCases.addAll(results);

            _resultTabs.addAll(List.filled(results.length, '$year-$month'));
          }
        });
      });

      if (kDebugMode) {
        print('Filtered Cases Count: ${_filteredCases.length}');
      }

      if (_filteredCases.isNotEmpty) {
        _switchTabToResult();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No cases found matching search criteria.')));
      }
    });
  }

  List<CaseListData> _filterCases(List<CaseListData> cases) {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    return cases.where((caseItem) {
      return (caseItem.caseNo.toLowerCase().contains(query)) ||
          (caseItem.courtName.toLowerCase().contains(query)) ||
          (caseItem.cityName.toLowerCase().contains(query)) ||
          (caseItem.handleBy.toLowerCase().contains(query)) ||
          (caseItem.applicant.toLowerCase().contains(query)) ||
          (caseItem.opponent.toLowerCase().contains(query));
    }).toList();
  }

  void _navigateToPreviousResult() {
    if (!mounted) return;
    setState(() {
      if (_currentResultIndex > 0) {
        _currentResultIndex--;
        _switchTabToResult();
      }
    });
  }

  void _navigateToNextResult() {
    if (!mounted) return;
    setState(() {
      if (_currentResultIndex < _filteredCases.length - 1) {
        _currentResultIndex++;
        _switchTabToResult();
      }
    });
  }

  void _switchTabToResult() {
    if (_filteredCases.isEmpty || _currentResultIndex >= _resultTabs.length) {
      if (kDebugMode)
        print("Cannot switch tab: No results or index out of bounds.");
      return;
    }

    final yearMonth = _resultTabs[_currentResultIndex].split('-');
    if (yearMonth.length != 2) {
      if (kDebugMode)
        print(
            "🚨 Invalid year-month format in _resultTabs: ${_resultTabs[_currentResultIndex]}");
      return;
    }
    final targetYear = yearMonth[0];
    final targetMonth = yearMonth[1];

    bool yearChanged = false;

    if (selectedYear != targetYear) {
      if (!years.contains(targetYear)) {
        if (kDebugMode)
          print(
              "🚨 Target year $targetYear not found in available years list.");
        return;
      }

      if (!mounted) return;
      setState(() {
        selectedYear = targetYear;
        monthsWithCases = _getMonthsForYear(selectedYear!);
        yearChanged = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && monthsWithCases.isNotEmpty) {
          _setupTabController();

          _findAndAnimateToMonth(targetMonth);
        } else if (mounted) {
          if (kDebugMode)
            print(
                "🚨 Target year $targetYear has no months with data after switching.");
        }
      });
    } else {
      _findAndAnimateToMonth(targetMonth);
    }
  }

  void _findAndAnimateToMonth(String targetMonth) {
    if (!mounted || _tabController == null) return;

    final monthIndex = monthsWithCases.indexOf(targetMonth);
    if (monthIndex != -1) {
      if (_tabController!.length > monthIndex) {
        _tabController!.animateTo(monthIndex);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCaseCard(
              targetYear: selectedYear!, targetMonth: targetMonth);
        });
      } else {
        if (kDebugMode)
          print(
              "🚨 Calculated monthIndex $monthIndex is out of bounds for TabController length ${_tabController!.length}");
      }
    } else {
      if (kDebugMode)
        print(
            "🚨 Target month $targetMonth not found in monthsWithCases for year $selectedYear");
    }
  }

  void _scrollToCaseCard(
      {required String targetYear, required String targetMonth}) {
    if (!mounted ||
        _scrollController.hasClients == false ||
        _filteredCases.isEmpty) {
      if (kDebugMode) {
        print(
            "🚨 Cannot scroll: Conditions not met (mounted: $mounted, hasClients: ${_scrollController.hasClients}, filteredEmpty: ${_filteredCases.isEmpty})");
      }
      return;
    }

    final allCasesInCurrentTab = getCaseDataForMonth(targetYear, targetMonth);
    if (allCasesInCurrentTab.isEmpty) {
      if (kDebugMode)
        print(
            "🚨 Cannot scroll: No cases found for $targetYear-$targetMonth in current view.");
      return;
    }

    final caseToHighlight = _filteredCases[_currentResultIndex];
    final indexInCurrentTab = allCasesInCurrentTab.indexWhere(
      (caseItem) => caseItem.caseNo == caseToHighlight.caseNo,
    );

    if (indexInCurrentTab >= 0) {
      const double estimatedCardHeight = 200.0;
      double scrollOffset = indexInCurrentTab * estimatedCardHeight;

      scrollOffset =
          scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

      if (kDebugMode) {
        print(
            "🎯 Scrolling in $targetYear-$targetMonth to index in tab: $indexInCurrentTab");
        print("🚀 Calculated Scroll Offset: $scrollOffset");
      }

      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      if (kDebugMode) {
        print(
            "🚨 Could not find highlighted case (${caseToHighlight.caseNo}) in the current tab's list ($targetYear-$targetMonth).");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _caseDataInitializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
                title: const Text("Case History"),
                elevation: 0,
                backgroundColor: const Color(0xFFF3F3F3)),
            body: const Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
                title: const Text("Case History"),
                elevation: 0,
                backgroundColor: const Color(0xFFF3F3F3)),
            body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading case history: ${snapshot.error}')),
            ),
          );
        }

        if (!_hasCaseData) {
          return Scaffold(
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
              elevation: 0,
              leading: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/back_arrow.svg',
                  width: 24,
                  height: 24,
                  colorFilter:
                      const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text("Case History",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "No case history found.",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        void disposalFunc() {
          if (!mounted) return;
          _searchController.clear();
          fn.unfocus();
          setState(() {
            _searchQuery = '';
            _filteredCases = [];
            _resultTabs = [];
            _currentResultIndex = 0;
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF3F3F3),
          appBar: ListAppBar(
            title: "Case History",
            isSearching: _isSearching,
            onSearchPressed: () {
              if (!mounted) return;
              setState(() {
                _isSearching = !_isSearching;
                if (_isSearching) {
                  fn.requestFocus();
                } else {
                  disposalFunc();
                }
              });
            },
            onFilterPressed: null,
            searchController: _searchController,
            searchFocusNode: fn,
            onSearchChanged: (value) {
              if (!mounted) return;
              setState(() {
                _searchQuery = value.toLowerCase();
                _updateFilteredCases();
              });
            },
            resultCount: _filteredCases.length,
            currentResultIndex: _currentResultIndex,
            onNavigatePrevious:
                _filteredCases.isNotEmpty && _currentResultIndex > 0
                    ? _navigateToPreviousResult
                    : null,
            onNavigateNext: _filteredCases.isNotEmpty &&
                    _currentResultIndex < _filteredCases.length - 1
                ? _navigateToNextResult
                : null,
          ),
          body: _buildBodyContent(),
        );
      },
    );
  }

  Widget _buildBodyContent() {
    if (selectedYear == null || _tabController == null) {
      return const Center(
        child: Text(
          "Loading year/month data...",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    if (monthsWithCases.isEmpty) {
      return Column(
        children: [
          _buildTabBarAndDropdown(),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No cases recorded for this year.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildTabBarAndDropdown(),
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: monthsWithCases.map((month) {
              final allCases = getCaseDataForMonth(selectedYear!, month);

              return Container(
                child: RefreshIndicator(
                  color: AppTheme.getRefreshIndicatorColor(
                      Theme.of(context).brightness),
                  backgroundColor:
                      AppTheme.getRefreshIndicatorBackgroundColor(),
                  onRefresh: () async {
                    await _initializeCaseData();
                  },
                  child: allCases.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight),
                                child: const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                      'No cases available for this month.',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black54)),
                                ))),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: allCases.length,
                          itemBuilder: (context, index) {
                            final caseItem = allCases[index];

                            final bool isHighlighted = _isSearching &&
                                _filteredCases.isNotEmpty &&
                                _currentResultIndex < _resultTabs.length &&
                                _resultTabs[_currentResultIndex] ==
                                    '$selectedYear-$month' &&
                                _filteredCases[_currentResultIndex].caseNo ==
                                    caseItem.caseNo;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: CaseCard(
                                key: ValueKey(
                                    '${caseItem.caseNo}-${caseItem.courtName}'),
                                caseItem: caseItem,
                                isHighlighted: isHighlighted,
                              ),
                            );
                          },
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarAndDropdown() {
    var screenWidth = MediaQuery.of(context).size.width;

    if (_tabController == null || monthsWithCases.isEmpty) {
      return Container(
        color: const Color(0xFFF3F3F3),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [_buildYearDropdown()],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF3F3F3),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController!,
                isScrollable: true,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.black,
                indicatorWeight: 2.5,
                labelPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                tabs: monthsWithCases.map((month) => Tab(text: month)).toList(),
              ),
            ),
          ),
          _buildYearDropdown(),
        ],
      ),
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButton<String>(
      value: selectedYear,
      icon: const Icon(Icons.arrow_drop_down_rounded,
          color: Colors.black, size: 28),
      elevation: 2,
      style: const TextStyle(
          color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
      underline: const SizedBox.shrink(),
      onChanged: (String? newValue) {
        if (newValue != null && newValue != selectedYear) {
          if (!mounted) return;
          setState(() {
            selectedYear = newValue;
            monthsWithCases = _getMonthsForYear(selectedYear!);

            if (monthsWithCases.isNotEmpty) {
              _setupTabController();

              _searchQuery = '';
              _searchController.clear();
              _filteredCases = [];
              _resultTabs = [];
              _currentResultIndex = 0;
            } else {
              _tabController?.dispose();
              _tabController = null;
            }
          });
        }
      },
      dropdownColor: Colors.white,
      items: years.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
