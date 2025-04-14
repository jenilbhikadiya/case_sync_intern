import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_item_list.dart';
import '../utils/constants.dart';

class TaskCard extends StatefulWidget {
  final TaskItem taskItem;
  final VoidCallback onTap;
  final bool isHighlighted;

  const TaskCard({
    super.key,
    required this.taskItem,
    required this.onTap,
    this.isHighlighted = false,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
    BuildContext? context,
  }) {
    final Color labelColor =
        widget.isHighlighted ? Colors.white70 : Colors.grey.shade600;
    final Color iconColor =
        widget.isHighlighted ? Colors.white70 : Colors.grey.shade500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black87,
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

  @override
  Widget build(BuildContext context) {
    final TaskItem taskItem = widget.taskItem;

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

    return GestureDetector(
      onTap: () {
        _animateTap();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.isHighlighted
                ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          color: widget.isHighlighted
                              ? Colors.white
                              : Colors.black,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.5),
                _buildInfoRow(
                  icon: Icons.folder_copy_outlined,
                  label: 'Case No',
                  valueWidget: Text(taskItem.caseNo),
                ),
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Alloted By',
                  valueWidget: Text(taskItem.allotedBy),
                ),
                _buildInfoRow(
                  icon: Icons.assignment_ind_outlined,
                  label: 'Alloted To',
                  valueWidget: Text(taskItem.allotedTo),
                ),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
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
