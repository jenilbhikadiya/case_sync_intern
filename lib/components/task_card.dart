import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Not strictly needed if formatted dates are in TaskItem

import '../models/task_item_list.dart';
import '../utils/constants.dart'; // Assuming getStatusColor is here or defined below

// Define or import getStatusColor if it's not in constants.dart

class TaskCard extends StatefulWidget {
  final TaskItem taskItem;
  final VoidCallback onTap;
  final bool isHighlighted;
  final bool showNewTaskTag; // Control for the "NEW" tag

  const TaskCard({
    super.key,
    required this.taskItem,
    required this.onTap,
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
  }

  // Helper for building rows with Label (left) and Value (right)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
    BuildContext? context, // Context isn't really used here anymore
  }) {
    final Color labelColor =
        widget.isHighlighted ? Colors.white70 : Colors.grey.shade700;
    final Color iconColor =
        widget.isHighlighted ? Colors.white70 : Colors.grey.shade600;
    final Color valueColor = widget.isHighlighted ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed width label section
          SizedBox(
            width: 110, // Adjust as needed
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Value section takes remaining space
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
                child: valueWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET FOR THE "NEW TASK" TAG (Unchanged) ---
  Widget _buildNewTaskTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2), // Slightly smaller padding
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(4.0), // Simple rounded corners
      ),
      child: const Text(
        'NEW TASK', // Simpler text might fit better inline
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 9, // Smaller font size for inline tag
          letterSpacing: 0.4,
        ),
      ),
    );
  }
  // -----------------------------------

  @override
  Widget build(BuildContext context) {
    final TaskItem taskItem = widget.taskItem;

    // Status Chip definition
    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: getStatusColor(taskItem.status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        taskItem.status.toUpperCase().replaceAll('_', ' '),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Define colors based on highlight state
    final Color cardColor = widget.isHighlighted
        ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
        : Colors.white;
    final Color borderColor = widget.isHighlighted
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade300;
    final Color instructionColor =
        widget.isHighlighted ? Colors.white : Colors.black;
    final Color leadingIconColor = // Renamed for clarity
        widget.isHighlighted ? Colors.white : Colors.black54;

    return GestureDetector(
      onTap: () {
        _animateTap();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          // Removed clipBehavior as it's not needed without absolute positioning
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.isHighlighted ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(widget.isHighlighted ? 0.12 : 0.08),
                spreadRadius: widget.isHighlighted ? 1 : 0,
                blurRadius: widget.isHighlighted ? 10 : 8,
                offset: Offset(0, widget.isHighlighted ? 4 : 3),
              ),
            ],
          ),
          // --- NO STACK NEEDED HERE ANYMORE ---
          child: Padding(
            // Direct Padding for content
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- MODIFIED INSTRUCTION ROW ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading Icon
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 2.0), // Align icon better with text
                      child: Icon(
                        Icons.notes_rounded,
                        size: 20,
                        color: leadingIconColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Instruction Text (takes available space)
                    Expanded(
                      child: Text(
                        taskItem.instruction.isEmpty
                            ? 'No Instruction Provided'
                            : taskItem.instruction,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: instructionColor,
                          height: 1.3, // Adjust line height for readability
                        ),
                      ),
                    ),
                    // Conditionally add the "NEW" tag *after* the text
                    if (widget.showNewTaskTag) ...[
                      const SizedBox(width: 8), // Space between text and tag
                      _buildNewTaskTag(), // The green tag widget
                    ],
                  ],
                ),
                // --------------------------------

                // Divider
                const Divider(height: 24, thickness: 0.5), // Standard height

                // Info Rows (Unchanged)
                _buildInfoRow(
                  icon: Icons.folder_copy_outlined,
                  label: 'Case No',
                  valueWidget: Text(
                      taskItem.caseNo.isNotEmpty ? taskItem.caseNo : 'N/A'),
                ),
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Alloted By',
                  valueWidget: Text(taskItem.allotedBy.isNotEmpty
                      ? taskItem.allotedBy
                      : 'N/A'),
                ),
                _buildInfoRow(
                  icon: Icons.assignment_ind_outlined,
                  label: 'Alloted To',
                  valueWidget: Text(taskItem.allotedTo.isNotEmpty
                      ? taskItem.allotedTo
                      : 'N/A'),
                ),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Alloted Date',
                  // Ensure TaskItem has these formatted strings or format here
                  valueWidget: Text(taskItem.formattedAllotedDate ?? 'N/A'),
                ),
                _buildInfoRow(
                  icon: Icons.event_busy_outlined,
                  label: 'End Date',
                  valueWidget: Text(taskItem.formattedExpectedEndDate ?? 'N/A'),
                ),
                _buildInfoRow(
                  icon: Icons.flag_circle_outlined,
                  label: 'Stage',
                  valueWidget:
                      Text(taskItem.stage.isNotEmpty ? taskItem.stage : 'N/A'),
                ),
                _buildInfoRow(
                  icon: Icons.playlist_add_check_circle_outlined,
                  label: 'Status',
                  valueWidget: statusChip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
