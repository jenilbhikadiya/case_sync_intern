import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../models/task_item_list.dart';

class TaskInfoScreen extends StatelessWidget {
  final TaskItem taskItem;

  const TaskInfoScreen({required this.taskItem, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
      backgroundColor: const Color(0xFFF3F3F3),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF3F3F3),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/back_arrow.svg',
          color: Colors.black,
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
        },
      ),
      title: const Text(
        'Task Details',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _buildDetailsCard(details: taskItem.toJson()),
    );
  }

  Widget _buildDetailsCard({required Map<String, dynamic> details}) {
    // Grouping details into sections with correct order
    final Map<String, List<MapEntry<String, dynamic>>> groupedDetails = {
      'General Info': [
        details.entries.firstWhere((e) => e.key == 'caseNo'),
        details.entries.firstWhere((e) => e.key == 'status'),
      ],
      'Assignment Details': [
        details.entries.firstWhere((e) => e.key == 'allotedBy'),
        details.entries.firstWhere((e) => e.key == 'allotedTo'),
      ],
      'Dates': [
        details.entries.firstWhere((e) => e.key == 'allotedDate'),
        details.entries.firstWhere((e) => e.key == 'expectedEndDate'),
      ],
      'Instruction': [
        details.entries.firstWhere((e) => e.key == 'instruction'),
      ],
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(
          color: Colors.black,
          width: 1,
        ),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dynamically build sections
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
                    const SizedBox(height: 8),
                    // Special handling for 'Instruction' section
                    if (section.key == 'Instruction') ...[
                      // Display the instruction value directly
                      Text(
                        section.value.first.value?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ] else ...[
                      // Key-Value Pairs for other sections
                      ...section.value.map((entry) {
                        String displayValue;

                        // Handle date formatting
                        if (['allotedDate', 'expectedEndDate']
                            .contains(entry.key)) {
                          displayValue = _formatDate(entry.value);
                        } else if (entry.value == null ||
                            entry.value.toString().isEmpty ||
                            entry.value == '0000-00-00') {
                          displayValue = '-';
                        } else {
                          displayValue = entry.value.toString();
                        }

                        // Convert the key to a more readable format if needed
                        String displayKey = _formatKey(entry.key);

                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    displayKey,
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
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            if (section.value.last != entry)
                              const Divider(
                                thickness: 1,
                                color: Colors.black38,
                              ),
                          ],
                        );
                      }),
                    ],
                  ],
                ),
              );
            }),
            // Spacer to add some bottom padding
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper method to format keys for display
  String _formatKey(String key) {
    // Convert camelCase to Title Case (e.g., 'allotedBy' -> 'Alloted By')
    return key
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .capitalize();
  }

  // Helper method to format date strings
  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty || date == '0000-00-00') {
      return 'No Date';
    }
    try {
      DateTime parsedDate;
      if (date is DateTime) {
        parsedDate = date;
      } else {
        parsedDate = DateTime.parse(date.toString());
      }
      return DateFormat('EEE, MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }
}

// Extension to capitalize the first letter of each word
extension StringCasingExtension on String {
  String capitalize() {
    return this
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
