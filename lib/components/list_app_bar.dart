import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ListAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Existing Parameters
  final VoidCallback? onSearchPressed; // Callback to toggle search state
  final VoidCallback? onFilterPressed; // Optional filter button callback
  final bool isSearching; // Flag indicating if search mode is active
  final bool showSearch; // Flag to allow showing the search icon
  final String title;
  final double? titleSize;

  // --- NEW PARAMETERS FOR SEARCH FUNCTIONALITY ---
  final TextEditingController?
      searchController; // Controller for the search field
  final FocusNode? searchFocusNode; // Focus node for the search field
  final ValueChanged<String>?
      onSearchChanged; // Callback when search text changes
  final int resultCount; // Total number of search results found
  final int
      currentResultIndex; // 0-based index of the currently highlighted result
  final VoidCallback? onNavigatePrevious; // Callback for previous result button
  final VoidCallback? onNavigateNext; // Callback for next result button
  // ---------------------------------------------

  const ListAppBar({
    super.key,
    this.onSearchPressed,
    this.onFilterPressed,
    this.isSearching = false,
    this.showSearch = true,
    required this.title,
    this.titleSize = 30, // Default title size kept

    // --- ADD NEW PARAMETERS TO CONSTRUCTOR ---
    this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    this.resultCount = 0, // Default count
    this.currentResultIndex = -1, // Default index (no selection)
    this.onNavigatePrevious,
    this.onNavigateNext,
    // ---------------------------------------
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      elevation: 0,
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/back_arrow.svg',
          width: 28, // Slightly smaller consistent size?
          height: 28,
          colorFilter: const ColorFilter.mode(
              Colors.black, BlendMode.srcIn), // Added color filter
        ),
        tooltip: 'Back', // Added tooltip
        onPressed: () {
          // If searching, maybe just close search? Or always pop?
          if (isSearching && onSearchPressed != null) {
            onSearchPressed!(); // Call the toggle callback to close search
          } else {
            Navigator.maybePop(context); // Default back action
          }
        },
      ),
      leadingWidth: 56, // Adjusted width if needed
      // --- Conditional Title/Search Field ---
      title: isSearching
          ? TextField(
              // Show TextField when searching is active
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: onSearchChanged,
              autofocus: true, // Focus when it appears
              style: const TextStyle(
                  color: Colors.black87, fontSize: 17), // Search text style
              decoration: InputDecoration(
                hintText: 'Search $title...', // Dynamic hint text
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: InputBorder.none, // Clean look
                isDense: true, // Reduce vertical padding
              ),
            )
          : Text(
              // Show Title Text when not searching
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: titleSize, // Use the provided title size
                fontWeight: FontWeight.bold,
              ),
            ),
      titleSpacing: 0, // Adjust if needed with leading width change
      toolbarHeight: 70, // Keep existing height
      actions: [
        // --- Filter Button (Show only if provided AND not searching) ---
        if (onFilterPressed != null && !isSearching)
          IconButton(
            tooltip: 'Filter', // Added tooltip
            icon: const Icon(Icons.filter_list_alt,
                size: 28, color: Colors.black), // Adjusted size
            onPressed: onFilterPressed,
          ),

        // --- Search Result Navigation (Show only if searching AND results exist) ---
        if (isSearching && resultCount > 0) ...[
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.black54),
            tooltip: 'Previous Result',
            // Disable if it's the first result or no results
            onPressed:
                onNavigatePrevious, // Directly use the callback (null disables)
          ),
          Padding(
            // Display index + 1 because index is 0-based
            padding:
                const EdgeInsets.symmetric(horizontal: 2.0), // Minimal padding
            child: Text(
              // Handle case where currentResultIndex might still be -1 initially
              '${currentResultIndex >= 0 ? currentResultIndex + 1 : '-'}/$resultCount',
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.arrow_downward_rounded, color: Colors.black54),
            tooltip: 'Next Result',
            // Disable if it's the last result or no results
            onPressed:
                onNavigateNext, // Directly use the callback (null disables)
          ),
          const SizedBox(width: 4), // Small spacer before search/close icon
        ],

        // --- Search Toggle / Close Button ---
        if (showSearch && onSearchPressed != null) // Show only if enabled
          IconButton(
            tooltip: isSearching ? 'Close Search' : 'Search', // Dynamic tooltip
            padding: const EdgeInsets.only(right: 16.0), // Adjusted padding
            icon: Icon(
              isSearching
                  ? Icons.close_rounded
                  : Icons.search_rounded, // Change icon based on state
              size: 28, // Adjusted size
              color: Colors.black,
            ),
            onPressed:
                onSearchPressed, // Use the provided callback to toggle state
          ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(70); // Keep existing preferred size
}
