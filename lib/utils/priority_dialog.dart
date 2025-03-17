import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class PriorityDialog extends StatelessWidget {
  final Function(int?) onPrioritySelected;

  const PriorityDialog({super.key, required this.onPrioritySelected});

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.light),
      // Ensures white background
      child: CupertinoAlertDialog(
        insetAnimationDuration: const Duration(milliseconds: 100),
        insetAnimationCurve: Curves.easeInOut,
        title: const Text(
          "Set Priority",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            placeholder: "Enter priority number",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CupertinoColors.black),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
            child: const Text(
              "Cancel",
              style: TextStyle(color: CupertinoColors.black),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              HapticFeedback.mediumImpact();
              int? priority = int.tryParse(controller.text);
              onPrioritySelected(priority);
              Navigator.pop(context);
            },
            child: const Text(
              "Save",
              style: TextStyle(
                  color: CupertinoColors.destructiveRed,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
