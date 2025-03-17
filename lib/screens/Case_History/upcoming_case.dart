import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intern_side/utils/constants.dart';

import '../../components/list_app_bar.dart';
import '../../components/todays_case_card.dart';
import '../../models/case.dart';

class CasesPage extends StatefulWidget {
  @override
  _CasesPageState createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false; // For controlling the search box visibility
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> casesData = {};
  bool isLoading = true;
  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedCourt;
  final List<String> _cities = [];
  final List<String> _courts = [];
  List<Case> _caseList = [];
  List<Case> _filteredCases = [];
  List<Case> todayCases = [];
  List<Case> tomorrowCases = [];
  List<Case> dayAfterCases = [];
  List<Case> filteredCases = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchCases();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        // Perform search logic if needed
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchCases() async {
    final url = Uri.parse('$baseUrl/upcoming_cases');

    // Generate dates for today, tomorrow, and the day after
    final today = DateTime.now();
    final tomorrow = today.add(Duration(days: 1));
    final dayAfter = today.add(Duration(days: 2));

    final formattedToday =
        '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
    final formattedTomorrow =
        '${tomorrow.year}/${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.day.toString().padLeft(2, '0')}';
    final formattedDayAfter =
        '${dayAfter.year}/${dayAfter.month.toString().padLeft(2, '0')}/${dayAfter.day.toString().padLeft(2, '0')}';

    // Prepare API body
    print("Today's Cases: $todayCases");
    print("Tomorrow's Cases: $tomorrowCases");
    print("Day After Cases: $dayAfterCases");

    final body = {'data': '{"date":"$formattedToday"}'};

    try {
      final response = await http.post(url, body: body);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Fetched Data from API: $responseData");

        setState(() {
          // Safely handle null values
          todayCases = (responseData[formattedToday] as List?)
                  ?.map((item) => Case.fromJson(item))
                  .toList() ??
              []; // Use empty list if null
          tomorrowCases = (responseData[formattedTomorrow] as List?)
                  ?.map((item) => Case.fromJson(item))
                  .toList() ??
              [];
          dayAfterCases = (responseData[formattedDayAfter] as List?)
                  ?.map((item) => Case.fromJson(item))
                  .toList() ??
              [];

          // Initialize filtered cases with today's cases
          filteredCases = List.from(todayCases);

          isLoading = false;
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search Cases',
          hintText: 'Search by case number, applicant, court, or city',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCity,
                hint: const Text('Select City'),
                items: ['All', ..._cities]
                    .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                    _updateFilteredCases();
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCourt,
                hint: const Text('Select Court'),
                items: ['All', ..._courts]
                    .map((court) => DropdownMenuItem(
                          value: court,
                          child: Text(court),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourt = value;
                    _updateFilteredCases();
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the filter panel
                  _updateFilteredCases();
                },
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateFilteredCases() {
    setState(() {
      _filteredCases = _caseList.where((caseItem) {
        final matchesSearchQuery = caseItem.caseNo
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem.applicant
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem.courtName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem.cityName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesCity = _selectedCity == null ||
            _selectedCity == 'All' ||
            caseItem.cityName == _selectedCity;
        final matchesCourt = _selectedCourt == null ||
            _selectedCourt == 'All' ||
            caseItem.courtName == _selectedCourt;

        return matchesSearchQuery && matchesCity && matchesCourt;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ListAppBar(
        title: "Today's Cases",
        isSearching: _isSearching,
        onSearchPressed: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchController.clear();
            }
          });
        },
        onFilterPressed: _showFilterOptions, // Add this line
      ),
      body: Column(
        children: [
          // Show search bar if search is active
          if (_isSearching) _buildSearchBar(),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Tomorrow'),
              Tab(text: 'Day After'),
            ],
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      buildCaseList(
                          filteredCases), // Today's cases with filters
                      buildCaseList(tomorrowCases), // Tomorrow's cases
                      buildCaseList(
                          dayAfterCases), // Day After Tomorrow's cases
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildCaseList(List<Case> cases) {
    if (cases.isEmpty) {
      return Center(child: Text('No cases available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final caseItem = cases[index];
        return TodaysCaseCard(caseItem: caseItem);
      },
    );
  }
}
