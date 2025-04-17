import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// Assuming these imports are correct
import '../../components/basicUIcomponent.dart';
import '../../components/case_card.dart';
import '../../components/list_app_bar.dart';
import '../../models/case_list.dart';
import '../../services/case_services.dart'; // Contains populateCaseData, caseData, years
import '../../utils/constants.dart'; // Contains months list

class CaseHistoryScreen extends StatefulWidget {
  const CaseHistoryScreen({super.key});

  @override
  CaseHistoryScreenState createState() => CaseHistoryScreenState();
}

class CaseHistoryScreenState extends State<CaseHistoryScreen>
    with TickerProviderStateMixin {
  // Use nullable TabController initially
  TabController? _tabController;
  String? selectedYear; // Make nullable initially
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<CaseListData> _filteredCases = [];
  int _currentResultIndex = 0;
  List<String> _resultTabs = [];
  List<String> monthsWithCases = []; // Initialize as empty
  // Future to track the initialization process
  late Future<bool> _caseDataInitializationFuture; // Changed type to bool
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> caseCardKeys =
      {}; // Consider if this is still needed with simpler scrolling

  FocusNode fn = FocusNode();

  // Flag to track if data was successfully loaded
  bool _hasCaseData = false;

  @override
  void initState() {
    super.initState();
    // Start the initialization process
    _caseDataInitializationFuture = _initializeCaseData();
  }

  // --- Modified Initialization ---
  Future<bool> _initializeCaseData() async {
    try {
      // 1. Explicitly call populateCaseData and wait for it
      await populateCaseData(); // Assuming this populates global 'caseData' and 'years'

      // 2. Check if caseData is populated AFTER the fetch
      if (caseData.isEmpty) {
        if (kDebugMode) {
          print("Initialization complete: No case data found.");
        }
        _hasCaseData = false;
        // No need to set up tabs if there's no data at all
        return false; // Indicate no data was loaded
      }

      // 3. Proceed with setup ONLY if data exists
      _hasCaseData = true;
      if (kDebugMode) {
        print("Initialization complete: Case data found.");
      }

      if (years.isNotEmpty) {
        // Use 'mounted' check before calling setState
        if (mounted) {
          setState(() {
            // Set initial selected year
            selectedYear = years.last;
            monthsWithCases = _getMonthsForYear(
                selectedYear!); // Use ! because years is not empty

            if (monthsWithCases.isNotEmpty) {
              _setupTabController();
            } else {
              // Handle case where the latest year has no months with data
              // Try finding the most recent year *with* data
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
                // Should not happen if caseData wasn't empty, but as fallback:
                _hasCaseData = false; // Mark as no displayable data
                if (kDebugMode)
                  print("Data exists, but no months found for any year.");
              }
            }
          });
        } else {
          // If not mounted during async gap, handle appropriately
          // This scenario is less likely here but good practice
          return _hasCaseData; // Return current known state
        }
      } else {
        // caseData is not empty, but years list is somehow empty - data inconsistency
        _hasCaseData = false;
        if (kDebugMode)
          print(
              "Data inconsistency: caseData populated but years list is empty.");
      }
      return _hasCaseData; // Return true if setup was successful
    } catch (e) {
      print("Error during case data initialization: $e");
      _hasCaseData = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading case history: $e')),
        );
      }
      return false; // Indicate failure
    }
  }

  void _setupTabController() {
    // Dispose existing controller if any (relevant for year changes)
    _tabController?.dispose();

    _tabController = TabController(
      length: monthsWithCases.length,
      vsync: this,
    );

    // Try setting initial index to current month if available
    final currentMonthIndex = DateTime.now().month - 1;
    final availableMonthsIndexes =
        monthsWithCases.map((month) => months.indexOf(month)).toList();

    int initialTabIndex = 0; // Default to first available month
    if (selectedYear == DateTime.now().year.toString() &&
        availableMonthsIndexes.contains(currentMonthIndex)) {
      initialTabIndex = availableMonthsIndexes.indexOf(currentMonthIndex);
    }

    // Ensure initialTabIndex is valid for the current monthsWithCases
    if (initialTabIndex >= monthsWithCases.length) {
      initialTabIndex = 0;
    }

    _tabController!.index = initialTabIndex; // Set initial index directly

    // Add listener *after* setting initial index
    _tabController!.addListener(() {
      // Use mounted check inside listener
      if (mounted && !_tabController!.indexIsChanging) {
        setState(
            () {}); // Rebuild to update UI based on tab change if necessary
      }
    });
  }

  List<String> _getMonthsForYear(String year) {
    if (!caseData.containsKey(year)) return [];

    // Use the constant list from utils/constants.dart
    List<String> monthOrder = months; // Assuming 'months' is your constant list

    List<String> availableMonths = caseData[year]
            ?.entries
            // Ensure value (list of cases) is not null AND not empty
            .where((entry) => entry.value.isNotEmpty)
            .map((entry) => entry.key)
            .toList() ??
        [];

    // Sort based on the predefined month order
    availableMonths
        .sort((a, b) => monthOrder.indexOf(a).compareTo(monthOrder.indexOf(b)));

    return availableMonths;
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Safely dispose nullable controller
    _searchController.dispose();
    _scrollController.dispose();
    fn.dispose(); // Dispose focus node
    super.dispose();
  }

  // --- Search and Filter Logic (Mostly Unchanged, added safety checks) ---

  void _updateFilteredCases() {
    if (!mounted) return; // Safety check
    setState(() {
      _filteredCases.clear();
      _resultTabs.clear();
      _currentResultIndex = 0; // Reset index on new search

      if (_searchQuery.isEmpty) return; // Don't filter if query is empty

      // Iterate through all years and months in the cached data
      caseData.forEach((year, monthlyCases) {
        monthlyCases.forEach((month, cases) {
          final results = _filterCases(cases);
          if (results.isNotEmpty) {
            _filteredCases.addAll(results);
            // Store unique identifier for the result's origin
            _resultTabs.addAll(List.filled(results.length, '$year-$month'));
          }
        });
      });

      if (kDebugMode) {
        print('Filtered Cases Count: ${_filteredCases.length}');
        // print('Result Tabs: $_resultTabs');
      }

      // If results are found, switch to the first one
      if (_filteredCases.isNotEmpty) {
        _switchTabToResult(); // Navigate to the first result
      } else {
        // Optional: Show feedback if search yields no results
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No cases found matching search criteria.')));
      }
    });
  }

  List<CaseListData> _filterCases(List<CaseListData> cases) {
    if (_searchQuery.isEmpty) return []; // Return empty if no query
    // Ensure search query is lowercase for case-insensitive search
    final query = _searchQuery.toLowerCase();
    return cases.where((caseItem) {
      // Check each field, ensuring null safety and converting to lowercase
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
    // --- Handle Year Change ---
    if (selectedYear != targetYear) {
      if (!years.contains(targetYear)) {
        if (kDebugMode)
          print(
              "🚨 Target year $targetYear not found in available years list.");
        return; // Cannot switch to a year that doesn't exist in dropdown
      }
      // Use mounted check before setState
      if (!mounted) return;
      setState(() {
        selectedYear = targetYear;
        monthsWithCases =
            _getMonthsForYear(selectedYear!); // Update months for the new year
        yearChanged = true; // Flag that year changed
      });
      // If year changed, we need to potentially recreate or reset the TabController
      // Wait for the state to update before setting up the controller again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && monthsWithCases.isNotEmpty) {
          _setupTabController(); // Recreate controller for the new set of months
          // Now find the month index *after* controller is set up
          _findAndAnimateToMonth(targetMonth);
        } else if (mounted) {
          // Handle case where the target year has no months (should be rare if filter found a case)
          if (kDebugMode)
            print(
                "🚨 Target year $targetYear has no months with data after switching.");
        }
      });
    } else {
      // Year did not change, just find the month and animate
      _findAndAnimateToMonth(targetMonth);
    }
  }

  void _findAndAnimateToMonth(String targetMonth) {
    if (!mounted || _tabController == null) return; // Ensure controller exists

    final monthIndex = monthsWithCases.indexOf(targetMonth);
    if (monthIndex != -1) {
      if (_tabController!.length > monthIndex) {
        // Check index validity
        _tabController!.animateTo(monthIndex);
        // Scroll to the specific case *after* tab animation likely started/finished
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCaseCard(
              targetYear: selectedYear!,
              targetMonth: targetMonth); // Pass current selectedYear
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

    // Get the cases for the currently visible tab
    final allCasesInCurrentTab = getCaseDataForMonth(targetYear, targetMonth);
    if (allCasesInCurrentTab.isEmpty) {
      if (kDebugMode)
        print(
            "🚨 Cannot scroll: No cases found for $targetYear-$targetMonth in current view.");
      return;
    }

    // Find the index of the highlighted case *within the list currently displayed in the tab*
    final caseToHighlight = _filteredCases[_currentResultIndex];
    final indexInCurrentTab = allCasesInCurrentTab.indexWhere(
      (caseItem) =>
          caseItem.caseNo ==
          caseToHighlight.caseNo, // Assuming caseNo is a unique identifier
    );

    if (indexInCurrentTab >= 0) {
      // Estimate height - THIS IS A MAJOR SOURCE OF INACCURACY
      // A better way is using ScrollablePositionedList or measuring the item.
      const double estimatedCardHeight =
          200.0; // Adjust this based on your CaseCard's typical height
      double scrollOffset = indexInCurrentTab * estimatedCardHeight;

      // Clamp the offset to prevent scrolling beyond bounds
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

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      // Use the boolean future
      future: _caseDataInitializationFuture,
      builder: (context, snapshot) {
        // --- 1. Handle Loading State ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
                title: const Text("Case History"),
                elevation: 0,
                backgroundColor: const Color(0xFFF3F3F3)), // Basic AppBar
            body: const Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        // --- 2. Handle Error State ---
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

        // --- 3. Handle No Data State (after Future completes) ---
        // Check the _hasCaseData flag set during initialization
        if (!_hasCaseData) {
          return Scaffold(
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
              elevation: 0,
              leading: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/back_arrow.svg',
                  width: 24, // Adjusted size
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
                  "No case history found.", // Clear message
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // --- 4. Build Main UI (if data exists) ---
        // At this point, snapshot has completed successfully and _hasCaseData is true.
        // selectedYear and potentially _tabController should be initialized.

        // Function to handle search disposal
        void disposalFunc() {
          if (!mounted) return;
          _searchController.clear();
          fn.unfocus(); // Remove focus
          setState(() {
            _searchQuery = '';
            _filteredCases = [];
            _resultTabs = [];
            _currentResultIndex = 0;
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF3F3F3),
          // Use the ListAppBar component
          appBar: ListAppBar(
            title: "Case History",
            isSearching: _isSearching,
            onSearchPressed: () {
              if (!mounted) return;
              setState(() {
                _isSearching = !_isSearching;
                if (_isSearching) {
                  fn.requestFocus(); // Request focus when starting search
                } else {
                  disposalFunc(); // Clear search when stopping
                }
              });
            },
            onFilterPressed: null, // No filter action defined here
            searchController: _searchController, // Pass controller
            searchFocusNode: fn, // Pass focus node
            onSearchChanged: (value) {
              // Handle text changes
              if (!mounted) return;
              setState(() {
                _searchQuery = value.toLowerCase();
                _updateFilteredCases();
              });
            },
            // Pass search result navigation callbacks
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
          // Build the main body content (Tabs and List)
          body: _buildBodyContent(),
        );
      },
    );
  }

  Widget _buildBodyContent() {
    // Ensure selectedYear and _tabController are initialized before building this part
    if (selectedYear == null || _tabController == null) {
      // This should ideally not be reached if _hasCaseData is true,
      // but acts as a fallback during initial builds or state inconsistencies.
      return const Center(
        child: Text(
          "Loading year/month data...",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    // Handle case where a year is selected, but it has no months with data
    if (monthsWithCases.isEmpty) {
      return Column(
        // Wrap in column to allow year dropdown to show
        children: [
          _buildTabBarAndDropdown(), // Show dropdown even if no months
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

    // --- Main Content: Tabs and List View ---
    return Column(
      children: [
        // Extracted TabBar and Dropdown widget
        _buildTabBarAndDropdown(),

        // Expanded TabBarView to fill remaining space
        Expanded(
          child: TabBarView(
            controller: _tabController!, // Use ! as we checked for null
            children: monthsWithCases.map((month) {
              // Get cases for the current tab's month and year
              final allCases = getCaseDataForMonth(selectedYear!, month);

              // Build the list view for the current tab
              return Container(
                // Removed margin here, apply padding inside ListView if needed
                child: RefreshIndicator(
                  color: AppTheme.getRefreshIndicatorColor(
                      Theme.of(context).brightness),
                  backgroundColor:
                      AppTheme.getRefreshIndicatorBackgroundColor(),
                  onRefresh: () async {
                    await _initializeCaseData(); // Re-run initialization on refresh
                  },
                  child: allCases.isEmpty
                      // Display message if a specific month has no cases (should be rare if month is in list)
                      ? LayoutBuilder(
                          // Ensure it's scrollable for RefreshIndicator
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
                      // Display the list of cases for the month
                      : ListView.builder(
                          controller:
                              _scrollController, // Attach scroll controller
                          // Add padding around the list itself
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          // Use physics that allows RefreshIndicator to work
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: allCases.length,
                          itemBuilder: (context, index) {
                            final caseItem = allCases[index];
                            // Determine if the current card should be highlighted based on search
                            final bool isHighlighted = _isSearching &&
                                _filteredCases.isNotEmpty &&
                                _currentResultIndex <
                                    _resultTabs.length && // Bounds check
                                _resultTabs[_currentResultIndex] ==
                                    '$selectedYear-$month' &&
                                _filteredCases[_currentResultIndex].caseNo ==
                                    caseItem.caseNo;

                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 12.0), // Spacing between cards
                              child: CaseCard(
                                // Consider using caseItem.id if available and unique
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

  // Helper widget for TabBar and Year Dropdown
  Widget _buildTabBarAndDropdown() {
    var screenWidth = MediaQuery.of(context).size.width;
    // Ensure controller exists before building TabBar
    if (_tabController == null || monthsWithCases.isEmpty) {
      // Build only the dropdown if tabs aren't ready or needed
      return Container(
        color: const Color(0xFFF3F3F3),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.end, // Align dropdown to the right
          children: [_buildYearDropdown()], // Call the dropdown builder
        ),
      );
    }

    return Container(
      color: const Color(0xFFF3F3F3),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          // TabBar container with flexible width
          Expanded(
            // Allow TabBar to take available space
            child: Container(
              // color: Colors.red, // Debug color
              alignment: Alignment.centerLeft, // Align tabs to the left
              child: TabBar(
                controller:
                    _tabController!, // Use '!' since we checked for null
                isScrollable: true, // Allow scrolling if many months
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.black,
                indicatorWeight: 2.5,
                labelPadding: const EdgeInsets.symmetric(
                    horizontal: 18.0), // Adjust padding
                // labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500), // Optional: Customize label style
                // unselectedLabelStyle: TextStyle(fontSize: 15), // Optional: Customize unselected style
                tabs: monthsWithCases.map((month) => Tab(text: month)).toList(),
              ),
            ),
          ),
          // Year Dropdown (fixed position on the right)
          _buildYearDropdown(), // Call the dropdown builder
        ],
      ),
    );
  }

  // Helper widget specifically for the Year DropdownButton
  Widget _buildYearDropdown() {
    return DropdownButton<String>(
      value: selectedYear, // Current selected year
      icon: const Icon(Icons.arrow_drop_down_rounded,
          color: Colors.black, size: 28),
      elevation: 2, // Add slight elevation to dropdown
      style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500), // Style for selected item
      underline: const SizedBox.shrink(), // Remove the default underline
      onChanged: (String? newValue) {
        if (newValue != null && newValue != selectedYear) {
          // Use mounted check before setState
          if (!mounted) return;
          setState(() {
            selectedYear = newValue;
            monthsWithCases =
                _getMonthsForYear(selectedYear!); // Get months for new year
            // Important: Re-setup or reset TabController for the new months
            if (monthsWithCases.isNotEmpty) {
              _setupTabController(); // Dispose old, create new
              // Clear search results when year changes
              _searchQuery = '';
              _searchController.clear();
              _filteredCases = [];
              _resultTabs = [];
              _currentResultIndex = 0;
            } else {
              _tabController?.dispose(); // Dispose if no months
              _tabController = null;
            }
          });
        }
      },
      dropdownColor: Colors.white, // Background color of the dropdown menu
      items: years.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
