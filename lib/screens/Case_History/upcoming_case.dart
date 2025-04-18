import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../components/filter_modal.dart';
import '../../components/list_app_bar.dart';
import '../../components/upoming_case_card.dart';
import '../../models/case_list.dart';
import '../../utils/constants.dart';

class UpcomingCases extends StatefulWidget {
  const UpcomingCases({super.key});

  @override
  State<UpcomingCases> createState() => UpcomingCasesState();
}

class UpcomingCasesState extends State<UpcomingCases>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, List<CaseListData>> _casesByDate = {};
  String _errorMessage = '';
  List<String> _dates = [];
  late TabController _tabController;
  String _selectedTabDate = '';
  DateTime _selectedDate = DateTime.now();
  String? _selectedCity;
  String? _selectedCourt;
  List<String> _cities = [];
  List<String> _courts = [];
  Map<String, List<CaseListData>> _originalCasesByDate = {};

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<CaseListData> _filteredCases = [];
  final List<String> _resultTabs = [];
  int _currentResultIndex = 0;
  Map<int, GlobalKey> caseCardKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCases(_selectedDate);
  }

  void _applyFilters() {
    setState(() {
      _casesByDate = _originalCasesByDate.map<String, List<CaseListData>>(
        (key, value) => MapEntry(
          key,
          value
              .where((caseItem) =>
                  (_selectedCity == null ||
                      _selectedCity == "All" ||
                      caseItem.cityName == _selectedCity) &&
                  (_selectedCourt == null ||
                      _selectedCourt == "All" ||
                      caseItem.courtName == _selectedCourt))
              .toList(),
        ),
      );
      _updateFilteredCases(); // Ensure search is applied after filtering
    });
  }

  void _updateFilteredCases() {
    setState(() {
      _filteredCases.clear();
      _resultTabs.clear();

      _casesByDate.forEach((date, cases) {
        // Search within filtered cases
        final results = _filterCases(cases);
        if (results.isNotEmpty) {
          _filteredCases.addAll(results);
          _resultTabs.addAll(List.filled(results.length, date));
        }
      });

      if (_filteredCases.isNotEmpty) {
        _currentResultIndex = 0;
        _switchTabToResult();
      }
    });
  }

  List<CaseListData> _filterCases(List<CaseListData> cases) {
    return cases.where((caseItem) {
      if (_searchQuery.isNotEmpty) {
        return caseItem.caseNo.toLowerCase().contains(_searchQuery) ||
            caseItem.courtName.toLowerCase().contains(_searchQuery) ||
            caseItem.cityName.toLowerCase().contains(_searchQuery) ||
            caseItem.handleBy.toLowerCase().contains(_searchQuery) ||
            caseItem.applicant.toLowerCase().contains(_searchQuery) ||
            caseItem.opponent.toLowerCase().contains(_searchQuery);
      } else {
        return false;
      }
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

    final targetDate = _resultTabs[_currentResultIndex];
    final targetIndex = _dates.indexOf(targetDate);

    if (targetIndex != -1) {
      _tabController.animateTo(targetIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allCases = _casesByDate[targetDate] ?? [];
      final highlightedIndex = allCases.indexWhere(
        (caseItem) =>
            caseItem.caseNo == _filteredCases[_currentResultIndex].caseNo,
      );

      if (highlightedIndex >= 0 && caseCardKeys.containsKey(highlightedIndex)) {
        final context = caseCardKeys[highlightedIndex]!.currentContext;
        if (context == null) return;

        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;

        double caseCardHeight = box.size.height;
        double scrollOffset = (highlightedIndex * caseCardHeight);
        double maxScrollExtent = _scrollController.position.maxScrollExtent;

        if (scrollOffset > maxScrollExtent) scrollOffset = maxScrollExtent;
        if (scrollOffset < 0) scrollOffset = 0;

        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  Future<void> _fetchCases(DateTime date) async {
    try {
      _errorMessage = '';
      String previousSelectedTabDate = _selectedTabDate;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/upcoming_cases"),
      );
      String strDate = DateFormat('yyyy-MM-dd').format(date);
      request.fields['data'] = json.encode({'date': strDate});
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData) as Map<String, dynamic>;
        setState(() {
          _originalCasesByDate = data.map<String, List<CaseListData>>(
            (key, value) => MapEntry(
              key,
              (value as List)
                  .map((item) => CaseListData.fromJson(item))
                  .toList(),
            ),
          );
          _applyFilters();

          _dates = _casesByDate.keys.toList();
          if (_dates.isNotEmpty) {
            if (_dates.contains(previousSelectedTabDate)) {
              _selectedTabDate = previousSelectedTabDate;
            } else {
              _selectedTabDate = _dates.first;
            }

            _tabController = TabController(length: _dates.length, vsync: this);
            _tabController.index = _dates.indexOf(_selectedTabDate);
            _tabController.addListener(() {
              setState(() {
                _selectedTabDate = _dates[_tabController.index];
              });
            });
          }

          // Extract unique cities and courts from the case data
          if (_cities.isEmpty) {
            _cities = _casesByDate.values
                .expand((cases) => cases.map((c) => c.cityName))
                .toSet()
                .toList();
          }
          if (_courts.isEmpty) {
            _courts = _casesByDate.values
                .expand((cases) => cases.map((c) => c.courtName))
                .toSet()
                .toList();
          }

          _isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load cases. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      log('Error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: ListAppBar(
          title: "Upcoming Cases",
          isSearching: _isSearching,
          showSearchField: false,
          onSearchPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchQuery = '';
                _filteredCases.clear();
                _resultTabs.clear();
              }
            });
          },
          onFilterPressed: () {
            FilterModal.showFilterModal(
              context,
              selectedCity: _selectedCity,
              selectedCourt: _selectedCourt,
              selectedNextDate: _selectedDate,
              cities: _cities,
              courts: _courts,
              onCitySelected: (value) {
                setState(() {
                  _selectedCity = value;
                  _applyFilters();
                });
              },
              onCourtSelected: (value) {
                setState(() {
                  _selectedCourt = value;
                  _applyFilters();
                });
              },
              onDateSelected: (value) {
                if (value != null && value != _selectedDate) {
                  setState(() {
                    _selectedDate = value;
                  });
                  _fetchCases(_selectedDate);
                }
              },
              onApply: () {
                _fetchCases(_selectedDate);
              },
              onReset: () {
                setState(() {
                  _selectedCity = null;
                  _selectedCourt = null;
                  _selectedDate = DateTime.now();
                });
                _fetchCases(_selectedDate);
              },
            );
          },
        ),
        backgroundColor: const Color(0xFFF3F3F3),
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
                          if (_searchController.text.trim() != '') {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                              _updateFilteredCases();
                            });
                          } else {
                            setState(() {
                              _searchQuery = '';
                              _filteredCases.clear();
                              _resultTabs.clear();
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search cases...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _filteredCases.clear();
                                      _resultTabs.clear();
                                    });
                                  },
                                )
                              : null, // Show clear button only when there's text
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _currentResultIndex > 0
                                ? _navigateToPreviousResult
                                : null),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _switchTabToResult();
                            });
                          },
                          child: Text(
                            '${_filteredCases.isEmpty ? 0 : _currentResultIndex + 1} / ${_filteredCases.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed:
                                _currentResultIndex < _filteredCases.length - 1
                                    ? _navigateToNextResult
                                    : null),
                      ],
                    ),
                  ],
                ),
              ),
            if (_dates.isNotEmpty)
              TabBar(
                tabAlignment: TabAlignment.center,
                indicatorAnimation: TabIndicatorAnimation.elastic,
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.black,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: _dates
                    .map(
                      (date) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Tab(
                          text: date,
                        ),
                      ),
                    )
                    .toList(),
              ),
            Expanded(
              child: LiquidPullToRefresh(
                backgroundColor: Colors.black,
                color: Colors.transparent,
                showChildOpacityTransition: false,
                onRefresh: () async {
                  _fetchCases(_selectedDate);
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity! < 0) {
                          if (_tabController.index < _dates.length - 1) {
                            _tabController.animateTo(_tabController.index + 1);
                          }
                        } else if (details.primaryVelocity! > 0) {
                          if (_tabController.index > 0) {
                            _tabController.animateTo(_tabController.index - 1);
                          }
                        }
                      },
                      child: (_isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.black))
                          : _errorMessage.isNotEmpty
                              ? Center(child: Text(_errorMessage))
                              : (_casesByDate[_selectedTabDate]?.isEmpty ??
                                      true)
                                  ? const Center(
                                      child: Text(
                                          "No cases available for this date."))
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16.0),
                                      itemCount: _casesByDate[_selectedTabDate]
                                              ?.length ??
                                          0,
                                      itemBuilder: (context, index) {
                                        final caseItem = _casesByDate[
                                            _selectedTabDate]![index];
                                        caseCardKeys[index] = GlobalKey();

                                        bool isHighlighted = _isSearching &&
                                            _filteredCases.isNotEmpty &&
                                            _resultTabs[_currentResultIndex] ==
                                                _selectedTabDate &&
                                            _filteredCases[_currentResultIndex]
                                                    .caseNo ==
                                                caseItem.caseNo;

                                        return Container(
                                          key: caseCardKeys[index],
                                          child: UpcomingCaseCard(
                                            caseItem: caseItem,
                                            isHighlighted: isHighlighted,
                                            updateCases: _fetchCases,
                                          ),
                                        );
                                      },
                                    )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
