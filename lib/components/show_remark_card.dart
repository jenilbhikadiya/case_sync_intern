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
  bool _isExpanded = false;

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
    setState(() {
      _isExpanded = !_isExpanded;
    });
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _animateTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withOpacity(0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with always visible information
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          (widget.index + 1).toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.remark['remarks'] ?? 'N/A',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(widget.remark['dos']),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
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
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),

              // Expandable content
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: Colors.grey.shade300),
                      _buildDetailRow(
                        Icons.text_snippet_outlined,
                        'Full Remark',
                        widget.remark['remarks'] ?? 'N/A',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.category_outlined,
                        'Stage',
                        widget.remark['stage'] ?? 'N/A',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.person_outline,
                        'Added By',
                        widget.remark['added_by'] ?? 'N/A',
                      ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
