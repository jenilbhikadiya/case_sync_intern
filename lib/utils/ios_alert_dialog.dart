import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class IOSAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelButtonText;
  final String confirmButtonText;
  final VoidCallback onConfirm;

  const IOSAlertDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelButtonText,
    required this.confirmButtonText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      insetAnimationDuration: const Duration(milliseconds: 150),
      insetAnimationCurve: Curves.easeInOut,
      title: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            color: CupertinoColors.secondaryLabel,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(false);
          },
          child: Text(
            cancelButtonText,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true, // Marks the confirm button visually
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(true);
            onConfirm();
          },
          child: Text(
            confirmButtonText,
            style: const TextStyle(
              color: CupertinoColors.destructiveRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
