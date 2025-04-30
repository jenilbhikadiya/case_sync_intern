import 'package:flutter/material.dart';

import '../models/task_item_list.dart';
import '../utils/constants.dart';

class TaskCard extends StatefulWidget {
  final TaskItem taskItem;
  final VoidCallback onTap;
  final Function(BuildContext, TaskItem) onLongPress; // New callback

  final bool isHighlighted;
  final bool showNewTaskTag;

  const TaskCard({
    super.key,
    required this.taskItem,
    required this.onTap,
    required this.onLongPress, // Make this required

    this.isHighlighted = false,
    this.showNewTaskTag = false,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final Color labelColor =
        widget.isHighlighted ? Colors.white70 : Colors.grey.shade700;
    final Color iconColor =
        widget.isHighlighted ? Colors.white70 : Colors.grey.shade600;
    final Color valueColor = widget.isHighlighted ? Colors.white : Colors.black;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: getStatusColor(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildNewTaskTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: const Text(
        'NEW TASK',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 9,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TaskItem taskItem = widget.taskItem;

    // Get the status color for the top strip only
    Color statusColor = getStatusColor(taskItem.status);

    final Color cardColor = widget.isHighlighted
        ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
        : Colors.white;

    final Color textColor = widget.isHighlighted ? Colors.white : Colors.black;
    final Color subtitleColor =
        widget.isHighlighted ? Colors.white70 : Colors.grey.shade700;

    return GestureDetector(
      onTap: () {
        _animateTap();
        widget.onTap();
      },
      onLongPress: () {
        widget.onLongPress(
            context, widget.taskItem); // Call the long press callback
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isHighlighted
                  ? Colors.white.withOpacity(0.8)
                  : Colors.black, // Changed to black border
              width: 1.0, // Reduced width from 2.0 to 1.0 for a cleaner look
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.08), // Consistent shadow color
                spreadRadius: widget.isHighlighted ? 1 : 0,
                blurRadius: widget.isHighlighted ? 10 : 8,
                offset: Offset(0, widget.isHighlighted ? 4 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with always visible information
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instruction with icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(
                            Icons.notes_rounded,
                            size: 20,
                            color: widget.isHighlighted
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            taskItem.instruction.isEmpty
                                ? 'No Instruction Provided'
                                : taskItem.instruction,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (widget.showNewTaskTag) ...[
                          const SizedBox(width: 8),
                          _buildNewTaskTag(),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Case number and alloted info
                    Row(
                      children: [
                        // Case number
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_copy_outlined,
                                size: 16,
                                color: subtitleColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  taskItem.caseNo.isNotEmpty
                                      ? taskItem.caseNo
                                      : 'N/A',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Container(
                          height: 16,
                          width: 1,
                          color: widget.isHighlighted
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                        ),

                        // Alloted by
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: subtitleColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  taskItem.allotedBy.isNotEmpty
                                      ? taskItem.allotedBy
                                      : 'N/A',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expand/collapse icon
                        const SizedBox(width: 8),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: widget.isHighlighted
                              ? Colors.white
                              : Colors
                                  .black, // Changed from statusColor to black
                        ),
                      ],
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
                      Divider(
                          color: widget.isHighlighted
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.withOpacity(
                                  0.3), // Changed from statusColor to grey
                          height: 24,
                          thickness: 0.5),

                      _buildDetailRow(
                        Icons.assignment_ind_outlined,
                        'Alloted To',
                        taskItem.allotedTo.isNotEmpty
                            ? taskItem.allotedTo
                            : 'N/A',
                      ),

                      const SizedBox(height: 12),

                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Alloted Date',
                        taskItem.formattedAllotedDate ?? 'N/A',
                      ),

                      const SizedBox(height: 12),

                      _buildDetailRow(
                        Icons.event_busy_outlined,
                        'End Date',
                        taskItem.formattedExpectedEndDate ?? 'N/A',
                      ),

                      const SizedBox(height: 12),

                      _buildDetailRow(
                        Icons.flag_circle_outlined,
                        'Stage',
                        taskItem.stage.isNotEmpty ? taskItem.stage : 'N/A',
                      ),

                      const SizedBox(height: 16),

                      // Status chip
                      Row(
                        children: [
                          Icon(
                            Icons.playlist_add_check_circle_outlined,
                            size: 18,
                            color: widget.isHighlighted
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status:',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isHighlighted
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(taskItem.status),
                        ],
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
}
