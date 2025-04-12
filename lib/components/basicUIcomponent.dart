import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(40.0),
    ),
    padding: const EdgeInsets.all(15),
  );

  static ButtonStyle getElevatedButtonStyle({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40.0),
      ),
      padding: const EdgeInsets.all(15),
    );
  }

  // Text Field Theme
  static InputDecoration textFieldDecoration({
    required String labelText,
    required String hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }

  static TextStyle titleStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle buttonTextStyle = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  // Custom Colors
  static const Color primaryColor = Colors.black;
  static const Color secondaryColor = Colors.white;
  static const Color errorColor = Colors.red;

  // Refresh Indicator Theme
  static Color getRefreshIndicatorColor(Brightness brightness) {
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  static Color getRefreshIndicatorBackgroundColor() {
    return Colors.white; // Always white background
  }

  // Calendar Theme
  static ThemeData calendarTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Colors.black, // Selected date color
      onPrimary: Colors.white, // Text on selected date
      surface: Colors.white, // Background color
      onSurface: Colors.black, // Default text color
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
    ),
    dialogBackgroundColor: Colors.white,
    buttonTheme: const ButtonThemeData(
      textTheme: ButtonTextTheme.primary,
    ),
  );
}

class AnimatedListTile extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final bool enabled;
  final VoidCallback? onTap;

  const AnimatedListTile({
    super.key,
    this.leading,
    this.title,
    this.enabled = true,
    this.onTap,
  });

  @override
  State<AnimatedListTile> createState() => _AnimatedListTileState();
}

class _AnimatedListTileState extends State<AnimatedListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled
          ? () {
              HapticFeedback.mediumImpact(); // Add haptic feedback
              _animateTap();
              if (widget.onTap != null) {
                widget.onTap!();
              }
            }
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ListTile(
          leading: widget.leading,
          title: widget.title,
          enabled: widget.enabled,
        ),
      ),
    );
  }
}

// Assuming TaskItem, AddRemarkPage, ShowRemarkPage, and _navigateToReAssignTask are defined elsewhere in your code.
// Also assuming fetchTasks is a function in your TaskPageState to refresh the list.

// For the TaskPage widget, you would use _showDropdownMenu like this:
// ...
// onTap: () {
//   _showDropdownMenu(context, taskItem, fetchTasks, _navigateToReAssignTask);
// },
// ...
