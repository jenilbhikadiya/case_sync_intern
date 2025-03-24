import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class FileAlreadyExistsDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelButtonText;
  final String confirmButtonText;
  final VoidCallback onConfirm;

  const FileAlreadyExistsDialog({
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
      insetAnimationDuration: const Duration(milliseconds: 100),
      insetAnimationCurve: Curves.easeInOut,
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(false);
          },
          child: Text(
            cancelButtonText,
            style: const TextStyle(color: CupertinoColors.black),
          ),
        ),
        CupertinoDialogAction(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onConfirm();
          },
          child: Text(
            confirmButtonText,
            style: const TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      ],
    );
  }
}
