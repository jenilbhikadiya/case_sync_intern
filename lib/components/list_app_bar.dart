import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchPressed;
  final VoidCallback? onFilterPressed; // Optional filter button
  final bool isSearching;
  final bool showSearch; // New parameter to show/hide search
  final String title;

  const ListAppBar({
    super.key,
    this.onSearchPressed,
    this.onFilterPressed, // Optional
    this.isSearching = false,
    this.showSearch = true, // Default to true
    required this.title,
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
          width: 32,
          height: 32,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      leadingWidth: 66,
      titleSpacing: -10,
      toolbarHeight: 70,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (onFilterPressed != null)
          IconButton(
            icon: const Icon(Icons.filter_list_alt,
                size: 32, color: Colors.black),
            onPressed: onFilterPressed,
          ),
        if (showSearch &&
            onSearchPressed != null) // Show search only if enabled
          IconButton(
            padding: const EdgeInsets.only(left: 10.0, right: 20.0),
            icon: Icon(
              isSearching ? Icons.close : Icons.search_rounded,
              size: 32,
              color: Colors.black,
            ),
            onPressed: onSearchPressed,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
