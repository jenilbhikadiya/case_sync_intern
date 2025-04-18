import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchPressed;
  final VoidCallback? onFilterPressed;
  final bool isSearching;
  final bool showSearch;
  final bool showSearchField;
  final String title;
  final double? titleSize;

  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final int resultCount;
  final int currentResultIndex;
  final VoidCallback? onNavigatePrevious;
  final VoidCallback? onNavigateNext;

  const ListAppBar({
    super.key,
    this.onSearchPressed,
    this.onFilterPressed,
    this.isSearching = false,
    this.showSearch = true,
    this.showSearchField = true,
    required this.title,
    this.titleSize = 30,
    this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    this.resultCount = 0,
    this.currentResultIndex = -1,
    this.onNavigatePrevious,
    this.onNavigateNext,
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
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        ),
        tooltip: 'Back',
        onPressed: () {
          if (isSearching && onSearchPressed != null) {
            onSearchPressed!();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
      leadingWidth: 56,
      title: (isSearching && showSearchField)
          ? TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: onSearchChanged,
              autofocus: true,
              style: const TextStyle(color: Colors.black87, fontSize: 17),
              decoration: InputDecoration(
                hintText: 'Search $title...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: InputBorder.none,
                isDense: true,
              ),
            )
          : Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
      titleSpacing: 0,
      toolbarHeight: 70,
      actions: [
        if (onFilterPressed != null)
          IconButton(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list_alt,
                size: 28, color: Colors.black),
            onPressed: onFilterPressed,
          ),
        if (isSearching && resultCount > 0) ...[
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.black54),
            tooltip: 'Previous Result',
            onPressed: onNavigatePrevious,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(
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
            onPressed: onNavigateNext,
          ),
        ],
        if (isSearching)
          IconButton(
            tooltip: 'Close Search',
            padding: const EdgeInsets.only(right: 16.0),
            icon: const Icon(
              Icons.close_rounded,
              size: 28,
              color: Colors.black,
            ),
            onPressed: onSearchPressed,
          )
        else if (showSearch && onSearchPressed != null)
          IconButton(
            tooltip: 'Search',
            padding: const EdgeInsets.only(right: 16.0),
            icon: const Icon(
              Icons.search_rounded,
              size: 28,
              color: Colors.black,
            ),
            onPressed: onSearchPressed,
          ),
        if (!isSearching &&
            onFilterPressed == null &&
            !(showSearch && onSearchPressed != null))
          const SizedBox(width: 16.0),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
