import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Make sure intl is imported if using formatted dates directly here

// Assuming TaskItem model and getStatusColor are accessible
// If getStatusColor is not accessible globally, define it here or import it
import '../models/task_item_list.dart';
import '../utils/constants.dart';
// import '../utils/constants.dart'; // Keep if needed for other constants

class TaskCard extends StatefulWidget {
  final TaskItem taskItem;
  final VoidCallback onTap;
  final bool
      isHighlighted; // You might not need highlighting with a strong border

  const TaskCard({
    super.key,
    required this.taskItem,
    required this.onTap,
    this.isHighlighted = false, // Default to false, maybe remove if unused
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
      // Slightly more pronounced pop
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeOut), // Use easeOut
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

  // Helper widget for building info rows consistently
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Widget
        valueWidget, // Allow passing custom widgets like the status chip
    BuildContext? context, // Pass context if needed for theme access
  }) {
    final Color labelColor = widget.isHighlighted
        ? Colors.white70
        : Colors.grey.shade600; // Softer label color
    final Color iconColor =
        widget.isHighlighted ? Colors.white70 : Colors.grey.shade500;

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 5.0), // Vertical spacing between rows
      child: Row(
        crossAxisAlignment: CrossAxisAlignment
            .start, // Align icon/label with top of value if value wraps
        children: [
          // Left side: Icon and Label
          Row(
            mainAxisSize: MainAxisSize.min, // Prevent taking too much space
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
          const SizedBox(width: 10), // Space between label and value
          // Right side: Value (takes remaining space)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black87,
                  fontWeight:
                      FontWeight.w500, // Values slightly bolder than labels
                ),
                textAlign: TextAlign.right, // Align text value to the right
                child: valueWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TaskItem taskItem = widget.taskItem;

    // Prepare the Status Chip Widget beforehand
    final statusChip = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 9, vertical: 3.5), // Adjusted padding
      decoration: BoxDecoration(
        color: getStatusColor(taskItem.status), // Solid status color background
        // Optionally add a subtle border if needed, e.g., for light status colors on white background
        // border: Border.all(color: Colors.black.withOpacity(0.1), width: 0.5),
        borderRadius: BorderRadius.circular(6), // Less rounded, more badge-like
      ),
      child: Text(
        taskItem.status
            .toUpperCase()
            .replaceAll('_', ' '), // Replace underscore with space
        style: const TextStyle(
          color: Colors.white, // White text for contrast
          fontWeight:
              FontWeight.w600, // Slightly less bold than FontWeight.bold
          fontSize: 11, // Slightly smaller font
          letterSpacing: 0.3, // Add slight letter spacing
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis, // Handle long status names
      ),
    );
    // --
    return GestureDetector(
      onTap: () {
        _animateTap();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(
              vertical: 8.0), // Increased vertical margin
          decoration: BoxDecoration(
            color: widget.isHighlighted
                ? Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.9) // Slightly transparent highlight
                : Colors.white,
            borderRadius: BorderRadius.circular(12), // Slightly larger radius
            // --- The Black Border ---
            border: Border.all(
              color: Colors.black,
              width: 1.0, // Adjust width as needed (1.0 is usually good)
            ),
            // --- Subtle Shadow (Optional - can remove if border is enough) ---
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08), // Softer shadow
                spreadRadius: 0,
                blurRadius: 8, // Slightly more blur
                offset: const Offset(0, 3), // Slightly more offset
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 14.0), // Adjusted padding
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align content left
              children: [
                // --- Instruction (More Prominent) ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 2.0), // Align icon better with text
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
                          fontWeight: FontWeight.bold, // Bold instruction
                          fontSize: 16, // Larger font size
                          color: widget.isHighlighted
                              ? Colors.white
                              : Colors.black,
                          height:
                              1.3, // Line height for readability if it wraps
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24, thickness: 0.5), // Visual separator

                // --- Detail Rows using the helper ---
                _buildInfoRow(
                  icon: Icons.folder_copy_outlined,
                  label: 'Case No',
                  valueWidget: Text(taskItem.caseNo),
                ),
                _buildInfoRow(
                  icon: Icons.person_outline, // Simpler icon
                  label: 'Alloted By',
                  valueWidget: Text(taskItem.allotedBy),
                ),
                _buildInfoRow(
                  icon:
                      Icons.assignment_ind_outlined, // Different icon for 'To'
                  label: 'Alloted To',
                  valueWidget: Text(taskItem
                      .allotedTo), // Displaying the name/id from the model
                ),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined, // Simpler icon
                  label: 'Alloted Date',
                  valueWidget: Text(taskItem.formattedAllotedDate),
                ),
                _buildInfoRow(
                  icon: Icons.event_busy_outlined,
                  label: 'End Date',
                  valueWidget: Text(taskItem.formattedExpectedEndDate),
                ),
                _buildInfoRow(
                  icon: Icons.flag_circle_outlined,
                  label: 'Stage',
                  valueWidget: Text(taskItem.stage),
                ),
                _buildInfoRow(
                  icon: Icons.playlist_add_check_circle_outlined,
                  label: 'Status',
                  valueWidget: statusChip, // Pass the pre-built chip
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
