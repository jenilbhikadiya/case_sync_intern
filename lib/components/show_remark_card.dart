import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/constants.dart';

class RemarkCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> remark;

  const RemarkCard({Key? key, required this.index, required this.remark})
      : super(key: key);

  @override
  State<RemarkCard> createState() => _RemarkCardState();
}

class _RemarkCardState extends State<RemarkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateTap() {
    _animationController.forward().then((_) => _animationController.reverse());
  }

  String _formatDate(String? dateString) {
    try {
      if (dateString == null ||
          dateString.isEmpty ||
          dateString == "0000-00-00" ||
          dateString.startsWith("0000")) {
        return 'N/A';
      }
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  TableRow _buildTableRow(IconData icon, String label, Widget valueWidget,
      {bool isTitle = false}) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: Colors.grey, width: 0.2), // Light bottom border
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontWeight: isTitle ? FontWeight.bold : FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 15),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: DefaultTextStyle(
            style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: isTitle ? FontWeight.bold : FontWeight.normal),
            child: valueWidget,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: _animateTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin:
                const EdgeInsets.symmetric(vertical: 5.0), // Matching margin
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12), // Matching borderRadius
              border: Border.all(
                color: Colors.black.withOpacity(0.5), // Light border
                width: 0.5, // Matching border width
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), // Matching boxShadow
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Matching padding
              child: Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: FlexColumnWidth(),
                },
                border: TableBorder.all(
                  color: Colors.grey.shade200, // Light grey table border
                  width: 0.3,
                ),
                children: [
                  _buildTableRow(
                    Icons.format_list_numbered,
                    'SR. No.',
                    Text(
                      ((widget.index + 1).toString()),
                      style: const TextStyle(fontSize: 16),
                    ),
                    isTitle: true,
                  ),
                  _buildTableRow(
                    Icons.text_snippet_outlined,
                    'Remark',
                    Text(widget.remark['remarks'] ?? 'N/A'),
                  ),
                  _buildTableRow(Icons.image_outlined, 'Stage',
                      Text(widget.remark['stage'] ?? 'N/A')),
                  _buildTableRow(Icons.person_outline, 'Added By',
                      Text(widget.remark['added_by'] ?? 'N/A')),
                  _buildTableRow(Icons.calendar_today_outlined, 'Remark Date',
                      Text(_formatDate(widget.remark['dos']))),
                  _buildTableRow(
                    Icons.label_outline,
                    'Status',
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 5),
                        decoration: BoxDecoration(
                          color: getStatusColor(widget.remark['status'])
                                  .withOpacity(0.8) ??
                              Colors.grey.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.remark['status']?.toUpperCase() ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
