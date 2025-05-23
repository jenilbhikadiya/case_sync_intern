import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../components/basicUIcomponent.dart';
import '../../components/case_counter_card.dart';
import '../../components/list_app_bar.dart';
import '../../models/case.dart';
import '../../utils/constants.dart';

class CounterCases extends StatefulWidget {
  const CounterCases({super.key});

  @override
  State<CounterCases> createState() => CounterCasesState();
}

class CounterCasesState extends State<CounterCases> {
  bool _isLoading = true;
  List<Case> _caseList = [];
  List<Case> _filteredCases = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedCity;
  String? _selectedCourt;
  final List<String> _cities = [];
  final List<String> _courts = [];
  late String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _errorMessage = '';
    fetchCases();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _updateFilteredCases();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int> fetchCases([bool isOnPage = true]) async {
    try {
      _errorMessage = '';
      final url = Uri.parse('$baseUrl/get_case_counter');

      var request = http.MultipartRequest('POST', url);
      request.fields['intern_id'] = '8'; // Replace with dynamic value if needed

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _caseList = (data['data'] as List)
              .map((item) => Case.fromJson(item))
              .toList();

          if (isOnPage) {
            setState(() {
              _filteredCases = List.from(_caseList);
              _cities.addAll(_caseList.map((c) => c.cityName).toSet());
              _courts.addAll(_caseList.map((c) => c.courtName).toSet());
            });
          }

          print('Total Cases: ${_caseList.length}');
          return _caseList.length;
        } else {
          _showError("No cases found.");
          print("API returned success = false.");
        }
      } else {
        _showError("Failed to fetch cases.");
        print("Failed API response: ${response.statusCode}");
      }
    } catch (e) {
      _showError("An error occurred: $e");
      print("Exception: $e");
    } finally {
      if (isOnPage) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    return 0;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Search by case number, applicant, court, or city',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _searchController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ListAppBar(
        title: "Case Counters",
        isSearching: false,
        showSearch: false,
        onSearchPressed: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchController.clear();
            }
          });
        },
      ),
      backgroundColor: const Color(0xFFF3F3F3),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                    color: Colors.black,
                  ))
                : (_errorMessage.isNotEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    fetchCases();
                                  });
                                },
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _filteredCases.isEmpty
                        ? const Center(child: Text('No cases found.'))
                        : RefreshIndicator(
                            color: AppTheme.getRefreshIndicatorColor(
                                Theme.of(context).brightness),
                            backgroundColor:
                                AppTheme.getRefreshIndicatorBackgroundColor(),
                            onRefresh: () async {
                              setState(() {
                                fetchCases();
                              });
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _filteredCases.length,
                              itemBuilder: (context, index) {
                                final caseItem = _filteredCases[index];
                                return CaseCounterCard(caseItem: caseItem);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
